import { Module } from '@nestjs/common';
import { OrdersModule } from '../orders/orders.module';
import { CouriersController } from './couriers.controller';
import { CouriersService } from './couriers.service';

@Module({
  imports: [OrdersModule],
  controllers: [CouriersController],
  providers: [CouriersService],
})
export class CouriersModule {}
