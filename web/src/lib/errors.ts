import { ApiError } from '@/app/api'

export function errorMessage(error: unknown, fallback = 'Algo salió mal. Inténtalo de nuevo.') {
  return error instanceof ApiError ? error.message : fallback
}

export type ErrorKind = 'network' | 'server' | 'forbidden' | 'notFound' | 'request' | 'unknown'

export interface ErrorDescription {
  kind: ErrorKind
  title: string
  description?: string
  /** Para que soporte encuentre el error en los logs del backend. */
  requestId?: string
  status?: number
  retriable: boolean
}

export function describeError(error: unknown): ErrorDescription {
  if (!(error instanceof ApiError)) {
    return {
      kind: 'unknown',
      title: 'Algo salió mal',
      description: 'Inténtalo de nuevo. Si sigue pasando, recarga la página.',
      retriable: true,
    }
  }
  const { status, requestId } = error
  if (status === 0) {
    if (error.code === 'NETWORK_ERROR') {
      return {
        kind: 'network',
        title: 'Sin conexión con Apamuy',
        description: 'Revisa tu internet. Cuando vuelva la conexión, reintenta.',
        retriable: true,
      }
    }
    if (error.code === 'TIMEOUT') {
      return {
        kind: 'network',
        title: 'La respuesta está tardando',
        description: error.message,
        retriable: true,
      }
    }
    return {
      kind: 'unknown',
      title: 'Algo salió mal',
      description: 'Inténtalo de nuevo. Si sigue pasando, recarga la página.',
      retriable: true,
    }
  }
  // El mensaje de un 5xx es técnico; al usuario solo le sirve saber que no fue su culpa.
  if (status >= 500) {
    return {
      kind: 'server',
      title: 'Tuvimos un problema de nuestro lado',
      description:
        'No es nada que hayas hecho. Inténtalo de nuevo en unos segundos; si sigue fallando, comparte el código de abajo con soporte.',
      requestId,
      status,
      retriable: true,
    }
  }
  if (error.isUnauthorized) {
    return {
      kind: 'forbidden',
      title: 'No tienes acceso a esto',
      description: error.message,
      requestId,
      status,
      retriable: false,
    }
  }
  if (status === 404) {
    return {
      kind: 'notFound',
      title: 'No encontramos lo que buscas',
      description: error.message,
      requestId,
      status,
      retriable: false,
    }
  }
  return { kind: 'request', title: error.message, requestId, status, retriable: false }
}
