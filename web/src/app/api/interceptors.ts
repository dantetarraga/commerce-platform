import type { AxiosInstance, InternalAxiosRequestConfig } from 'axios'
import { toApiError } from './api-error'

export interface AuthInterceptorOptions {
  getAccessToken: () => string | null
  canRefresh: () => boolean
  refreshAccessToken: () => Promise<string>
  onAuthFailure: () => void
}

type RetriableConfig = InternalAxiosRequestConfig & { retried?: boolean }

const isAuthEndpoint = (config: InternalAxiosRequestConfig) =>
  config.url?.startsWith('/auth/') ?? false

export function setupAuthInterceptors(instance: AxiosInstance, options: AuthInterceptorOptions) {
  const request = instance.interceptors.request.use((config) => {
    const token = options.getAccessToken()
    if (token) config.headers.Authorization = `Bearer ${token}`
    return config
  })

  const response = instance.interceptors.response.use(undefined, async (error: unknown) => {
    const apiError = toApiError(error)
    const config = (error as { config?: RetriableConfig }).config

    const shouldRefresh =
      apiError.status === 401 &&
      config &&
      !config.retried &&
      !isAuthEndpoint(config) &&
      options.canRefresh()
    if (!shouldRefresh) throw apiError

    config.retried = true
    let token: string
    try {
      token = await options.refreshAccessToken()
    } catch (refreshError) {
      const failure = toApiError(refreshError)
      if (failure.isUnauthorized) options.onAuthFailure()
      throw failure
    }
    config.headers.Authorization = `Bearer ${token}`
    return instance.request(config)
  })

  return () => {
    instance.interceptors.request.eject(request)
    instance.interceptors.response.eject(response)
  }
}
