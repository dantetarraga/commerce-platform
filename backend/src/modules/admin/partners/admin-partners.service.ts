import { HttpStatus, Injectable } from '@nestjs/common';
import { AppException, ErrorCode } from '../../../common/exceptions/app.exception';
import { PrismaService } from '../../../database/prisma.service';
import { Prisma } from '../../../generated/prisma/client';
import { CourierStatus, Role } from '../../../generated/prisma/enums';
import { TokensService } from '../../auth/tokens/tokens.service';
import { FINAL_STATUSES } from '../../orders/order-list-scope';
import { CreateCourierDto, CreateMerchantDto, PARTNER_ROLES, PartnerRole } from './partners.dto';

const partnerInclude = {
  roles: { select: { role: true } },
  ownedStores: { where: { deletedAt: null }, select: { id: true, name: true, isAcceptingOrders: true } },
  courier: { select: { cityId: true, vehicleType: true, vehicleLabel: true, plate: true, status: true } },
} satisfies Prisma.UserInclude;

type PartnerUser = Prisma.UserGetPayload<{ include: typeof partnerInclude }>;

function toPartner(user: PartnerUser) {
  return {
    id: user.id,
    phone: user.phone,
    firstName: user.firstName,
    lastName: user.lastName,
    isActive: user.isActive,
    roles: user.roles.map((r) => r.role),
    stores: user.ownedStores,
    courier: user.courier,
  };
}

/** Alta y suspensión de socios (OPERACION.md §5); el equipo lo usa desde Swagger. */
@Injectable()
export class AdminPartnersService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly tokens: TokensService,
  ) {}

  async findByPhone(phone: string) {
    const user = await this.prisma.user.findUnique({ where: { phone }, include: partnerInclude });
    if (!user) throw AppException.notFound('No hay ninguna cuenta con ese celular.');
    return toPartner(user);
  }

  createMerchant(dto: CreateMerchantDto) {
    const storeIds = dto.storeIds ?? [];
    return this.prisma.$transaction(async (tx) => {
      const { userId, created } = await this.upsertUser(tx, dto);
      if (storeIds.length) {
        const found = await tx.store.count({ where: { id: { in: storeIds }, deletedAt: null } });
        if (found !== storeIds.length) throw AppException.notFound('Alguno de esos negocios no existe.');
        await tx.store.updateMany({ where: { id: { in: storeIds } }, data: { ownerId: userId } });
      }
      await this.grant(tx, userId, Role.MERCHANT);
      return { created, user: await this.load(tx, userId) };
    });
  }

  createCourier(dto: CreateCourierDto) {
    return this.prisma.$transaction(async (tx) => {
      const city = await tx.city.findUnique({ where: { id: dto.cityId }, select: { id: true } });
      if (!city) throw AppException.notFound('Esa ciudad no existe.');
      const { userId, created } = await this.upsertUser(tx, dto);
      const vehicle = {
        cityId: dto.cityId,
        vehicleType: dto.vehicleType,
        vehicleLabel: dto.vehicleLabel,
        plate: dto.plate ?? null,
        // Editar el vehículo no debe borrar la antigüedad que el formulario no envía.
        ...(dto.activeSince !== undefined && { activeSince: dto.activeSince }),
      };
      await tx.courier.upsert({ where: { userId }, create: { userId, ...vehicle }, update: vehicle });
      await this.grant(tx, userId, Role.COURIER);
      return { created, user: await this.load(tx, userId) };
    });
  }

  /**
   * Quita los roles de socio y cierra sus sesiones. Un repartidor con un pedido
   * en curso no se suspende; los negocios del dueño dejan de recibir pedidos.
   */
  async suspendPartner(userId: string, roles: readonly PartnerRole[] = PARTNER_ROLES) {
    const user = await this.prisma.$transaction(async (tx) => {
      const current = await tx.user.findUnique({ where: { id: userId }, include: partnerInclude });
      if (!current) throw AppException.notFound('No encontramos ese usuario.');
      const held = current.roles.map((r) => r.role);
      const removing = roles.filter((role) => held.includes(role));

      if (removing.includes(Role.COURIER) && current.courier) {
        const active = await tx.order.count({ where: { courier: { userId }, status: { notIn: FINAL_STATUSES } } });
        if (active > 0) {
          throw new AppException(
            ErrorCode.COURIER_HAS_ACTIVE_ORDER,
            HttpStatus.CONFLICT,
            'El repartidor tiene un pedido en curso. Resuélvelo antes de suspenderlo.',
          );
        }
        await tx.courier.update({ where: { userId }, data: { status: CourierStatus.OFFLINE } });
      }
      if (removing.includes(Role.MERCHANT)) {
        await tx.store.updateMany({ where: { ownerId: userId }, data: { isAcceptingOrders: false } });
      }
      await tx.userRole.deleteMany({ where: { userId, role: { in: removing } } });
      return this.load(tx, userId);
    });
    await this.tokens.revokeAllForUser(userId);
    return user;
  }

  /** La cuenta del celular, o una nueva de cliente. */
  private async upsertUser(tx: Prisma.TransactionClient, dto: CreateMerchantDto | CreateCourierDto) {
    const existing = await tx.user.findUnique({ where: { phone: dto.phone }, select: { id: true, isActive: true } });
    if (existing) {
      if (!existing.isActive) {
        throw new AppException(ErrorCode.USER_DISABLED, HttpStatus.CONFLICT, 'Esa cuenta está desactivada.');
      }
      return { userId: existing.id, created: false };
    }
    const user = await tx.user.create({
      data: {
        phone: dto.phone,
        firstName: dto.firstName,
        lastName: dto.lastName,
        roles: { create: { role: Role.CUSTOMER } },
      },
      select: { id: true },
    });
    return { userId: user.id, created: true };
  }

  private grant(tx: Prisma.TransactionClient, userId: string, role: Role) {
    return tx.userRole.upsert({ where: { userId_role: { userId, role } }, create: { userId, role }, update: {} });
  }

  private async load(tx: Prisma.TransactionClient, userId: string) {
    return toPartner(await tx.user.findUniqueOrThrow({ where: { id: userId }, include: partnerInclude }));
  }
}
