import type { AuthUser } from '../../common/decorators/auth.decorators';
import { Role } from '../../generated/prisma/enums';
import type { OrderActor } from '../orders/status/order-status.service';

/** El admin opera cualquier negocio; el merchant, solo los suyos. */
export const actorOf = (user: AuthUser): OrderActor => ({
  userId: user.id,
  role: user.roles.includes(Role.ADMIN) ? Role.ADMIN : Role.MERCHANT,
});

/** Filtro por dueño: el merchant solo toca lo suyo; el admin (undefined), todo. */
export const ownerOf = (user: AuthUser) => (actorOf(user).role === Role.MERCHANT ? user.id : undefined);
