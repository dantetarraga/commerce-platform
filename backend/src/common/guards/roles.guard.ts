import { CanActivate, ExecutionContext, HttpStatus, Injectable } from '@nestjs/common';
import { Reflector } from '@nestjs/core';
import type { Role } from '../../generated/prisma/enums';
import { AuthUser, ROLES_KEY } from '../decorators/auth.decorators';
import { AppException, ErrorCode } from '../exceptions/app.exception';

/** Global: solo actúa en rutas con `@Roles(...)`. Corre después del guard JWT. */
@Injectable()
export class RolesGuard implements CanActivate {
  constructor(private readonly reflector: Reflector) {}

  canActivate(context: ExecutionContext): boolean {
    const required = this.reflector.getAllAndOverride<Role[] | undefined>(ROLES_KEY, [
      context.getHandler(),
      context.getClass(),
    ]);
    if (!required?.length) return true;

    const user = context.switchToHttp().getRequest<{ user?: AuthUser }>().user;
    if (user?.roles.some((role) => required.includes(role))) return true;
    throw new AppException(ErrorCode.FORBIDDEN, HttpStatus.FORBIDDEN, 'No tienes permiso para hacer esto.');
  }
}
