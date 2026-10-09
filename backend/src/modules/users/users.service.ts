import { HttpStatus, Injectable } from '@nestjs/common';
import { AppException, ErrorCode } from '../../common/exceptions/app.exception';
import { PrismaService } from '../../database/prisma.service';
import { Prisma } from '../../generated/prisma/client';
import { Role } from '../../generated/prisma/enums';
import { FINAL_STATUSES } from '../orders/order-list-scope';
import type { UpdateMeDto } from './dto/update-me.dto';

/** `UserDto` de la app. */
export interface UserResponse {
  id: string;
  phone: string;
  firstName: string;
  lastName: string;
  email: string | null;
  avatarUrl: string | null;
  roles: Role[];
}

export const userWithRoles = { roles: true } satisfies Prisma.UserInclude;
export type UserWithRoles = Prisma.UserGetPayload<{ include: typeof userWithRoles }>;

export function toUserResponse(user: UserWithRoles): UserResponse {
  return {
    id: user.id,
    phone: user.phone,
    firstName: user.firstName,
    lastName: user.lastName,
    email: user.email,
    avatarUrl: user.avatarUrl,
    roles: user.roles.map((r) => r.role),
  };
}

@Injectable()
export class UsersService {
  constructor(private readonly prisma: PrismaService) {}

  async me(userId: string): Promise<UserResponse> {
    const user = await this.prisma.user.findUnique({ where: { id: userId }, include: userWithRoles });
    // Usuario borrado o desactivado con un access token todavía vigente.
    if (!user?.isActive) {
      throw new AppException(ErrorCode.UNAUTHORIZED, HttpStatus.UNAUTHORIZED, 'Inicia sesión para continuar.');
    }
    return toUserResponse(user);
  }

  /**
   * Elimina la cuenta: borra los datos personales y la desactiva. Los pedidos se
   * conservan sin nombre ni celular (contabilidad). Un socio o el equipo se dan de baja
   * con Apamuy, para no dejar negocios ni repartos sin responsable.
   */
  async deleteMe(userId: string): Promise<void> {
    const user = await this.prisma.user.findUnique({ where: { id: userId }, include: userWithRoles });
    if (!user?.isActive) return;
    if (user.roles.some(({ role }) => role !== Role.CUSTOMER)) {
      throw new AppException(
        ErrorCode.PARTNER_ACCOUNT,
        HttpStatus.CONFLICT,
        'Tu cuenta es de un socio de Apamuy. Escríbenos para darla de baja junto con tu negocio o tus repartos.',
      );
    }
    const active = await this.prisma.order.count({
      where: { customerId: userId, status: { notIn: FINAL_STATUSES } },
    });
    if (active > 0) {
      throw new AppException(
        ErrorCode.ACCOUNT_HAS_ACTIVE_ORDER,
        HttpStatus.CONFLICT,
        'Tienes un pedido en curso. Podrás eliminar tu cuenta cuando termine.',
      );
    }
    await this.prisma.$transaction([
      this.prisma.address.deleteMany({ where: { userId } }),
      this.prisma.device.deleteMany({ where: { userId } }),
      this.prisma.notification.deleteMany({ where: { userId } }),
      this.prisma.refreshToken.deleteMany({ where: { userId } }),
      this.prisma.otpChallenge.deleteMany({ where: { phone: user.phone } }),
      // El celular queda libre: quien vuelva a registrarse con él empieza de cero.
      this.prisma.user.update({
        where: { id: userId },
        data: {
          phone: `deleted:${userId}`,
          email: null,
          firstName: 'Cuenta',
          lastName: 'eliminada',
          avatarUrl: null,
          isActive: false,
        },
      }),
    ]);
  }

  async updateMe(userId: string, dto: UpdateMeDto): Promise<UserResponse> {
    await this.me(userId);
    try {
      const user = await this.prisma.user.update({ where: { id: userId }, data: dto, include: userWithRoles });
      return toUserResponse(user);
    } catch (error) {
      if (error instanceof Prisma.PrismaClientKnownRequestError && error.code === 'P2002') {
        throw new AppException(
          ErrorCode.EMAIL_ALREADY_EXISTS,
          HttpStatus.CONFLICT,
          'Ese correo ya está en uso por otra cuenta.',
        );
      }
      throw error;
    }
  }
}
