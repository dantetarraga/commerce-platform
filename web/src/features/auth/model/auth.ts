import type { SessionUser } from './user'

/** El refresh token viaja en una cookie httpOnly: el panel no lo ve. */
export interface SessionTokens {
  accessToken: string
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
