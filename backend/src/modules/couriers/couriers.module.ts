import { Module } from '@nestjs/common';
import { OrdersModule } from '../orders/orders.module';
import { CouriersController } from './couriers.controller';

@Module({
  imports: [OrdersModule],
  controllers: [CouriersController],
})
export class CouriersModule {}
