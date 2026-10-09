import { Module } from '@nestjs/common';
import { CouponsModule } from '../coupons/coupons.module';
import { NotificationsModule } from '../notifications/notifications.module';
import { StoresModule } from '../stores/stores.module';
import { OrdersController } from './orders.controller';
import { OrdersService } from './orders.service';
import { OrderStatusService } from './status/order-status.service';
import { UnansweredOrdersJob } from './status/unanswered-orders.job';

@Module({
  imports: [StoresModule, CouponsModule, NotificationsModule],
  controllers: [OrdersController],
  providers: [OrdersService, OrderStatusService, UnansweredOrdersJob],
  // Negocio y courier operan pedidos con los mismos servicios.
  exports: [OrdersService, OrderStatusService, UnansweredOrdersJob],
})
export class OrdersModule {}
