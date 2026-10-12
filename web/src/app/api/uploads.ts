import axios from 'axios'
import { http } from './http'
import { toApiError } from './api-error'

export type ImagePurpose = 'product' | 'store-logo' | 'store-cover' | 'promotion' | 'category'

export interface ImageTarget {
  purpose: ImagePurpose
  /** Requerido para producto, logo y portada. */
  storeId?: string
}

interface SignedUpload {
  method: 'PUT'
  uploadUrl: string
  headers: Record<string, string>
  publicUrl: string
}

/**
 * Sube la foto directo al storage con la URL firmada que da el backend y devuelve la URL
 * pública para guardarla. El PUT no usa `http`: el storage no debe recibir el token.
 */
export async function uploadImage(
  image: Blob,
  target: ImageTarget,
  onProgress?: (fraction: number) => void,
): Promise<string> {
  const { data } = await http.post<SignedUpload>('/uploads/images', {
    ...target,
    contentType: image.type,
    size: image.size,
  })
  try {
    await axios.put(data.uploadUrl, image, {
      headers: data.headers,
      timeout: 120_000,
      onUploadProgress: (event) => {
        if (event.total) onProgress?.(event.loaded / event.total)
      },
    })
  } catch (error) {
    throw toApiError(error)
  }
  return data.publicUrl
}
