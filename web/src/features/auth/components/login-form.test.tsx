import { screen } from '@testing-library/react'
import { beforeEach, describe, expect, it, vi } from 'vitest'
import { ApiError } from '@/app/api'
import { renderWithProviders } from '@/test/render'
import * as authApi from '../api/auth.api'
import { useSessionStore } from '../model/session.store'
import type { SessionUser } from '../model/user'
import { LoginForm } from './login-form'

vi.mock('../api/auth.api', async () => {
  const { useMutation } = await import('@tanstack/react-query')
  const requestOtp = vi.fn()
  const verifyOtp = vi.fn()
  return {
    requestOtp,
    verifyOtp,
    logout: vi.fn().mockResolvedValue(undefined),
    useRequestOtp: () => useMutation({ mutationFn: (phone: string) => requestOtp(phone) }),
    useVerifyOtp: () =>
      useMutation({
        mutationFn: ({ phone, code }: { phone: string; code: string }) => verifyOtp(phone, code),
      }),
  }
})

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
  useSessionStore.setState({
    status: 'anonymous',
    accessToken: null,
    refreshToken: null,
    user: null,
  })
  vi.mocked(authApi.requestOtp).mockResolvedValue({
    phone: '987654321',
    resendAfterSeconds: 30,
    codeLength: 6,
  })
})

async function goToCodeStep(user: ReturnType<typeof renderWithProviders>['user']) {
  await user.type(screen.getByLabelText('Celular'), '987 654 321')
  await user.click(screen.getByRole('button', { name: 'Enviar código' }))
  return screen.findByLabelText('Código de 6 dígitos')
}

describe('LoginForm', () => {
  it('valida el celular antes de pedir el código', async () => {
    const { user } = renderWithProviders(<LoginForm onAuthenticated={vi.fn()} />)

    await user.type(screen.getByLabelText('Celular'), '12345')
    await user.click(screen.getByRole('button', { name: 'Enviar código' }))

    expect(await screen.findByRole('alert')).toHaveTextContent('9 dígitos')
    expect(authApi.requestOtp).not.toHaveBeenCalled()
  })

  it('ingresa a un admin con el código correcto', async () => {
    vi.mocked(authApi.verifyOtp).mockResolvedValue({
      status: 'AUTHENTICATED',
      accessToken: 'a',
      refreshToken: 'r',
      user: user(['CUSTOMER', 'ADMIN']),
    })
    const onAuthenticated = vi.fn()
    const view = renderWithProviders(<LoginForm onAuthenticated={onAuthenticated} />)

    await view.user.type(await goToCodeStep(view.user), '123456')
    await view.user.click(screen.getByRole('button', { name: 'Ingresar' }))

    expect(authApi.requestOtp).toHaveBeenCalledWith('987654321')
    expect(onAuthenticated).toHaveBeenCalledWith(expect.objectContaining({ id: 'u1' }))
    expect(useSessionStore.getState().status).toBe('authenticated')
    expect(screen.getByText(/Reenviar en \d+ s/)).toBeInTheDocument()
  })

  it('un cliente sin rol de socio ve el aviso y no queda con sesión', async () => {
    vi.mocked(authApi.verifyOtp).mockResolvedValue({
      status: 'AUTHENTICATED',
      accessToken: 'a',
      refreshToken: 'r',
      user: user(['CUSTOMER']),
    })
    const onAuthenticated = vi.fn()
    const view = renderWithProviders(<LoginForm onAuthenticated={onAuthenticated} />)

    await view.user.type(await goToCodeStep(view.user), '123456')
    await view.user.click(screen.getByRole('button', { name: 'Ingresar' }))

    expect(await screen.findByText('Aún no eres socio de Apamuy')).toBeInTheDocument()
    expect(onAuthenticated).not.toHaveBeenCalled()
    expect(useSessionStore.getState().user).toBeNull()
  })

  it('muestra el mensaje del backend cuando el código es incorrecto', async () => {
    vi.mocked(authApi.verifyOtp).mockRejectedValue(
      new ApiError(400, 'OTP_INVALID', 'El código no es correcto. Te quedan 2 intentos.'),
    )
    const view = renderWithProviders(<LoginForm onAuthenticated={vi.fn()} />)

    await view.user.type(await goToCodeStep(view.user), '000000')
    await view.user.click(screen.getByRole('button', { name: 'Ingresar' }))

    expect(await screen.findByRole('alert')).toHaveTextContent('Te quedan 2 intentos')
  })
})
