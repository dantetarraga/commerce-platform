import { HttpStatus, Injectable } from '@nestjs/common';
import { AppException, ErrorCode } from '../../../common/exceptions/app.exception';
import { PrismaService } from '../../../database/prisma.service';
import { Prisma } from '../../../generated/prisma/client';
import { Role } from '../../../generated/prisma/enums';
import { FINAL_STATUSES } from '../../orders/order-list-scope';
import { adminStoreInclude, toAdminStore } from './catalog-presenter';
import { freeSlug, invalid, scheduleErrors, slugify } from './catalog-rules';
import {
  CategoryDto,
  CreateStoreDto,
  OpeningHoursDto,
  SectionDto,
  UpdateCategoryDto,
  UpdateSectionDto,
  UpdateStoreDto,
} from './store.dto';

/** Negocios, horarios, secciones del menú y categorías, editados por el admin. */
@Injectable()
export class AdminStoresService {
  constructor(private readonly prisma: PrismaService) {}

  async list(cityId?: string) {
    const stores = await this.prisma.store.findMany({
      where: { deletedAt: null, ...(cityId && { cityId }) },
      orderBy: { name: 'asc' },
      select: {
        id: true,
        cityId: true,
        ownerId: true,
        name: true,
        slug: true,
        isActive: true,
        isAcceptingOrders: true,
        _count: { select: { products: { where: { deletedAt: null } } } },
      },
    });
    return stores.map(({ _count, ...store }) => ({ ...store, productCount: _count.products }));
  }

  async get(id: string) {
    const store = await this.prisma.store.findFirst({
      where: { id, deletedAt: null },
      include: { ...adminStoreInclude, city: { select: { currency: true } } },
    });
    if (!store) throw AppException.notFound('No encontramos ese negocio.');
    return toAdminStore(store, store.city.currency);
  }

  async create(dto: CreateStoreDto) {
    const { cityId, ownerId, schedules = [], categoryIds = [], minOrderAmount, ...fields } = dto;
    const city = await this.prisma.city.findUnique({ where: { id: cityId }, select: { id: true } });
    if (!city) throw AppException.notFound('Esa ciudad no existe.');
    await this.assertMerchant(ownerId);
    await this.assertCategories(categoryIds);
    this.assertSchedules(schedules);

    const base = slugify(dto.name) || 'negocio';
    const taken = await this.prisma.store.findMany({
      where: { cityId, slug: { startsWith: base } },
      select: { slug: true },
    });
    const store = await this.prisma.store.create({
      data: {
        ...fields,
        isActive: dto.isActive ?? false,
        slug: freeSlug(base, new Set(taken.map((t) => t.slug))),
        minOrderAmount: minOrderAmount?.amount ?? 0,
        city: { connect: { id: cityId } },
        owner: { connect: { id: ownerId } },
        schedules: { create: schedules },
        categories: { create: categoryIds.map((categoryId) => ({ categoryId })) },
      },
    });
    return this.get(store.id);
  }

  async update(id: string, dto: UpdateStoreDto) {
    await this.findStore(id);
    const { ownerId, categoryIds, minOrderAmount, ...fields } = dto;
    if (ownerId) await this.assertMerchant(ownerId);
    if (categoryIds) await this.assertCategories(categoryIds);

    await this.prisma.$transaction(async (tx) => {
      await tx.store.update({
        where: { id },
        data: {
          ...fields,
          ...(ownerId && { owner: { connect: { id: ownerId } } }),
          ...(minOrderAmount && { minOrderAmount: minOrderAmount.amount }),
        },
      });
      if (categoryIds) {
        await tx.storeCategory.deleteMany({ where: { storeId: id } });
        await tx.storeCategory.createMany({ data: categoryIds.map((categoryId) => ({ storeId: id, categoryId })) });
      }
    });
    return this.get(id);
  }

