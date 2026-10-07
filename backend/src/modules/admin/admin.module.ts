import { Module } from '@nestjs/common';
import { AuthModule } from '../auth/auth.module';
import { AdminCatalogController } from './catalog/admin-catalog.controller';
import { AdminProductsService } from './catalog/admin-products.service';
import { AdminStoresService } from './catalog/admin-stores.service';
import { AdminMarketingController } from './marketing/admin-marketing.controller';
import { AdminMarketingService } from './marketing/admin-marketing.service';
import { AdminPartnersController } from './partners/admin-partners.controller';
import { AdminPartnersService } from './partners/admin-partners.service';

/** Herramientas del equipo (rol ADMIN): alta de socios, catálogo, cupones y promociones. */
@Module({
  imports: [AuthModule],
  controllers: [AdminPartnersController, AdminCatalogController, AdminMarketingController],
  providers: [AdminPartnersService, AdminStoresService, AdminProductsService, AdminMarketingService],
})
export class AdminModule {}
