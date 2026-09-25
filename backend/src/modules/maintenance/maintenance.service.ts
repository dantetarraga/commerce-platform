import { Injectable, Logger } from '@nestjs/common';
import { Cron, CronExpression } from '@nestjs/schedule';
import { PrismaService } from '../../database/prisma.service';

const DAY_MS = 24 * 60 * 60 * 1000;

/**
 * Limpieza diaria de datos de auth que ya no sirven, para que esas tablas no
 * crezcan sin límite:
 * - códigos OTP de hace más de un día (vencen a los 5 minutos);
 * - refresh tokens vencidos. Los rotados pero vigentes se conservan: son los
 *   que permiten detectar el reuso de un token robado.
 */
@Injectable()
export class MaintenanceService {
  private readonly logger = new Logger(MaintenanceService.name);

  constructor(private readonly prisma: PrismaService) {}

  @Cron(CronExpression.EVERY_DAY_AT_4AM, { name: 'purge-auth', timeZone: 'America/Lima' })
  async purgeAuthData(now = new Date()) {
    const [otp, tokens] = await Promise.all([
      this.prisma.otpChallenge.deleteMany({ where: { createdAt: { lt: new Date(now.getTime() - DAY_MS) } } }),
      this.prisma.refreshToken.deleteMany({ where: { expiresAt: { lt: now } } }),
    ]);
    this.logger.log(`Limpieza: ${otp.count} códigos OTP y ${tokens.count} refresh tokens vencidos`);
    return { otpChallenges: otp.count, refreshTokens: tokens.count };
  }
}
