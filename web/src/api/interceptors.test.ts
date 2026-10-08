import axios, { AxiosError, type AxiosAdapter, type InternalAxiosRequestConfig } from 'axios'
import { describe, expect, it, vi } from 'vitest'
import { ApiError } from './api-error'
import { setupAuthInterceptors } from './interceptors'

type Handler = (config: InternalAxiosRequestConfig) => { status: number; data?: unknown }

function createClient(handler: Handler) {
  const adapter: AxiosAdapter = async (config) => {
    const { status, data } = handler(config)
    const response = { status, data, headers: {}, config, statusText: String(status) }
    if (status >= 400) throw new AxiosError('fail', String(status), config, undefined, response)
    return response
  }
  return axios.create({ adapter })
}

const authorized = (config: InternalAxiosRequestConfig, token: string) =>
  String(config.headers.Authorization) === `Bearer ${token}`

describe('setupAuthInterceptors', () => {
  it('normaliza el formato de error de la API', async () => {
    const client = createClient(() => ({
      status: 409,
      data: { code: 'COURIER_HAS_ACTIVE_ORDER', message: 'Tiene un pedido', requestId: 'r1' },
    }))
    setupAuthInterceptors(client, {
      getAccessToken: () => 'a',
      canRefresh: () => true,
      refreshAccessToken: vi.fn(),
      onAuthFailure: vi.fn(),
    })

    const error = await client.get('/x').catch((e: unknown) => e)

    expect(error).toBeInstanceOf(ApiError)
    expect(error).toMatchObject({ status: 409, code: 'COURIER_HAS_ACTIVE_ORDER', requestId: 'r1' })
  })

  it('ante un 401 renueva el token y reintenta la petición', async () => {
    let token = 'vencido'
    const client = createClient((config) =>
      authorized(config, 'nuevo') ? { status: 200, data: 'ok' } : { status: 401 },
    )
    const refreshAccessToken = vi.fn(async () => {
      token = 'nuevo'
      return token
    })
    setupAuthInterceptors(client, {
      getAccessToken: () => token,
      canRefresh: () => true,
      refreshAccessToken,
      onAuthFailure: vi.fn(),
    })

    const { data } = await client.get('/a')

    expect(data).toBe('ok')
    expect(refreshAccessToken).toHaveBeenCalledOnce()
  })

  it('no intenta renovar en los endpoints de auth', async () => {
    const client = createClient(() => ({
      status: 401,
      data: { code: 'OTP_INVALID', message: 'x' },
    }))
    const refreshAccessToken = vi.fn()
    setupAuthInterceptors(client, {
      getAccessToken: () => null,
      canRefresh: () => true,
      refreshAccessToken,
      onAuthFailure: vi.fn(),
    })

    await expect(client.post('/auth/otp/verify')).rejects.toMatchObject({ code: 'OTP_INVALID' })
    expect(refreshAccessToken).not.toHaveBeenCalled()
  })

  it('si la renovación es rechazada avisa del fallo de sesión', async () => {
    const client = createClient(() => ({ status: 401 }))
    const onAuthFailure = vi.fn()
    setupAuthInterceptors(client, {
      getAccessToken: () => 'vencido',
      canRefresh: () => true,
      refreshAccessToken: () => Promise.reject(new ApiError(401, 'INVALID_REFRESH_TOKEN', 'x')),
      onAuthFailure,
    })

    await expect(client.get('/a')).rejects.toMatchObject({ code: 'INVALID_REFRESH_TOKEN' })
    expect(onAuthFailure).toHaveBeenCalledOnce()
  })

  it('sin conexión devuelve un error de red', async () => {
    const client = createClient(() => {
      throw new AxiosError('Network Error', 'ERR_NETWORK')
    })
    setupAuthInterceptors(client, {
      getAccessToken: () => null,
      canRefresh: () => false,
      refreshAccessToken: vi.fn(),
      onAuthFailure: vi.fn(),
    })

    await expect(client.get('/a')).rejects.toMatchObject({ status: 0, code: 'NETWORK_ERROR' })
  })
})
