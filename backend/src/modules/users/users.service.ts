import { HttpStatus, Injectable } from '@nestjs/common';
import { AppException, ErrorCode } from '../../common/exceptions/app.exception';
import { PrismaService } from '../../database/prisma.service';
import { Prisma } from '../../generated/prisma/client';
import type { Role } from '../../generated/prisma/enums';
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
