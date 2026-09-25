import { Module } from '@nestjs/common';
import { CouponsModule } from '../coupons/coupons.module';
import { NotificationsModule } from '../notifications/notifications.module';
import { StoresModule } from '../stores/stores.module';
import { OrdersController } from './orders.controller';
import { OrdersService } from './orders.service';
import { OrderStatusService } from './status/order-status.service';

@Module({
  imports: [StoresModule, CouponsModule, NotificationsModule],
  controllers: [OrdersController],
  providers: [OrdersService, OrderStatusService],
  // Negocio y courier operan pedidos con los mismos servicios.
  exports: [OrdersService, OrderStatusService],
})
export class OrdersModule {}
