import { Logger } from '@nestjs/common';

/** Envío de SMS detrás de una abstracción: el proveedor se elige con `SMS_PROVIDER`. */
export abstract class SmsSender {
  /** `phone` = celular local (9 dígitos); cada proveedor le agrega el prefijo del país. */
  abstract send(phone: string, message: string): Promise<void>;
}

/** El proveedor rechazó el número (no existe o no es celular): el usuario debe corregirlo. */
export class SmsInvalidNumberError extends Error {}

/** El proveedor no respondió o falló: se puede reintentar. */
export class SmsDeliveryError extends Error {}

/**
 * Desarrollo y test: escribe el mensaje en el log. Con `logContent` en false
 * no se loguea el contenido, para no filtrar códigos.
 */
export class LogSmsSender extends SmsSender {
  private readonly logger = new Logger('SMS');

  constructor(private readonly logContent: boolean) {
    super();
  }

  send(phone: string, message: string): Promise<void> {
    this.logger.log(this.logContent ? `→ ${phone}: ${message}` : `→ ${phone} (contenido oculto)`);
    return Promise.resolve();
  }
}

export interface TwilioConfig {
  accountSid: string;
  authToken: string;
  countryCode: string;
  /** Uno de los dos: Messaging Service (recomendado) o número remitente. */
  messagingServiceSid?: string;
  from?: string;
}

// Errores de Twilio que significan "número inválido", no una falla del servicio.
// https://www.twilio.com/docs/api/errors
const INVALID_NUMBER_CODES = new Set([21211, 21214, 21217, 21614]);
const TIMEOUT_MS = 10_000;

/** API REST de Twilio (Messages). Una sola llamada: no hace falta el SDK. */
export class TwilioSmsSender extends SmsSender {
  private readonly logger = new Logger('SMS');

  constructor(
    private readonly config: TwilioConfig,
    private readonly fetchImpl: typeof fetch = fetch,
  ) {
    super();
  }

  async send(phone: string, message: string): Promise<void> {
    const { accountSid, authToken, countryCode, messagingServiceSid, from } = this.config;
    const body = new URLSearchParams({ To: `${countryCode}${phone}`, Body: message });
    if (messagingServiceSid) body.set('MessagingServiceSid', messagingServiceSid);
    else if (from) body.set('From', from);

    let response: Response;
    try {
      response = await this.fetchImpl(`https://api.twilio.com/2010-04-01/Accounts/${accountSid}/Messages.json`, {
        method: 'POST',
        headers: {
          Authorization: `Basic ${Buffer.from(`${accountSid}:${authToken}`).toString('base64')}`,
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body,
        signal: AbortSignal.timeout(TIMEOUT_MS),
      });
    } catch (error) {
      this.logger.error(`Twilio no respondió: ${error instanceof Error ? error.message : String(error)}`);
      throw new SmsDeliveryError('Twilio no respondió');
    }

    if (response.ok) return;
    const detail = (await response.json().catch(() => ({}))) as { code?: number; message?: string };
    // Nunca se loguea el mensaje: lleva el código.
    this.logger.warn(
      `Twilio rechazó el SMS (${response.status}, código ${detail.code ?? '?'}): ${detail.message ?? ''}`,
    );
    if (detail.code !== undefined && INVALID_NUMBER_CODES.has(detail.code)) {
      throw new SmsInvalidNumberError(detail.message);
    }
    throw new SmsDeliveryError(`Twilio respondió ${response.status}`);
  }
}
