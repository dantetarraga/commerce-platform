import { ApiError } from '@/app/api'

export function errorMessage(error: unknown, fallback = 'Algo salió mal. Inténtalo de nuevo.') {
  return error instanceof ApiError ? error.message : fallback
}
