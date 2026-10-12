import type { CookieOptions, Request, Response } from 'express';
import { API_PREFIX } from '../../app.setup';

/**
 * El panel web guarda el refresh token en una cookie httpOnly (JavaScript no
 * la puede leer). Las apps lo siguen recibiendo en el cuerpo. El panel se
 * identifica con [WEB_CLIENT_HEADER]: al ser una cabecera propia, el navegador
 * hace preflight de CORS y un sitio ajeno no puede usar la cookie.
 */
export const REFRESH_COOKIE = 'apamuy_rt';
export const WEB_CLIENT_HEADER = 'x-apamuy-client';

export type CookieSameSite = 'strict' | 'lax' | 'none';

export const isWebClient = (req: Request) => req.headers[WEB_CLIENT_HEADER] === 'web';

/** Lee la cookie sin `cookie-parser`: es la única que usa la API. */
export function readRefreshCookie(req: Request): string | undefined {
  for (const part of (req.headers.cookie ?? '').split(';')) {
    const [name, ...value] = part.trim().split('=');
    if (name === REFRESH_COOKIE) return decodeURIComponent(value.join('='));
  }
  return undefined;
}

export interface SessionCookieConfig {
  secure: boolean;
  sameSite: CookieSameSite;
  maxAgeMs: number;
}

// Solo viaja a /auth: el resto de la API usa el access token.
const options = ({ secure, sameSite }: SessionCookieConfig): CookieOptions => ({
  httpOnly: true,
  secure: secure || sameSite === 'none',
  sameSite,
  path: `/${API_PREFIX}/auth`,
});

export function setRefreshCookie(res: Response, token: string, config: SessionCookieConfig) {
  res.cookie(REFRESH_COOKIE, token, { ...options(config), maxAge: config.maxAgeMs });
}

export function clearRefreshCookie(res: Response, config: SessionCookieConfig) {
  res.clearCookie(REFRESH_COOKIE, options(config));
}
