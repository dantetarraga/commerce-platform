import { Injectable } from '@nestjs/common';
import { AppException } from '../../../common/exceptions/app.exception';
import { PrismaService } from '../../../database/prisma.service';
import { AdminProductsService } from '../../admin/catalog/admin-products.service';
import { AdminStoresService } from '../../admin/catalog/admin-stores.service';
import { ProductDto, UpdateProductDto } from '../../admin/catalog/product.dto';
import { OpeningHoursDto, SectionDto, UpdateSectionDto } from '../../admin/catalog/store.dto';
import { MerchantStoreProfileDto } from './merchant-catalog.dto';

/**
 * Catálogo editado por el dueño desde el Portal Socios. Reusa los servicios del
 * admin; aquí solo se comprueba que el negocio sea suyo (`ownerId` indefinido: admin).
 * Lo ajeno responde 404, sin revelar que existe.
 */
@Injectable()
export class MerchantCatalogService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly stores: AdminStoresService,
    private readonly products: AdminProductsService,
  ) {}

  async store(storeId: string, ownerId?: string) {
    await this.ownStore(storeId, ownerId);
    return this.stores.get(storeId);
  }

  async updateProfile(storeId: string, dto: MerchantStoreProfileDto, ownerId?: string) {
    await this.ownStore(storeId, ownerId);
    return this.stores.update(storeId, dto);
  }

  async replaceSchedules(storeId: string, schedules: OpeningHoursDto[], ownerId?: string) {
    await this.ownStore(storeId, ownerId);
    return this.stores.replaceSchedules(storeId, schedules);
  }

  async createSection(storeId: string, dto: SectionDto, ownerId?: string) {
    await this.ownStore(storeId, ownerId);
    return this.stores.createSection(storeId, dto);
  }

  async updateSection(sectionId: string, dto: UpdateSectionDto, ownerId?: string) {
    await this.ownSection(sectionId, ownerId);
    return this.stores.updateSection(sectionId, dto);
  }

  async removeSection(sectionId: string, ownerId?: string) {
    await this.ownSection(sectionId, ownerId);
    return this.stores.removeSection(sectionId);
  }

  async createProduct(storeId: string, dto: ProductDto, ownerId?: string) {
    await this.ownStore(storeId, ownerId);
    return this.products.create(storeId, dto);
  }

  async product(productId: string, ownerId?: string) {
    await this.ownProduct(productId, ownerId);
    return this.products.get(productId);
  }

  async updateProduct(productId: string, dto: UpdateProductDto, ownerId?: string) {
    await this.ownProduct(productId, ownerId);
    return this.products.update(productId, dto);
  }

  async removeProduct(productId: string, ownerId?: string) {
    await this.ownProduct(productId, ownerId);
    return this.products.remove(productId);
  }

  private async ownStore(storeId: string, ownerId?: string) {
    const count = await this.prisma.store.count({ where: { id: storeId, deletedAt: null, ownerId } });
    if (count === 0) throw AppException.notFound('No encontramos ese negocio.');
  }

  private async ownSection(sectionId: string, ownerId?: string) {
    const count = await this.prisma.menuSection.count({
      where: { id: sectionId, store: { deletedAt: null, ownerId } },
    });
    if (count === 0) throw AppException.notFound('No encontramos esa sección.');
  }

  private async ownProduct(productId: string, ownerId?: string) {
    const count = await this.prisma.product.count({
      where: { id: productId, deletedAt: null, store: { deletedAt: null, ownerId } },
    });
    if (count === 0) throw AppException.notFound('No encontramos ese producto.');
  }
}
