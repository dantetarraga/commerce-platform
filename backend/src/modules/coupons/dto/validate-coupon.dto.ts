import { Type } from 'class-transformer';
import { IsString, Length, ValidateNested } from 'class-validator';
import { LocationQueryDto } from '../../../common/dto/location-query.dto';
import { MoneyDto } from '../../../common/dto/money.dto';

export class ValidateCouponDto extends LocationQueryDto {
  @IsString()
  @Length(2, 40, { message: 'Escribe el código del cupón.' })
  code!: string;

  @IsString()
  storeId!: string;

  /** Subtotal de productos de la bolsa. */
  @ValidateNested()
  @Type(() => MoneyDto)
  subtotal!: MoneyDto;
}
