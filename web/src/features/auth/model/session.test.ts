import { beforeEach, describe, expect, it, vi } from 'vitest'
import { ApiError } from '@/app/api'
import * as authApi from '../actions/auth.actions'
import { refreshAccessToken, restoreSession, signIn } from './session'
import { SESSION_STORAGE_KEY, sessionStore, syncSessionAcrossTabs } from '../stores/session.store'
import type { SessionUser } from './user'

vi.mock('../actions/auth.actions', () => ({
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
  sessionStore.setState({ status: 'unknown', accessToken: null, refreshToken: null, user: null })
})

describe('session', () => {
  it('comparte una sola renovación entre llamadas simultáneas', async () => {
    sessionStore.setState({ refreshToken: 'r1' })
    vi.mocked(authApi.refreshTokens).mockResolvedValue({ accessToken: 'a2', refreshToken: 'r2' })

    const tokens = await Promise.all([
      refreshAccessToken(),
      refreshAccessToken(),
      refreshAccessToken(),
    ])

    expect(tokens).toEqual(['a2', 'a2', 'a2'])
    expect(authApi.refreshTokens).toHaveBeenCalledOnce()
    expect(sessionStore.getState().refreshToken).toBe('r2')
  })

  it('restaura la sesión guardada de un admin', async () => {
    sessionStore.setState({ refreshToken: 'r1' })
    vi.mocked(authApi.refreshTokens).mockResolvedValue({ accessToken: 'a2', refreshToken: 'r2' })
    vi.mocked(authApi.fetchMe).mockResolvedValue(user(['ADMIN']))

    await restoreSession()

    expect(sessionStore.getState()).toMatchObject({ status: 'authenticated', accessToken: 'a2' })
  })

  it('un refresh token rechazado deja la sesión anónima', async () => {
    sessionStore.setState({ refreshToken: 'r1' })
    vi.mocked(authApi.refreshTokens).mockRejectedValue(
      new ApiError(401, 'INVALID_REFRESH_TOKEN', 'x'),
    )

    await restoreSession()

    expect(sessionStore.getState()).toMatchObject({ status: 'anonymous', refreshToken: null })
  })

  it('sin conexión no borra la sesión y se puede reintentar', async () => {
    sessionStore.setState({ refreshToken: 'r1' })
    vi.mocked(authApi.refreshTokens).mockRejectedValue(new ApiError(0, 'NETWORK_ERROR', 'x'))

    await expect(restoreSession()).rejects.toMatchObject({ code: 'NETWORK_ERROR' })
    expect(sessionStore.getState()).toMatchObject({ status: 'unknown', refreshToken: 'r1' })
  })

  it('un cliente sin rol de panel no queda con sesión', () => {
    const ok = signIn({ accessToken: 'a', refreshToken: 'r', user: user(['CUSTOMER']) })

    expect(ok).toBe(false)
    expect(sessionStore.getState()).toMatchObject({ status: 'anonymous', refreshToken: null })
    expect(authApi.logout).toHaveBeenCalledWith('r')
  })

  it('renueva con el refresh token que guardó otra pestaña', async () => {
    sessionStore.setState({ refreshToken: 'r1' })
    localStorage.setItem(
      SESSION_STORAGE_KEY,
      JSON.stringify({ state: { refreshToken: 'r9' }, version: 1 }),
    )
    vi.mocked(authApi.refreshTokens).mockResolvedValue({ accessToken: 'a2', refreshToken: 'r10' })

    await refreshAccessToken()

    expect(authApi.refreshTokens).toHaveBeenCalledWith('r9')
  })

  it('si otra pestaña cierra sesión, esta también', async () => {
    sessionStore.setState({
      status: 'authenticated',
      accessToken: 'a1',
      refreshToken: 'r1',
      user: user(['ADMIN']),
    })
    const stop = syncSessionAcrossTabs()
    localStorage.setItem(
      SESSION_STORAGE_KEY,
      JSON.stringify({ state: { refreshToken: null }, version: 1 }),
    )

    window.dispatchEvent(new StorageEvent('storage', { key: SESSION_STORAGE_KEY }))

    await vi.waitFor(() => expect(sessionStore.getState().status).toBe('anonymous'))
    expect(sessionStore.getState().accessToken).toBeNull()
    stop()
  })
})
