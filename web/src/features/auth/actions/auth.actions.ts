import { http } from '@/app/api'
import type { OtpRequested, SessionTokens, VerifyOtpResponse } from '../model/auth'
import type { SessionUser } from '../model/user'

// Escrito a mano hasta generar el cliente con orval (pnpm run api:generate).

export async function requestOtp(phone: string) {
  return (await http.post<OtpRequested>('/auth/otp/request', { phone })).data
}

export async function verifyOtp(phone: string, code: string) {
  return (await http.post<VerifyOtpResponse>('/auth/otp/verify', { phone, code })).data
}

/** [legacyToken]: el que guardaba una versión anterior en localStorage; se manda una sola vez. */
export async function refreshTokens(legacyToken?: string) {
  const body = legacyToken ? { refreshToken: legacyToken } : {}
  return (await http.post<SessionTokens>('/auth/refresh', body)).data
}

export async function fetchMe() {
  return (await http.get<SessionUser>('/users/me')).data
}

export async function logout(legacyToken?: string) {
  await http.post('/auth/logout', legacyToken ? { refreshToken: legacyToken } : {})
}
