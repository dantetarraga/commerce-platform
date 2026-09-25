import { IsIn, IsInt, Min } from 'class-validator';
import { DEFAULT_CURRENCY } from '../utils/money';

/** `{ amount, currency }` en el body. Por ahora solo soles. */
export class MoneyDto {
  @IsInt({ message: 'El monto debe estar en céntimos.' })
  @Min(0)
  amount!: number;

  @IsIn([DEFAULT_CURRENCY])
  currency!: string;
}
