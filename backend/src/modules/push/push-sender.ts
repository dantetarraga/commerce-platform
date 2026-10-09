import { Logger } from '@nestjs/common';
import { createSign } from 'node:crypto';

/** Canal de Android en el que se muestra el aviso; la app lo crea con ese id. */
export type PushChannel = 'orders' | 'order_alarm';

export interface PushMessage {
  /** Sin título ni texto es un mensaje de datos: la app decide cómo mostrarlo (la alarma). */
  title?: string;
  body?: string;
  data: Record<string, string>;
  channel: PushChannel;
  /** Segundos que FCM lo reintenta; pasado ese tiempo ya no sirve. */
  ttlSeconds?: number;
}

/** Envío de push detrás de una abstracción: el proveedor se elige con `PUSH_PROVIDER`. */
export abstract class PushSender {
  /** Devuelve los tokens que FCM ya no reconoce, para borrarlos. */
  abstract send(tokens: readonly string[], message: PushMessage): Promise<{ invalidTokens: string[] }>;
}

/** Desarrollo y test: escribe el aviso en el log. */
export class LogPushSender extends PushSender {
  private readonly logger = new Logger('Push');

  send(tokens: readonly string[], message: PushMessage) {
    if (tokens.length > 0) {
      this.logger.log(
        `→ ${tokens.length} dispositivo(s) [${message.channel}] ${message.title ?? message.data.type ?? ''}`,
      );
    }
    return Promise.resolve({ invalidTokens: [] });
  }
}

/** Lo necesario de la cuenta de servicio de Firebase (JSON descargado de la consola). */
export interface FcmServiceAccount {
  project_id: string;
  client_email: string;
  private_key: string;
  token_uri?: string;
}

const SCOPE = 'https://www.googleapis.com/auth/firebase.messaging';
const DEFAULT_TOKEN_URI = 'https://oauth2.googleapis.com/token';
const TIMEOUT_MS = 10_000;

const base64url = (value: string | Buffer) => Buffer.from(value).toString('base64url');

/**
 * FCM HTTP v1, sin el SDK: un token OAuth firmado con la cuenta de servicio (válido una
 * hora, se reusa) y una llamada por dispositivo.
 */
export class FcmPushSender extends PushSender {
  private readonly logger = new Logger('Push');
  private accessToken: { value: string; expiresAt: number } | null = null;

  constructor(
    private readonly account: FcmServiceAccount,
    private readonly fetchImpl: typeof fetch = fetch,
    private readonly now: () => number = Date.now,
  ) {
    super();
  }

  async send(tokens: readonly string[], message: PushMessage) {
    if (tokens.length === 0) return { invalidTokens: [] };
    const accessToken = await this.token();
    const results = await Promise.all(tokens.map((token) => this.sendOne(accessToken, token, message)));
    return { invalidTokens: tokens.filter((_, i) => results[i] === 'invalid') };
  }

  private async sendOne(
    accessToken: string,
    token: string,
    message: PushMessage,
  ): Promise<'ok' | 'invalid' | 'failed'> {
    const url = `https://fcm.googleapis.com/v1/projects/${this.account.project_id}/messages:send`;
    try {
      const res = await this.fetchImpl(url, {
        method: 'POST',
        headers: { Authorization: `Bearer ${accessToken}`, 'Content-Type': 'application/json' },
        body: JSON.stringify({ message: toFcmMessage(token, message) }),
        signal: AbortSignal.timeout(TIMEOUT_MS),
      });
      if (res.ok) return 'ok';
      const error = (await res.json().catch(() => null)) as FcmError | null;
      const codes = error?.error?.details?.map((detail) => detail.errorCode) ?? [];
      // El teléfono desinstaló la app o renovó el token.
      if (res.status === 404 || codes.includes('UNREGISTERED')) return 'invalid';
      this.logger.warn(`FCM respondió ${res.status}: ${error?.error?.message ?? 'sin detalle'}`);
      return 'failed';
    } catch (error) {
      this.logger.warn(`FCM no respondió: ${(error as Error).message}`);
      return 'failed';
    }
  }

  private async token(): Promise<string> {
    const now = this.now();
    if (this.accessToken && this.accessToken.expiresAt - 60_000 > now) return this.accessToken.value;
    const tokenUri = this.account.token_uri ?? DEFAULT_TOKEN_URI;
    const iat = Math.floor(now / 1000);
    const header = base64url(JSON.stringify({ alg: 'RS256', typ: 'JWT' }));
    const claims = base64url(
      JSON.stringify({ iss: this.account.client_email, scope: SCOPE, aud: tokenUri, iat, exp: iat + 3600 }),
    );
    const signature = createSign('RSA-SHA256').update(`${header}.${claims}`).sign(this.account.private_key);
    const res = await this.fetchImpl(tokenUri, {
      method: 'POST',
      headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
      body: new URLSearchParams({
        grant_type: 'urn:ietf:params:oauth:grant-type:jwt-bearer',
        assertion: `${header}.${claims}.${base64url(signature)}`,
      }),
      signal: AbortSignal.timeout(TIMEOUT_MS),
    });
    if (!res.ok) throw new Error(`Google OAuth respondió ${res.status}`);
    const body = (await res.json()) as { access_token: string; expires_in: number };
    this.accessToken = { value: body.access_token, expiresAt: now + body.expires_in * 1000 };
    return body.access_token;
  }
}

interface FcmError {
  error?: { message?: string; details?: { errorCode?: string }[] };
}

/** Mensaje de FCM v1. Con título va como notificación; sin él, solo datos (alta prioridad). */
export function toFcmMessage(token: string, message: PushMessage) {
  const notification = message.title ? { title: message.title, body: message.body ?? '' } : undefined;
  return {
    token,
    ...(notification && { notification }),
    data: message.data,
    android: {
      priority: 'HIGH',
      ...(message.ttlSeconds !== undefined && { ttl: `${message.ttlSeconds}s` }),
      ...(notification && { notification: { channel_id: message.channel } }),
    },
    apns: { payload: { aps: notification ? { sound: 'default' } : { 'content-available': 1 } } },
  };
}
