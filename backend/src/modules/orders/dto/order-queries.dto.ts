import { Transform } from 'class-transformer';
import { IsInt, IsOptional, IsString, Max, MaxLength, Min } from 'class-validator';

export class RateOrderDto {
  @IsInt()
  @Min(1, { message: 'Elige de 1 a 5 estrellas.' })
  @Max(5, { message: 'Elige de 1 a 5 estrellas.' })
  rating!: number;

  @IsOptional()
  @Transform(({ value }: { value: unknown }) => (typeof value === 'string' ? value.trim() : value))
  @IsString()
  @MaxLength(500)
  comment?: string | null;
}
