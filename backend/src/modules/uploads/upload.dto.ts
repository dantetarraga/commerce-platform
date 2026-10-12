import { IsIn, IsInt, IsString, Max, Min, ValidateIf } from 'class-validator';
import { IMAGE_PURPOSES, IMAGE_TYPES, isStoreImage, MAX_IMAGE_BYTES } from './image-keys';
import type { ImageContentType, ImagePurpose } from './image-keys';

export class ImageUploadDto {
  /** Dónde se va a usar la foto: decide la carpeta y quién puede subirla. */
  @IsIn(IMAGE_PURPOSES)
  purpose!: ImagePurpose;

  /** Requerido para las fotos de un negocio (producto, logo, portada). */
  @ValidateIf((dto: ImageUploadDto) => isStoreImage(dto.purpose))
  @IsString({ message: 'Indica el negocio de la foto.' })
  storeId?: string;

  @IsIn(Object.keys(IMAGE_TYPES), { message: 'La foto debe ser JPG, PNG o WebP.' })
  contentType!: ImageContentType;

  /** Bytes exactos del archivo: van firmados en la URL. */
  @IsInt()
  @Min(1)
  @Max(MAX_IMAGE_BYTES, { message: 'La foto pesa más de 5 MB.' })
  size!: number;
}
