import { Module } from '@nestjs/common';
import { AdminModule } from '../admin/admin.module';
import { OrdersModule } from '../orders/orders.module';
import { StoresModule } from '../stores/stores.module';
import { MerchantCatalogController } from './catalog/merchant-catalog.controller';
import { MerchantCatalogService } from './catalog/merchant-catalog.service';
import { MerchantController } from './merchant.controller';
import { MerchantService } from './merchant.service';

@Module({
  imports: [OrdersModule, StoresModule, AdminModule],
  controllers: [MerchantController, MerchantCatalogController],
  providers: [MerchantService, MerchantCatalogService],
})
export class MerchantModule {}
