import axios, { type AxiosRequestConfig } from 'axios'
import { env } from '@/app/config/env'
import type { ApiError } from './api-error'

// X-Apamuy-Client: la API guarda el refresh token en una cookie httpOnly en vez
// de devolverlo; withCredentials la manda a /auth (en otro origen también).
export const http = axios.create({
  baseURL: env.apiUrl,
  timeout: 15_000,
  withCredentials: true,
  headers: { 'Content-Type': 'application/json', 'X-Apamuy-Client': 'web' },
})

// Usado por el cliente generado con orval (api/generated).
export function apiMutator<T>(
  config: AxiosRequestConfig,
  options?: AxiosRequestConfig,
): Promise<T> {
  return http.request<T>({ ...config, ...options }).then(({ data }) => data)
}

export type ErrorType<_Error> = ApiError
export type BodyType<Body> = Body
