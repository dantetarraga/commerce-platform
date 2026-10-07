import { Body, Controller, Delete, Get, HttpCode, HttpStatus, Param, Patch, Post, Put, Query } from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import { Roles } from '../../../common/decorators/auth.decorators';
import { Role } from '../../../generated/prisma/enums';
import { AdminProductsService } from './admin-products.service';
import { AdminStoresService } from './admin-stores.service';
import { ProductDto, UpdateProductDto } from './product.dto';
import {
  CategoryDto,
  CreateStoreDto,
  ReplaceSchedulesDto,
  SectionDto,
  StoresQueryDto,
  UpdateCategoryDto,
  UpdateSectionDto,
  UpdateStoreDto,
} from './store.dto';

/** Catálogo editado por el equipo desde Swagger: negocios, horarios, secciones, productos y categorías. */
@ApiTags('admin · catálogo')
@ApiBearerAuth()
@Roles(Role.ADMIN)
@Controller('admin')
export class AdminCatalogController {
  constructor(
    private readonly stores: AdminStoresService,
    private readonly products: AdminProductsService,
  ) {}

  /** Incluye borradores y pausados. */
  @Get('stores')
  listStores(@Query() query: StoresQueryDto) {
    return this.stores.list(query.cityId);
  }

  /** Todo el negocio con su carta, con los ids para editar. */
  @Get('stores/:id')
  getStore(@Param('id') id: string) {
    return this.stores.get(id);
  }

  /** Queda en borrador salvo que venga `isActive: true`. */
  @Post('stores')
  createStore(@Body() dto: CreateStoreDto) {
    return this.stores.create(dto);
  }

  @Patch('stores/:id')
  updateStore(@Param('id') id: string, @Body() dto: UpdateStoreDto) {
    return this.stores.update(id, dto);
  }

  /** Reemplaza el horario completo. */
  @Put('stores/:id/schedules')
  replaceSchedules(@Param('id') id: string, @Body() dto: ReplaceSchedulesDto) {
    return this.stores.replaceSchedules(id, dto.schedules);
  }

  @Delete('stores/:id')
  @HttpCode(HttpStatus.NO_CONTENT)
  removeStore(@Param('id') id: string) {
    return this.stores.remove(id);
  }

  @Post('stores/:id/sections')
  createSection(@Param('id') storeId: string, @Body() dto: SectionDto) {
    return this.stores.createSection(storeId, dto);
  }

  @Patch('sections/:id')
  updateSection(@Param('id') id: string, @Body() dto: UpdateSectionDto) {
    return this.stores.updateSection(id, dto);
  }

  @Delete('sections/:id')
  @HttpCode(HttpStatus.NO_CONTENT)
  removeSection(@Param('id') id: string) {
    return this.stores.removeSection(id);
  }

  @Post('stores/:id/products')
  createProduct(@Param('id') storeId: string, @Body() dto: ProductDto) {
    return this.products.create(storeId, dto);
  }

  @Get('products/:id')
  getProduct(@Param('id') id: string) {
    return this.products.get(id);
  }

  /** `variants` y `options`, si vienen, reemplazan la lista: con `id` se editan, sin `id` se crean. */
  @Patch('products/:id')
  updateProduct(@Param('id') id: string, @Body() dto: UpdateProductDto) {
    return this.products.update(id, dto);
  }

  @Delete('products/:id')
  @HttpCode(HttpStatus.NO_CONTENT)
  removeProduct(@Param('id') id: string) {
    return this.products.remove(id);
  }

  @Post('categories')
  createCategory(@Body() dto: CategoryDto) {
    return this.stores.createCategory(dto);
  }

  @Patch('categories/:id')
  updateCategory(@Param('id') id: string, @Body() dto: UpdateCategoryDto) {
    return this.stores.updateCategory(id, dto);
  }
}
