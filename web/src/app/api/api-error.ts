import axios from 'axios'

export class ApiError extends Error {
  readonly status: number
  readonly code: string
  readonly details?: Record<string, unknown>
  readonly requestId?: string

  constructor(
    status: number,
    code: string,
    message: string,
    details?: Record<string, unknown>,
    requestId?: string,
  ) {
    super(message)
    this.name = 'ApiError'
    this.status = status
    this.code = code
    this.details = details
    this.requestId = requestId
  }

  get isUnauthorized() {
    return this.status === 401 || this.status === 403
  }

  get isRetriable() {
    return (this.status === 0 && this.code !== 'CANCELED') || this.status >= 500
  }
}

interface ApiErrorBody {
  code?: string
  message?: string
  details?: Record<string, unknown>
  requestId?: string
}

const NETWORK_MESSAGE =
  'No pudimos conectarnos con Apamuy. Revisa tu internet e inténtalo de nuevo.'
const TIMEOUT_MESSAGE = 'Apamuy está tardando en responder. Inténtalo de nuevo en un momento.'
const UNKNOWN_MESSAGE = 'Algo salió mal. Inténtalo de nuevo.'

export function toApiError(error: unknown): ApiError {
  if (error instanceof ApiError) return error
  if (!axios.isAxiosError<ApiErrorBody>(error)) {
    return new ApiError(0, 'UNKNOWN_ERROR', UNKNOWN_MESSAGE)
  }
  if (axios.isCancel(error)) return new ApiError(0, 'CANCELED', 'La solicitud se canceló.')
  if (!error.response) {
    return error.code === 'ECONNABORTED' || error.code === 'ETIMEDOUT'
      ? new ApiError(0, 'TIMEOUT', TIMEOUT_MESSAGE)
      : new ApiError(0, 'NETWORK_ERROR', NETWORK_MESSAGE)
  }

  const { status, data } = error.response
  return new ApiError(
    status,
    data?.code ?? 'UNKNOWN_ERROR',
    data?.message ?? UNKNOWN_MESSAGE,
    data?.details,
    data?.requestId,
  )
}
