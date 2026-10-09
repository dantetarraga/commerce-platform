import { IsOptional, IsString, Matches } from 'class-validator';

const DATE = /^\d{4}-\d{2}-\d{2}$/;
const DATE_MESSAGE = 'La fecha va como AAAA-MM-DD.';

export class MerchantReportQueryDto {
  /** Primer día, en hora de Lima. */
  @Matches(DATE, { message: DATE_MESSAGE })
  from!: string;

  /** Último día, incluido. Máximo 92 días desde `from`. */
  @Matches(DATE, { message: DATE_MESSAGE })
  to!: string;

  /** Uno de sus negocios; sin él, todos. */
  @IsOptional()
  @IsString()
  storeId?: string;
}
