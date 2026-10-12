/** Formatos que aceptan la app y el panel; el panel ya los convierte a WebP antes de subir. */
export const IMAGE_TYPES = {
  'image/jpeg': 'jpg',
  'image/png': 'png',
  'image/webp': 'webp',
} as const;

export type ImageContentType = keyof typeof IMAGE_TYPES;

export const MAX_IMAGE_BYTES = 5 * 1024 * 1024;

export const IMAGE_PURPOSES = ['product', 'store-logo', 'store-cover', 'promotion', 'category'] as const;
export type ImagePurpose = (typeof IMAGE_PURPOSES)[number];

/** Las fotos de un negocio cuelgan de su carpeta: se pueden listar o borrar juntas. */
export const isStoreImage = (purpose: ImagePurpose) =>
  purpose === 'product' || purpose === 'store-logo' || purpose === 'store-cover';

const folders: Record<ImagePurpose, string> = {
  product: 'products',
  'store-logo': 'logo',
  'store-cover': 'cover',
  promotion: 'promotions',
  category: 'categories',
};

/** Cada subida tiene una key nueva: así la CDN puede guardar la foto en caché para siempre. */
export function imageKey(purpose: ImagePurpose, contentType: ImageContentType, id: string, storeId?: string) {
  const file = `${id}.${IMAGE_TYPES[contentType]}`;
  if (!isStoreImage(purpose)) return `${folders[purpose]}/${file}`;
  if (!storeId) throw new Error(`La foto de tipo ${purpose} necesita el negocio`);
  return `stores/${storeId}/${folders[purpose]}/${file}`;
}
