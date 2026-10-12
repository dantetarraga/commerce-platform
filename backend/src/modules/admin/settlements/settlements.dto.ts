import { IsInt, IsISO8601, IsOptional, IsString, Matches, Max, Min, ValidateIf } from 'class-validator';
import { MAX_RATE_BPS } from './commission';

const DATE = /^\d{4}-\d{2}-\d{2}$/;
const RATE_MESSAGE = 'La comisión va de 0 % a 100 %.';

export class CommissionRateDto {
  /** Puntos básicos: 1000 = 10 %. */
  @IsInt({ message: RATE_MESSAGE })
  @Min(0, { message: RATE_MESSAGE })
  @Max(MAX_RATE_BPS, { message: RATE_MESSAGE })
  rateBps!: number;
}

export class StoreCommissionDto {
  /** Puntos básicos; `null` vuelve a la comisión por defecto. */
  @ValidateIf((dto: StoreCommissionDto) => dto.rateBps !== null)
  @IsInt({ message: RATE_MESSAGE })
  @Min(0, { message: RATE_MESSAGE })
  @Max(MAX_RATE_BPS, { message: RATE_MESSAGE })
  rateBps!: number | null;
}

export class SettlementWeekQueryDto {
  /** Cualquier día de la semana (lunes a domingo, hora de Lima); sin él, la semana actual. */
  @IsOptional()
  @Matches(DATE, { message: 'La fecha va como AAAA-MM-DD.' })
  @IsISO8601({ strict: true }, { message: 'Esa fecha no existe.' })
  week?: string;
}

export class AdminSettlementsQueryDto extends SettlementWeekQueryDto {
  @IsOptional()
  @IsString()
  cityId?: string;
}

export class MerchantSettlementsQueryDto extends SettlementWeekQueryDto {
  /** Uno de sus negocios; sin él, todos. */
  @IsOptional()
  @IsString()
  storeId?: string;
}

export class MarkSettlementPaidDto {
  /** Cualquier día de la semana que se paga. */
  @Matches(DATE, { message: 'La fecha va como AAAA-MM-DD.' })
  @IsISO8601({ strict: true }, { message: 'Esa fecha no existe.' })
  week!: string;
}
