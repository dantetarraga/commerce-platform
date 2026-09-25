import { Transform } from 'class-transformer';
import { IsString, Length } from 'class-validator';
import { LocationQueryDto } from '../../../common/dto/location-query.dto';

export class SearchQueryDto extends LocationQueryDto {
  @Transform(({ value }: { value: unknown }) => (typeof value === 'string' ? value.trim() : value))
  @IsString()
  @Length(2, 80, { message: 'Escribe al menos 2 letras.' })
  q!: string;
}
