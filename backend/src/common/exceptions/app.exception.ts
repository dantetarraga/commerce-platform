import { HttpException, HttpStatus } from '@nestjs/common';

/**
 * Catálogo de códigos de error. La app decide qué hacer según `code`; el
 * `message` va en español porque se muestra tal cual al usuario.
 */
export const ErrorCode = {
  // Generales
  VALIDATION_ERROR: 'VALIDATION_ERROR',
  BAD_REQUEST: 'BAD_REQUEST',
  UNAUTHORIZED: 'UNAUTHORIZED',
  FORBIDDEN: 'FORBIDDEN',
  NOT_FOUND: 'NOT_FOUND',
  CONFLICT: 'CONFLICT',
  RATE_LIMITED: 'RATE_LIMITED',
  SERVICE_UNAVAILABLE: 'SERVICE_UNAVAILABLE',
  INTERNAL_ERROR: 'INTERNAL_ERROR',
  // Auth
  TOKEN_EXPIRED: 'TOKEN_EXPIRED',
  INVALID_REFRESH_TOKEN: 'INVALID_REFRESH_TOKEN',
  OTP_NOT_REQUESTED: 'OTP_NOT_REQUESTED',
  OTP_EXPIRED: 'OTP_EXPIRED',
  OTP_INVALID: 'OTP_INVALID',
  OTP_TOO_MANY_ATTEMPTS: 'OTP_TOO_MANY_ATTEMPTS',
  OTP_RESEND_TOO_SOON: 'OTP_RESEND_TOO_SOON',
  OTP_TOO_MANY_REQUESTS: 'OTP_TOO_MANY_REQUESTS',
  REGISTRATION_EXPIRED: 'REGISTRATION_EXPIRED',
  USER_DISABLED: 'USER_DISABLED',
  EMAIL_ALREADY_EXISTS: 'EMAIL_ALREADY_EXISTS',
} as const;

export type ErrorCode = (typeof ErrorCode)[keyof typeof ErrorCode];

export class AppException extends HttpException {
  constructor(
    readonly code: ErrorCode,
    status: HttpStatus,
    message: string,
    readonly details?: Record<string, unknown>,
  ) {
    super({ code, message, details }, status);
  }

  static notFound(message: string) {
    return new AppException(ErrorCode.NOT_FOUND, HttpStatus.NOT_FOUND, message);
  }
}
