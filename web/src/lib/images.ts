export const IMAGE_ACCEPT = 'image/jpeg,image/png,image/webp'
export const MAX_SOURCE_BYTES = 15 * 1024 * 1024

const MAX_SIDE = 1600
const QUALITY = 0.85

/** Lado mayor de 1600 px como máximo, conservando la proporción. */
export function fitWithin(width: number, height: number, maxSide = MAX_SIDE) {
  const scale = Math.min(1, maxSide / Math.max(width, height))
  return { width: Math.round(width * scale), height: Math.round(height * scale) }
}

/**
 * Achica la foto y la pasa a WebP antes de subirla: una foto de celular de 4 MB queda en
 * unos 200 KB, que suben rápido con datos móviles. Si el navegador no codifica WebP, JPEG.
 */
export async function prepareImage(file: File): Promise<Blob> {
  const bitmap = await createImageBitmap(file)
  const { width, height } = fitWithin(bitmap.width, bitmap.height)
  const canvas = document.createElement('canvas')
  canvas.width = width
  canvas.height = height
  const context = canvas.getContext('2d')
  if (!context) throw new Error('El navegador no puede procesar la foto.')
  context.drawImage(bitmap, 0, 0, width, height)
  bitmap.close()
  const encode = (type: string) =>
    new Promise<Blob | null>((resolve) => canvas.toBlob(resolve, type, QUALITY))
  const webp = await encode('image/webp')
  if (webp?.type === 'image/webp') return webp
  const jpeg = await encode('image/jpeg')
  if (!jpeg) throw new Error('El navegador no puede procesar la foto.')
  return jpeg
}
