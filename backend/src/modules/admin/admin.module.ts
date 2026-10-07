import { Module } from '@nestjs/common';
import { AuthModule } from '../auth/auth.module';
import { AdminCatalogController } from './catalog/admin-catalog.controller';
import { AdminProductsService } from './catalog/admin-products.service';
import { AdminStoresService } from './catalog/admin-stores.service';
import { AdminPartnersController } from './partners/admin-partners.controller';
import { AdminPartnersService } from './partners/admin-partners.service';

/** Herramientas del equipo (rol ADMIN): alta de socios y catálogo. */
@Module({
  imports: [AuthModule],
  controllers: [AdminPartnersController, AdminCatalogController],
  providers: [AdminPartnersService, AdminStoresService, AdminProductsService],
})
export class AdminModule {}
