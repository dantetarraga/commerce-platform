import { IsOptional, IsString, Matches } from 'class-validator';

export class AdminCashQueryDto {
  /** Día de entrega en hora de Lima; sin fecha, hoy. */
  @IsOptional()
  @Matches(/^\d{4}-\d{2}-\d{2}$/, { message: 'La fecha va como AAAA-MM-DD.' })
  date?: string;

  @IsOptional()
  @IsString()
  cityId?: string;
}
