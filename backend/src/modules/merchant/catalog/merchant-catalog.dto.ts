import { PickType } from '@nestjs/swagger';
import { UpdateStoreDto } from '../../admin/catalog/store.dto';

/**
 * Lo que el dueño cambia de su negocio. Nombre, dirección, ciudad, categorías y
 * publicación los decide el equipo Apamuy.
 */
export class MerchantStoreProfileDto extends PickType(UpdateStoreDto, [
  'description',
  'phone',
  'logoUrl',
  'coverUrl',
  'avgPrepMinutes',
  'minOrderAmount',
] as const) {}
