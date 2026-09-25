import { ConfigService } from '@nestjs/config';
import { mockDeep } from 'jest-mock-extended';
import { AppException } from '../../../common/exceptions/app.exception';
import type { PrismaService } from '../../../database/prisma.service';
import type { OtpChallenge } from '../../../generated/prisma/client';
import { OtpService } from './otp.service';
import { SmsDeliveryError, SmsInvalidNumberError, SmsSender } from '../sms/sms-sender';

const PHONE = '987654321';
const NOW = new Date('2026-09-24T12:00:00Z');

function setup(env: Record<string, unknown> = {}) {
  const prisma = mockDeep<PrismaService>();
  const sms = { send: jest.fn().mockResolvedValue(undefined) } as unknown as jest.Mocked<SmsSender>;
  const values: Record<string, unknown> = {
    OTP_SECRET: 'x'.repeat(32),
    OTP_TTL_SECONDS: 300,
    OTP_RESEND_SECONDS: 30,
    OTP_MAX_ATTEMPTS: 5,
    ...env,
  };
  const config = { get: (key: string) => values[key] } as unknown as ConfigService;
  return { prisma, sms, service: new OtpService(prisma, sms, config as never) };
}

async function codeOf(error: Promise<unknown>) {
  try {
    await error;
  } catch (e) {
    return (e as AppException).code;
  }
  throw new Error('no lanzó');
}

describe('OtpService.request', () => {
  it('guarda solo el hash y envía el código por SMS', async () => {
    const { prisma, sms, service } = setup({ OTP_DEV_CODE: '123456' });
    prisma.otpChallenge.findMany.mockResolvedValue([]);

    await expect(service.request(PHONE, NOW)).resolves.toEqual({
      phone: PHONE,
      resendAfterSeconds: 30,
      codeLength: 6,
    });

    const data = prisma.otpChallenge.create.mock.calls[0][0].data;
    expect(data.codeHash).not.toContain('123456');
    expect(data.expiresAt).toEqual(new Date(NOW.getTime() + 300_000));
    expect(sms.send).toHaveBeenCalledWith(PHONE, expect.stringContaining('123456'));
  });

  it('si el SMS falla, borra el código para poder reintentar enseguida', async () => {
    const { prisma, sms, service } = setup();
    prisma.otpChallenge.findMany.mockResolvedValue([]);
    prisma.otpChallenge.create.mockResolvedValue({ id: 'otp_9' } as OtpChallenge);
    sms.send.mockRejectedValue(new SmsDeliveryError('caído'));

    expect(await codeOf(service.request(PHONE, NOW))).toBe('SMS_SEND_FAILED');
    expect(prisma.otpChallenge.delete).toHaveBeenCalledWith({ where: { id: 'otp_9' } });
  });

  it('número rechazado por el proveedor → SMS_INVALID_NUMBER', async () => {
    const { prisma, sms, service } = setup();
    prisma.otpChallenge.findMany.mockResolvedValue([]);
    prisma.otpChallenge.create.mockResolvedValue({ id: 'otp_9' } as OtpChallenge);
    sms.send.mockRejectedValue(new SmsInvalidNumberError('no es celular'));

    expect(await codeOf(service.request(PHONE, NOW))).toBe('SMS_INVALID_NUMBER');
  });

  it('no permite pedir otro código antes del tiempo de reenvío', async () => {
    const { prisma, service } = setup();
    prisma.otpChallenge.findMany.mockResolvedValue([{ createdAt: new Date(NOW.getTime() - 10_000) } as OtpChallenge]);
    expect(await codeOf(service.request(PHONE, NOW))).toBe('OTP_RESEND_TOO_SOON');
  });

  it('limita los códigos por hora', async () => {
    const { prisma, service } = setup();
    prisma.otpChallenge.findMany.mockResolvedValue(
      Array.from({ length: 5 }, (_, i) => ({ createdAt: new Date(NOW.getTime() - (i + 1) * 60_000) }) as OtpChallenge),
    );
    expect(await codeOf(service.request(PHONE, NOW))).toBe('OTP_TOO_MANY_REQUESTS');
  });
});

describe('OtpService.verify', () => {
  async function challengeFor(code: string, overrides: Partial<OtpChallenge> = {}) {
    // Genera un hash real pidiendo el código con OTP_DEV_CODE.
    const { prisma, service } = setup({ OTP_DEV_CODE: code });
    prisma.otpChallenge.findMany.mockResolvedValue([]);
    await service.request(PHONE, NOW);
    const { codeHash } = prisma.otpChallenge.create.mock.calls[0][0].data;
    return {
      id: 'otp_1',
      phone: PHONE,
      codeHash,
      attempts: 0,
      expiresAt: new Date(NOW.getTime() + 300_000),
      consumedAt: null,
      createdAt: NOW,
      ...overrides,
    } satisfies OtpChallenge;
  }

  it('consume el código correcto', async () => {
    const { prisma, service } = setup();
    prisma.otpChallenge.findFirst.mockResolvedValue(await challengeFor('654321'));
    prisma.otpChallenge.updateMany.mockResolvedValue({ count: 1 });

    await expect(service.verify(PHONE, '654321', NOW)).resolves.toBeUndefined();
    expect(prisma.otpChallenge.updateMany).toHaveBeenCalledWith({
      where: { id: 'otp_1', consumedAt: null },
      data: { consumedAt: NOW },
    });
  });

  it('un código incorrecto suma un intento', async () => {
    const { prisma, service } = setup();
    prisma.otpChallenge.findFirst.mockResolvedValue(await challengeFor('654321'));
    prisma.otpChallenge.updateMany.mockResolvedValue({ count: 1 });

    expect(await codeOf(service.verify(PHONE, '111111', NOW))).toBe('OTP_INVALID');
    expect(prisma.otpChallenge.updateMany).toHaveBeenCalledWith({
      where: { id: 'otp_1', attempts: { lt: 5 } },
      data: { attempts: { increment: 1 } },
    });
  });

  it.each([
    ['sin código pedido', null, 'OTP_NOT_REQUESTED'],
    ['código ya usado', { consumedAt: NOW }, 'OTP_NOT_REQUESTED'],
    ['código vencido', { expiresAt: NOW }, 'OTP_EXPIRED'],
    ['sin intentos', { attempts: 5 }, 'OTP_TOO_MANY_ATTEMPTS'],
  ])('%s → %s', async (_label, overrides, expected) => {
    const { prisma, service } = setup();
    prisma.otpChallenge.findFirst.mockResolvedValue(
      overrides === null ? null : await challengeFor('654321', overrides),
    );
    expect(await codeOf(service.verify(PHONE, '654321', NOW))).toBe(expected);
  });
});
