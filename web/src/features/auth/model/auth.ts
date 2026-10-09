import type { SessionUser } from './user'

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
