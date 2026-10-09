import { IsOptional, IsString, Matches } from 'class-validator';

const DATE = /^\d{4}-\d{2}-\d{2}$/;
const DATE_MESSAGE = 'La fecha va como AAAA-MM-DD.';

export class AnalyticsQueryDto {
  /** Primer día, en hora de la ciudad. */
  @Matches(DATE, { message: DATE_MESSAGE })
  from!: string;

  /** Último día, incluido. Máximo 92 días desde `from`. */
  @Matches(DATE, { message: DATE_MESSAGE })
  to!: string;

  /** Sin ciudad, todas. */
  @IsOptional()
  @IsString()
  cityId?: string;
}
