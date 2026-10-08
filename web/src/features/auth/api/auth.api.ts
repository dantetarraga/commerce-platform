import { useMutation } from '@tanstack/react-query'
import { http } from '@/api'
import type { SessionUser } from '../model/user'

// Escrito a mano hasta generar el cliente con orval (npm run api:generate).

export interface SessionTokens {
  accessToken: string
  refreshToken: string
}

export interface OtpRequested {
  phone: string
  resendAfterSeconds: number
  codeLength: number
}

export type AuthResponse = SessionTokens & { user: SessionUser }

export type VerifyOtpResponse =
  | ({ status: 'AUTHENTICATED' } & AuthResponse)
  | { status: 'PROFILE_REQUIRED'; registrationToken: string }

export async function requestOtp(phone: string) {
  const { data } = await http.post<OtpRequested>('/auth/otp/request', { phone })
  return data
}

export async function verifyOtp(phone: string, code: string) {
  const { data } = await http.post<VerifyOtpResponse>('/auth/otp/verify', { phone, code })
  return data
}

export async function refreshTokens(refreshToken: string) {
  const { data } = await http.post<SessionTokens>('/auth/refresh', { refreshToken })
  return data
}

export async function fetchMe() {
  const { data } = await http.get<SessionUser>('/users/me')
  return data
}

export async function logout(refreshToken: string) {
  await http.post('/auth/logout', { refreshToken })
}

export function useRequestOtp() {
  return useMutation({ mutationFn: (phone: string) => requestOtp(phone) })
}

export function useVerifyOtp() {
  return useMutation({
    mutationFn: ({ phone, code }: { phone: string; code: string }) => verifyOtp(phone, code),
  })
}
