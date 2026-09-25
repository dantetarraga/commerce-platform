import { Module } from '@nestjs/common';
import { OrdersModule } from '../orders/orders.module';
import { StoresModule } from '../stores/stores.module';
import { MerchantController } from './merchant.controller';

@Module({
  imports: [OrdersModule, StoresModule],
  controllers: [MerchantController],
})
export class MerchantModule {}
