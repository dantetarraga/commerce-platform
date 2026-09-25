import { HttpStatus, Injectable } from '@nestjs/common';
import { AppException, ErrorCode } from '../../common/exceptions/app.exception';
import { PrismaService } from '../../database/prisma.service';
import { Prisma } from '../../generated/prisma/client';
import { Role } from '../../generated/prisma/enums';
import { toUserResponse, UserResponse, userWithRoles, UserWithRoles } from '../users/users.service';
import type { RegisterDto } from './dto/auth.dto';
import { OtpService } from './otp/otp.service';
import { SessionTokens, TokensService } from './tokens/tokens.service';

export type AuthResponse = SessionTokens & { user: UserResponse };

/** Respuesta de `POST /auth/otp/verify`. */
export type VerifyOtpResponse =
  ({ status: 'AUTHENTICATED' } & AuthResponse) | { status: 'PROFILE_REQUIRED'; registrationToken: string };

@Injectable()
export class AuthService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly otp: OtpService,
    private readonly tokens: TokensService,
  ) {}

  requestCode(phone: string) {
    return this.otp.request(phone);
  }

  /** Cuenta existente → sesión; número nuevo → token para completar el perfil. */
  async verifyCode(phone: string, code: string, userAgent?: string): Promise<VerifyOtpResponse> {
    await this.otp.verify(phone, code);
    const user = await this.prisma.user.findUnique({ where: { phone }, include: userWithRoles });
    if (!user) {
      return { status: 'PROFILE_REQUIRED', registrationToken: await this.tokens.signRegistration(phone) };
    }
    return { status: 'AUTHENTICATED', ...(await this.startSession(user, userAgent)) };
  }

  /**
   * Crea la cuenta (siempre CUSTOMER). Si el número ya tiene cuenta, p. ej.
   * por un doble tap, inicia sesión con ella en vez de fallar.
   */
  async register(dto: RegisterDto, userAgent?: string): Promise<AuthResponse> {
    const phone = await this.tokens.verifyRegistration(dto.registrationToken);
    const user = await this.createCustomer(phone, dto.firstName, dto.lastName);
    return this.startSession(user, userAgent);
  }

  refresh(refreshToken: string, userAgent?: string): Promise<SessionTokens> {
    return this.tokens.rotate(refreshToken, userAgent);
  }

  logout(refreshToken: string): Promise<void> {
    return this.tokens.revokeByToken(refreshToken);
  }

  private async createCustomer(phone: string, firstName: string, lastName: string): Promise<UserWithRoles> {
    try {
      return await this.prisma.user.create({
        data: { phone, firstName, lastName, roles: { create: { role: Role.CUSTOMER } } },
        include: userWithRoles,
      });
    } catch (error) {
      if (error instanceof Prisma.PrismaClientKnownRequestError && error.code === 'P2002') {
        return this.prisma.user.findUniqueOrThrow({ where: { phone }, include: userWithRoles });
      }
      throw error;
    }
  }

  private async startSession(user: UserWithRoles, userAgent?: string): Promise<AuthResponse> {
    if (!user.isActive) {
      throw new AppException(
        ErrorCode.USER_DISABLED,
        HttpStatus.FORBIDDEN,
        'Tu cuenta está desactivada. Escríbenos para ayudarte.',
      );
    }
    const response = toUserResponse(user);
    const tokens = await this.tokens.issueSession({ id: user.id, roles: response.roles }, userAgent);
    return { user: response, ...tokens };
  }
}
