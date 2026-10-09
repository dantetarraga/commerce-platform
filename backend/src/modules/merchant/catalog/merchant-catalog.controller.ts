import { Body, Controller, Delete, Get, HttpCode, HttpStatus, Param, Patch, Post, Put } from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import { CurrentUser, Roles } from '../../../common/decorators/auth.decorators';
import type { AuthUser } from '../../../common/decorators/auth.decorators';
import { Role } from '../../../generated/prisma/enums';
import { ProductDto, UpdateProductDto } from '../../admin/catalog/product.dto';
import { ReplaceSchedulesDto, SectionDto, UpdateSectionDto } from '../../admin/catalog/store.dto';
import { ownerOf } from '../merchant-actor';
import { MerchantStoreProfileDto } from './merchant-catalog.dto';
import { MerchantCatalogService } from './merchant-catalog.service';

/** Portal Socios: el dueño edita los datos, horarios y carta de sus negocios. */
@ApiTags('merchant · catálogo')
@ApiBearerAuth()
@Roles(Role.MERCHANT, Role.ADMIN)
@Controller('merchant/catalog')
export class MerchantCatalogController {
  constructor(private readonly catalog: MerchantCatalogService) {}

  /** El negocio con su carta completa, con los ids para editar. */
  @Get('stores/:id')
  store(@CurrentUser() user: AuthUser, @Param('id') id: string) {
    return this.catalog.store(id, ownerOf(user));
  }

  /** Descripción, teléfono, logo, portada, tiempo de preparación y pedido mínimo. */
  @Patch('stores/:id')
  updateProfile(@CurrentUser() user: AuthUser, @Param('id') id: string, @Body() dto: MerchantStoreProfileDto) {
    return this.catalog.updateProfile(id, dto, ownerOf(user));
  }

  @Put('stores/:id/schedules')
  replaceSchedules(@CurrentUser() user: AuthUser, @Param('id') id: string, @Body() dto: ReplaceSchedulesDto) {
    return this.catalog.replaceSchedules(id, dto.schedules, ownerOf(user));
  }

  @Post('stores/:id/sections')
  createSection(@CurrentUser() user: AuthUser, @Param('id') id: string, @Body() dto: SectionDto) {
    return this.catalog.createSection(id, dto, ownerOf(user));
  }

  @Patch('sections/:id')
  updateSection(@CurrentUser() user: AuthUser, @Param('id') id: string, @Body() dto: UpdateSectionDto) {
    return this.catalog.updateSection(id, dto, ownerOf(user));
  }

  @Delete('sections/:id')
  @HttpCode(HttpStatus.NO_CONTENT)
  removeSection(@CurrentUser() user: AuthUser, @Param('id') id: string) {
    return this.catalog.removeSection(id, ownerOf(user));
  }

  @Post('stores/:id/products')
  createProduct(@CurrentUser() user: AuthUser, @Param('id') id: string, @Body() dto: ProductDto) {
    return this.catalog.createProduct(id, dto, ownerOf(user));
  }

  @Get('products/:id')
  product(@CurrentUser() user: AuthUser, @Param('id') id: string) {
    return this.catalog.product(id, ownerOf(user));
  }

  @Patch('products/:id')
  updateProduct(@CurrentUser() user: AuthUser, @Param('id') id: string, @Body() dto: UpdateProductDto) {
    return this.catalog.updateProduct(id, dto, ownerOf(user));
  }

  @Delete('products/:id')
  @HttpCode(HttpStatus.NO_CONTENT)
  removeProduct(@CurrentUser() user: AuthUser, @Param('id') id: string) {
    return this.catalog.removeProduct(id, ownerOf(user));
  }
}
