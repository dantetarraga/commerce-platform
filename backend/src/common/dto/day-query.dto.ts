import { IsISO8601, IsOptional, Matches } from 'class-validator';

/** `?date=YYYY-MM-DD`: un día en hora de Lima. Sin `date`, hoy. */
export class DayQueryDto {
  @IsOptional()
  @Matches(/^\d{4}-\d{2}-\d{2}$/, { message: 'La fecha va como AAAA-MM-DD.' })
  @IsISO8601({ strict: true }, { message: 'Esa fecha no existe.' })
  date?: string;
}