  async replaceSchedules(id: string, schedules: OpeningHoursDto[]) {
    await this.findStore(id);
    this.assertSchedules(schedules);
    await this.prisma.$transaction([
      this.prisma.storeSchedule.deleteMany({ where: { storeId: id } }),
      this.prisma.storeSchedule.createMany({ data: schedules.map((h) => ({ storeId: id, ...h })) }),
    ]);
    return this.get(id);
  }

  /** Se oculta y deja de recibir pedidos; sus pedidos pasados no cambian. */
  async remove(id: string) {
    await this.findStore(id);
    const active = await this.prisma.order.count({ where: { storeId: id, status: { notIn: FINAL_STATUSES } } });
    if (active > 0) {
      throw new AppException(
        ErrorCode.CONFLICT,
        HttpStatus.CONFLICT,
        'El negocio tiene pedidos en curso. Espera a que terminen para quitarlo.',
      );
    }
    await this.prisma.store.update({
      where: { id },
      data: { deletedAt: new Date(), isActive: false, isAcceptingOrders: false },
    });
  }

  async createSection(storeId: string, dto: SectionDto) {
    await this.findStore(storeId);
    const sortOrder = dto.sortOrder ?? (await this.prisma.menuSection.count({ where: { storeId } }));
    const { id, name } = await this.prisma.menuSection.create({ data: { storeId, name: dto.name, sortOrder } });
    return { id, name, sortOrder };
  }

  async updateSection(id: string, dto: UpdateSectionDto) {
    await this.findSection(id);
    const { name, sortOrder } = await this.prisma.menuSection.update({ where: { id }, data: dto });
    return { id, name, sortOrder };
  }

  /** Sus productos quedan sin sección (siguen en la carta). */
  async removeSection(id: string) {
    await this.findSection(id);
    await this.prisma.menuSection.delete({ where: { id } });
  }

  async createCategory(dto: CategoryDto) {
    const slug = dto.slug ? slugify(dto.slug) : slugify(dto.name);
    try {
      return await this.prisma.category.create({ data: { ...dto, slug } });
    } catch (error) {
      throw this.slugTaken(error) ?? error;
    }
  }

  async updateCategory(id: string, dto: UpdateCategoryDto) {
    if (!(await this.prisma.category.findUnique({ where: { id }, select: { id: true } }))) {
      throw AppException.notFound('No encontramos esa categoría.');
    }
    try {
      return await this.prisma.category.update({
        where: { id },
        data: { ...dto, ...(dto.slug && { slug: slugify(dto.slug) }) },
      });
    } catch (error) {
      throw this.slugTaken(error) ?? error;
    }
  }

  private async findStore(id: string) {
    const store = await this.prisma.store.findFirst({ where: { id, deletedAt: null }, select: { id: true } });
    if (!store) throw AppException.notFound('No encontramos ese negocio.');
  }

  private async findSection(id: string) {
    const section = await this.prisma.menuSection.findFirst({
      where: { id, store: { deletedAt: null } },
      select: { id: true },
    });
    if (!section) throw AppException.notFound('No encontramos esa sección.');
  }

  private async assertMerchant(userId: string) {
    const role = await this.prisma.userRole.findUnique({ where: { userId_role: { userId, role: Role.MERCHANT } } });
    if (!role) throw invalid({ ownerId: 'El dueño debe tener el rol de negocio (POST admin/merchants).' });
  }

  private async assertCategories(ids: string[]) {
    if (!ids.length) return;
    const found = await this.prisma.category.count({ where: { id: { in: ids } } });
    if (found !== ids.length) throw invalid({ categoryIds: 'Alguna de esas categorías no existe.' });
  }

  private assertSchedules(schedules: OpeningHoursDto[]) {
    const errors = scheduleErrors(schedules);
    if (Object.keys(errors).length) throw invalid(errors);
  }

  private slugTaken(error: unknown) {
    if (error instanceof Prisma.PrismaClientKnownRequestError && error.code === 'P2002') {
      return new AppException(ErrorCode.CONFLICT, HttpStatus.CONFLICT, 'Ya hay una categoría con ese slug.');
    }
    return undefined;
  }
}
