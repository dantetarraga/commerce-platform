import { IsNumber, Max, Min } from 'class-validator';

export class CourierLocationDto {
  @IsNumber({}, { message: 'La latitud debe ser un número.' })
  @Min(-90, { message: 'La latitud está fuera de rango.' })
  @Max(90, { message: 'La latitud está fuera de rango.' })
  lat!: number;

  @IsNumber({}, { message: 'La longitud debe ser un número.' })
  @Min(-180, { message: 'La longitud está fuera de rango.' })
  @Max(180, { message: 'La longitud está fuera de rango.' })
  lng!: number;
}
