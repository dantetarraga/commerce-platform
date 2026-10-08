import { beforeEach, describe, expect, it, vi } from 'vitest'
import { ApiError } from '@/app/api'
import * as authApi from '../api/auth.api'
import { refreshAccessToken, restoreSession, signIn } from './session'
import { useSessionStore } from './session.store'
import type { SessionUser } from './user'

vi.mock('../api/auth.api', () => ({
  refreshTokens: vi.fn(),
  fetchMe: vi.fn(),
  logout: vi.fn().mockResolvedValue(undefined),
}))

const user = (roles: SessionUser['roles']): SessionUser => ({
  id: 'u1',
  phone: '987654321',
  firstName: 'Rosa',
  lastName: 'Quispe',
  email: null,
  avatarUrl: null,
  roles,
})

beforeEach(() => {
  vi.clearAllMocks()
  useSessionStore.setState({ status: 'unknown', accessToken: null, refreshToken: null, user: null })
})

describe('session', () => {
  it('comparte una sola renovación entre llamadas simultáneas', async () => {
    useSessionStore.setState({ refreshToken: 'r1' })
    vi.mocked(authApi.refreshTokens).mockResolvedValue({ accessToken: 'a2', refreshToken: 'r2' })

    const tokens = await Promise.all([
      refreshAccessToken(),
      refreshAccessToken(),
      refreshAccessToken(),
    ])

    expect(tokens).toEqual(['a2', 'a2', 'a2'])
    expect(authApi.refreshTokens).toHaveBeenCalledOnce()
    expect(useSessionStore.getState().refreshToken).toBe('r2')
  })

  it('restaura la sesión guardada de un admin', async () => {
    useSessionStore.setState({ refreshToken: 'r1' })
    vi.mocked(authApi.refreshTokens).mockResolvedValue({ accessToken: 'a2', refreshToken: 'r2' })
    vi.mocked(authApi.fetchMe).mockResolvedValue(user(['ADMIN']))

    await restoreSession()

    expect(useSessionStore.getState()).toMatchObject({ status: 'authenticated', accessToken: 'a2' })
  })

  it('un refresh token rechazado deja la sesión anónima', async () => {
    useSessionStore.setState({ refreshToken: 'r1' })
    vi.mocked(authApi.refreshTokens).mockRejectedValue(
      new ApiError(401, 'INVALID_REFRESH_TOKEN', 'x'),
    )

    await restoreSession()

    expect(useSessionStore.getState()).toMatchObject({ status: 'anonymous', refreshToken: null })
  })

  it('sin conexión no borra la sesión y se puede reintentar', async () => {
    useSessionStore.setState({ refreshToken: 'r1' })
    vi.mocked(authApi.refreshTokens).mockRejectedValue(new ApiError(0, 'NETWORK_ERROR', 'x'))

    await expect(restoreSession()).rejects.toMatchObject({ code: 'NETWORK_ERROR' })
    expect(useSessionStore.getState()).toMatchObject({ status: 'unknown', refreshToken: 'r1' })
  })

  it('un cliente sin rol de panel no queda con sesión', () => {
    const ok = signIn({ accessToken: 'a', refreshToken: 'r', user: user(['CUSTOMER']) })

    expect(ok).toBe(false)
    expect(useSessionStore.getState()).toMatchObject({ status: 'anonymous', refreshToken: null })
    expect(authApi.logout).toHaveBeenCalledWith('r')
  })
})
