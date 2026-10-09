import { IsIn, IsString, Length } from 'class-validator';

export class RegisterDeviceDto {
  /** Token de FCM del teléfono. */
  @IsString()
  @Length(10, 4096)
  pushToken!: string;

  @IsIn(['android', 'ios'])
  platform!: 'android' | 'ios';

  /** La app que lo registra: Socios recibe la alarma de pedidos nuevos. */
  @IsIn(['customer', 'partner'])
  app!: 'customer' | 'partner';
}

export class UnregisterDeviceDto {
  @IsString()
  @Length(10, 4096)
  pushToken!: string;
}
