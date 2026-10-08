import axios, { type AxiosRequestConfig } from 'axios'
import { env } from '@/config/env'
import type { ApiError } from './api-error'

export const http = axios.create({
  baseURL: env.apiUrl,
  timeout: 15_000,
  headers: { 'Content-Type': 'application/json' },
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
