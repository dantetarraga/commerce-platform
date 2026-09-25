import { Module } from '@nestjs/common';
import { CouponsModule } from '../coupons/coupons.module';
import { StoresModule } from '../stores/stores.module';
import { OrdersController } from './orders.controller';
import { OrdersService } from './orders.service';

@Module({
  imports: [StoresModule, CouponsModule],
  controllers: [OrdersController],
  providers: [OrdersService],
})
export class OrdersModule {}
