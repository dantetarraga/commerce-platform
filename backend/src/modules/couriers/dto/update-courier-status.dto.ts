import { IsIn } from 'class-validator';
import { CourierStatus } from '../../../generated/prisma/enums';
import type { CourierToggle } from '../couriers.service';

export class UpdateCourierStatusDto {
  @IsIn([CourierStatus.AVAILABLE, CourierStatus.OFFLINE], { message: 'Elige conectado o desconectado.' })
  status!: CourierToggle;
}
