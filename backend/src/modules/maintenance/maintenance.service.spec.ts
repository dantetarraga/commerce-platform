import { mockDeep } from 'jest-mock-extended';
import type { PrismaService } from '../../database/prisma.service';
import { MaintenanceService } from './maintenance.service';

describe('MaintenanceService.purgeAuthData', () => {
  it('borra OTP de más de un día y solo refresh tokens vencidos', async () => {
    const prisma = mockDeep<PrismaService>();
    prisma.otpChallenge.deleteMany.mockResolvedValue({ count: 3 });
    prisma.refreshToken.deleteMany.mockResolvedValue({ count: 2 });
    const now = new Date('2026-09-25T09:00:00Z');

    await expect(new MaintenanceService(prisma).purgeAuthData(now)).resolves.toEqual({
      otpChallenges: 3,
      refreshTokens: 2,
    });
    expect(prisma.otpChallenge.deleteMany).toHaveBeenCalledWith({
      where: { createdAt: { lt: new Date('2026-09-24T09:00:00Z') } },
    });
    // Un token rotado pero vigente se conserva para detectar reuso.
    expect(prisma.refreshToken.deleteMany).toHaveBeenCalledWith({ where: { expiresAt: { lt: now } } });
  });
});
