import { Type } from 'class-transformer';
import { IsLatitude, IsLongitude, ValidateIf } from 'class-validator';
import type { GeoPoint } from '../utils/geo';

/**
 * Ubicación de entrega opcional (`?lat=&lng=`). Si falta, se usa el centro de
 * la ciudad. Si viene una coordenada, la otra es obligatoria.
 */
export class LocationQueryDto {
  @ValidateIf((q: LocationQueryDto) => q.lat !== undefined || q.lng !== undefined)
  @Type(() => Number)
  @IsLatitude({ message: 'Latitud inválida.' })
  lat?: number;

  @ValidateIf((q: LocationQueryDto) => q.lat !== undefined || q.lng !== undefined)
  @Type(() => Number)
  @IsLongitude({ message: 'Longitud inválida.' })
  lng?: number;
}

export function pointOf(query: LocationQueryDto): GeoPoint | undefined {
  return query.lat !== undefined && query.lng !== undefined ? { lat: query.lat, lng: query.lng } : undefined;
}
