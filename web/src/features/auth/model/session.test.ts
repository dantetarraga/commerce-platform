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
  localStorage.clear()
  sessionStore.setState({
    status: 'unknown',
    accessToken: null,
    user: null,
    hasSession: false,
    legacyRefreshToken: null,
  })
})

describe('session', () => {
  it('comparte una sola renovación entre llamadas simultáneas', async () => {
    sessionStore.setState({ hasSession: true })
    vi.mocked(authApi.refreshTokens).mockResolvedValue({ accessToken: 'a2' })

    const tokens = await Promise.all([
      refreshAccessToken(),
      refreshAccessToken(),
      refreshAccessToken(),
    ])

    expect(tokens).toEqual(['a2', 'a2', 'a2'])
    expect(authApi.refreshTokens).toHaveBeenCalledOnce()
    // El refresh token va en la cookie: el panel no lo manda.
    expect(authApi.refreshTokens).toHaveBeenCalledWith(undefined)
  })

  it('restaura la sesión guardada de un admin', async () => {
    sessionStore.setState({ hasSession: true })
    vi.mocked(authApi.refreshTokens).mockResolvedValue({ accessToken: 'a2' })
    vi.mocked(authApi.fetchMe).mockResolvedValue(user(['ADMIN']))

    await restoreSession()

    expect(sessionStore.getState()).toMatchObject({ status: 'authenticated', accessToken: 'a2' })
  })

  it('sin sesión guardada no llama a la API', async () => {
    await restoreSession()

    expect(authApi.refreshTokens).not.toHaveBeenCalled()
    expect(sessionStore.getState().status).toBe('anonymous')
  })

  it('canjea una sola vez el refresh token que guardaba la versión anterior', async () => {
    localStorage.setItem(
      SESSION_STORAGE_KEY,
      JSON.stringify({ state: { refreshToken: 'viejo' }, version: 1 }),
    )
    await sessionStore.persist.rehydrate()
    vi.mocked(authApi.refreshTokens).mockResolvedValue({ accessToken: 'a2' })

    await refreshAccessToken()

    expect(authApi.refreshTokens).toHaveBeenCalledWith('viejo')
    expect(sessionStore.getState()).toMatchObject({ hasSession: true, legacyRefreshToken: null })
    expect(localStorage.getItem(SESSION_STORAGE_KEY)).not.toContain('viejo')
  })

  it('una sesión rechazada deja la sesión anónima', async () => {
    sessionStore.setState({ hasSession: true })
    vi.mocked(authApi.refreshTokens).mockRejectedValue(
      new ApiError(401, 'INVALID_REFRESH_TOKEN', 'x'),
    )

    await restoreSession()

    expect(sessionStore.getState()).toMatchObject({ status: 'anonymous', hasSession: false })
  })

  it('sin conexión no borra la sesión y se puede reintentar', async () => {
    sessionStore.setState({ hasSession: true })
    vi.mocked(authApi.refreshTokens).mockRejectedValue(new ApiError(0, 'NETWORK_ERROR', 'x'))

    await expect(restoreSession()).rejects.toMatchObject({ code: 'NETWORK_ERROR' })
    expect(sessionStore.getState()).toMatchObject({ status: 'unknown', hasSession: true })
  })

  it('un cliente sin rol de panel no queda con sesión', () => {
    const ok = signIn({ accessToken: 'a', user: user(['CUSTOMER']) })

    expect(ok).toBe(false)
    expect(sessionStore.getState()).toMatchObject({ status: 'anonymous', hasSession: false })
    expect(authApi.logout).toHaveBeenCalledWith(undefined)
  })

  it('si otra pestaña cierra sesión, esta también', async () => {
    sessionStore.setState({
      status: 'authenticated',
      accessToken: 'a1',
      hasSession: true,
      user: user(['ADMIN']),
    })
    const stop = syncSessionAcrossTabs()
    localStorage.setItem(
      SESSION_STORAGE_KEY,
      JSON.stringify({ state: { hasSession: false, legacyRefreshToken: null }, version: 2 }),
    )

    window.dispatchEvent(new StorageEvent('storage', { key: SESSION_STORAGE_KEY }))

    await vi.waitFor(() => expect(sessionStore.getState().status).toBe('anonymous'))
    expect(sessionStore.getState().accessToken).toBeNull()
    stop()
  })
})
