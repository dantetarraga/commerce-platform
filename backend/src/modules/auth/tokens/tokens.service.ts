import { createHash, randomBytes, randomUUID } from 'node:crypto';
import { HttpStatus, Injectable } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { JwtService, TokenExpiredError } from '@nestjs/jwt';
import type { AuthUser } from '../../../common/decorators/auth.decorators';
import { AppException, ErrorCode } from '../../../common/exceptions/app.exception';
import type { Env } from '../../../config/env';
import { PrismaService } from '../../../database/prisma.service';
import type { Role } from '../../../generated/prisma/enums';

export interface SessionTokens {
  accessToken: string;
  refreshToken: string;
}

interface AccessPayload {
  sub: string;
  roles: Role[];
}

const ACCESS_AUDIENCE = 'access';
const REGISTRATION_AUDIENCE = 'registration';
const REGISTRATION_TTL_SECONDS = 15 * 60;
const DAY_MS = 24 * 60 * 60 * 1000;

export const sha256 = (value: string) => createHash('sha256').update(value).digest('hex');

/**
 * - Access token: JWT corto (`sub`, `roles`); se valida sin consultar la BD.
 * - Refresh token: opaco, guardado hasheado, rota en cada uso. Reusar uno ya
 *   rotado revoca toda la familia (posible robo).
 * - Registration token: JWT de 15 min que prueba que el celular se verificó.
 */
@Injectable()
export class TokensService {
  private readonly secret: string;
  private readonly accessTtlSeconds: number;
  private readonly refreshTtlMs: number;

  constructor(
    private readonly prisma: PrismaService,
    private readonly jwt: JwtService,
    config: ConfigService<Env, true>,
  ) {
    this.secret = config.get('JWT_ACCESS_SECRET', { infer: true });
    this.accessTtlSeconds = config.get('JWT_ACCESS_TTL_SECONDS', { infer: true });
    this.refreshTtlMs = config.get('REFRESH_TOKEN_TTL_DAYS', { infer: true }) * DAY_MS;
  }

  async issueSession(user: AuthUser, userAgent?: string): Promise<SessionTokens> {
    const { refreshToken } = await this.createRefreshToken(user.id, randomUUID(), userAgent);
    return { accessToken: await this.signAccess(user), refreshToken };
  }

  async rotate(refreshToken: string, userAgent?: string): Promise<SessionTokens> {
    const stored = await this.prisma.refreshToken.findUnique({
      where: { tokenHash: sha256(refreshToken) },
      include: { user: { include: { roles: true } } },
    });
    if (!stored) throw invalidRefresh();

    if (stored.revokedAt) {
      await this.revokeFamily(stored.familyId);
      throw invalidRefresh();
    }
    if (stored.expiresAt <= new Date() || !stored.user.isActive) {
      await this.revokeFamily(stored.familyId);
      throw invalidRefresh();
    }

    // Marca el token como usado de forma condicional: si otra request ya lo
    // rotó, se trata como reuso.
    const { count } = await this.prisma.refreshToken.updateMany({
      where: { id: stored.id, revokedAt: null },
      data: { revokedAt: new Date() },
    });
    if (count === 0) {
      await this.revokeFamily(stored.familyId);
      throw invalidRefresh();
    }

    const next = await this.createRefreshToken(stored.userId, stored.familyId, userAgent);
    await this.prisma.refreshToken.update({ where: { id: stored.id }, data: { replacedById: next.id } });
    const user = { id: stored.userId, roles: stored.user.roles.map((r) => r.role) };
    return { accessToken: await this.signAccess(user), refreshToken: next.refreshToken };
  }

  /** Logout: idempotente, no falla si el token no existe o ya estaba revocado. */
  async revokeByToken(refreshToken: string): Promise<void> {
    const stored = await this.prisma.refreshToken.findUnique({ where: { tokenHash: sha256(refreshToken) } });
    if (stored) await this.revokeFamily(stored.familyId);
  }

  async verifyAccess(token: string): Promise<AuthUser> {
    try {
      const payload = await this.jwt.verifyAsync<AccessPayload>(token, {
        secret: this.secret,
        audience: ACCESS_AUDIENCE,
      });
      return { id: payload.sub, roles: payload.roles };
    } catch (error) {
      if (error instanceof TokenExpiredError) {
        throw new AppException(ErrorCode.TOKEN_EXPIRED, HttpStatus.UNAUTHORIZED, 'Tu sesión expiró.');
      }
      throw new AppException(ErrorCode.UNAUTHORIZED, HttpStatus.UNAUTHORIZED, 'Inicia sesión para continuar.');
    }
  }

  signRegistration(phone: string): Promise<string> {
    return this.jwt.signAsync(
      { sub: phone },
      { secret: this.secret, audience: REGISTRATION_AUDIENCE, expiresIn: REGISTRATION_TTL_SECONDS },
    );
  }

  /** Devuelve el celular verificado. */
  async verifyRegistration(token: string): Promise<string> {
    try {
      const payload = await this.jwt.verifyAsync<{ sub: string }>(token, {
        secret: this.secret,
        audience: REGISTRATION_AUDIENCE,
      });
      return payload.sub;
    } catch {
      throw new AppException(ErrorCode.REGISTRATION_EXPIRED, HttpStatus.UNAUTHORIZED, 'Vuelve a verificar tu número.');
    }
  }

  private signAccess(user: AuthUser): Promise<string> {
    return this.jwt.signAsync({ sub: user.id, roles: user.roles } satisfies AccessPayload, {
      secret: this.secret,
      audience: ACCESS_AUDIENCE,
      expiresIn: this.accessTtlSeconds,
    });
  }

  private async createRefreshToken(userId: string, familyId: string, userAgent?: string) {
    const refreshToken = randomBytes(32).toString('base64url');
    const { id } = await this.prisma.refreshToken.create({
      data: {
        userId,
        familyId,
        tokenHash: sha256(refreshToken),
        expiresAt: new Date(Date.now() + this.refreshTtlMs),
        userAgent: userAgent?.slice(0, 255),
      },
      select: { id: true },
    });
    return { id, refreshToken };
  }

  /** Cierra todas sus sesiones; el access token vigente dura hasta que vence. */
  async revokeAllForUser(userId: string): Promise<void> {
    await this.prisma.refreshToken.updateMany({ where: { userId, revokedAt: null }, data: { revokedAt: new Date() } });
  }

  private async revokeFamily(familyId: string): Promise<void> {
    await this.prisma.refreshToken.updateMany({
      where: { familyId, revokedAt: null },
      data: { revokedAt: new Date() },
    });
  }
}

function invalidRefresh() {
  return new AppException(
    ErrorCode.INVALID_REFRESH_TOKEN,
    HttpStatus.UNAUTHORIZED,
    'Tu sesión expiró. Vuelve a ingresar.',
  );
}
