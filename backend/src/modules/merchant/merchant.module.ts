import { Module } from '@nestjs/common';
import { OrdersModule } from '../orders/orders.module';
import { StoresModule } from '../stores/stores.module';
import { MerchantController } from './merchant.controller';
import { MerchantService } from './merchant.service';

@Module({
  imports: [OrdersModule, StoresModule],
  controllers: [MerchantController],
  providers: [MerchantService],
})
export class MerchantModule {}
