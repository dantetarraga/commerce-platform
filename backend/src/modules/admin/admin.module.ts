import { Module } from '@nestjs/common';
import { AuthModule } from '../auth/auth.module';
import { OrdersModule } from '../orders/orders.module';
import { AdminCashController } from './cash/admin-cash.controller';
import { AdminCashService } from './cash/admin-cash.service';
import { AdminCatalogController } from './catalog/admin-catalog.controller';
import { AdminCitiesController } from './cities/admin-cities.controller';
import { AdminCitiesService } from './cities/admin-cities.service';
import { AdminProductsService } from './catalog/admin-products.service';
import { AdminStoresService } from './catalog/admin-stores.service';
import { AdminMarketingController } from './marketing/admin-marketing.controller';
import { AdminMarketingService } from './marketing/admin-marketing.service';
import { AdminOrdersController } from './orders/admin-orders.controller';
import { AdminOrdersService } from './orders/admin-orders.service';
import { AdminPartnersController } from './partners/admin-partners.controller';
import { AdminPartnersService } from './partners/admin-partners.service';

/** Herramientas del equipo (rol ADMIN): alta de socios, catálogo, cupones, promociones, ciudades, pedidos en vivo y caja. */
@Module({
  imports: [AuthModule, OrdersModule],
  controllers: [
    AdminPartnersController,
    AdminCatalogController,
    AdminMarketingController,
    AdminCitiesController,
    AdminOrdersController,
    AdminCashController,
  ],
  providers: [
    AdminPartnersService,
    AdminStoresService,
    AdminProductsService,
    AdminMarketingService,
    AdminCitiesService,
    AdminOrdersService,
    AdminCashService,
  ],
  // El Portal Socios edita su propio catálogo con los mismos servicios.
  exports: [AdminStoresService, AdminProductsService],
})
export class AdminModule {}
