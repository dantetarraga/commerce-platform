import { createHmac, randomInt, timingSafeEqual } from 'node:crypto';
import { HttpStatus, Injectable } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { AppException, ErrorCode } from '../../../common/exceptions/app.exception';
import type { Env } from '../../../config/env';
import { PrismaService } from '../../../database/prisma.service';
import { SmsSender } from '../sms/sms-sender';

export const OTP_LENGTH = 6;
const MAX_REQUESTS_PER_HOUR = 5;
const HOUR_MS = 60 * 60 * 1000;

export interface OtpChallengeResponse {
  phone: string;
  resendAfterSeconds: number;
  codeLength: number;
}

/**
 * Códigos de un solo uso por SMS. Solo se guarda un HMAC del código; cada
 * código tiene vencimiento, intentos máximos y se consume al verificarse.
 */
@Injectable()
export class OtpService {
  private readonly secret: string;
  private readonly ttlMs: number;
  private readonly resendSeconds: number;
  private readonly maxAttempts: number;
  private readonly devCode?: string;

  constructor(
    private readonly prisma: PrismaService,
    private readonly sms: SmsSender,
    config: ConfigService<Env, true>,
  ) {
    this.secret = config.get('JWT_ACCESS_SECRET', { infer: true });
    this.ttlMs = config.get('OTP_TTL_SECONDS', { infer: true }) * 1000;
    this.resendSeconds = config.get('OTP_RESEND_SECONDS', { infer: true });
    this.maxAttempts = config.get('OTP_MAX_ATTEMPTS', { infer: true });
    this.devCode = config.get('OTP_DEV_CODE', { infer: true });
  }

  async request(phone: string, now = new Date()): Promise<OtpChallengeResponse> {
    const recent = await this.prisma.otpChallenge.findMany({
      where: { phone, createdAt: { gt: new Date(now.getTime() - HOUR_MS) } },
      orderBy: { createdAt: 'desc' },
      select: { createdAt: true },
    });

    const last = recent[0];
    if (last) {
      const waitSeconds = Math.ceil(this.resendSeconds - (now.getTime() - last.createdAt.getTime()) / 1000);
      if (waitSeconds > 0) {
        throw new AppException(
          ErrorCode.OTP_RESEND_TOO_SOON,
          HttpStatus.TOO_MANY_REQUESTS,
          `Espera ${waitSeconds} s para pedir otro código.`,
          { retryAfterSeconds: waitSeconds },
        );
      }
    }
    if (recent.length >= MAX_REQUESTS_PER_HOUR) {
      throw new AppException(
        ErrorCode.OTP_TOO_MANY_REQUESTS,
        HttpStatus.TOO_MANY_REQUESTS,
        'Pediste muchos códigos. Inténtalo de nuevo en una hora.',
      );
    }

    const code =
      this.devCode ??
      randomInt(0, 10 ** OTP_LENGTH)
        .toString()
        .padStart(OTP_LENGTH, '0');
    await this.prisma.otpChallenge.create({
      data: { phone, codeHash: this.hash(phone, code), expiresAt: new Date(now.getTime() + this.ttlMs) },
    });
    await this.sms.send(phone, `Tu código de Chaski es ${code}. No lo compartas con nadie.`);

    return { phone, resendAfterSeconds: this.resendSeconds, codeLength: OTP_LENGTH };
  }

  /** Lanza si el código no es válido; si lo es, lo consume. */
  async verify(phone: string, code: string, now = new Date()): Promise<void> {
    const challenge = await this.prisma.otpChallenge.findFirst({
      where: { phone },
      orderBy: { createdAt: 'desc' },
    });
    if (!challenge || challenge.consumedAt) {
      throw new AppException(ErrorCode.OTP_NOT_REQUESTED, HttpStatus.CONFLICT, 'Pide un código primero.');
    }
    if (challenge.expiresAt <= now) {
      throw new AppException(ErrorCode.OTP_EXPIRED, HttpStatus.CONFLICT, 'El código venció. Pide uno nuevo.');
    }
    if (challenge.attempts >= this.maxAttempts) {
      throw tooManyAttempts();
    }

    if (!this.matches(challenge.codeHash, this.hash(phone, code))) {
      // Incremento condicional: dos intentos simultáneos no pasan el límite.
      const { count } = await this.prisma.otpChallenge.updateMany({
        where: { id: challenge.id, attempts: { lt: this.maxAttempts } },
        data: { attempts: { increment: 1 } },
      });
      if (count === 0) throw tooManyAttempts();
      throw new AppException(
        ErrorCode.OTP_INVALID,
        HttpStatus.UNPROCESSABLE_ENTITY,
        'Ese código no coincide. Revisa el mensaje e inténtalo otra vez.',
      );
    }

    const { count } = await this.prisma.otpChallenge.updateMany({
      where: { id: challenge.id, consumedAt: null },
      data: { consumedAt: now },
    });
    if (count === 0) {
      throw new AppException(ErrorCode.OTP_NOT_REQUESTED, HttpStatus.CONFLICT, 'Pide un código primero.');
    }
  }

  private hash(phone: string, code: string): string {
    return createHmac('sha256', this.secret).update(`otp:${phone}:${code}`).digest('hex');
  }

  private matches(expected: string, actual: string): boolean {
    return timingSafeEqual(Buffer.from(expected, 'hex'), Buffer.from(actual, 'hex'));
  }
}

function tooManyAttempts() {
  return new AppException(
    ErrorCode.OTP_TOO_MANY_ATTEMPTS,
    HttpStatus.TOO_MANY_REQUESTS,
    'Demasiados intentos. Pide un código nuevo.',
  );
}
