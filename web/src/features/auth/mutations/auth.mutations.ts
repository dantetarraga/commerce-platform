import { mutationOptions } from '@tanstack/react-query'
import { requestOtp, verifyOtp } from '../actions/auth.actions'

export const requestOtpMutation = () =>
  mutationOptions({ mutationFn: (phone: string) => requestOtp(phone) })

export const verifyOtpMutation = () =>
  mutationOptions({
    mutationFn: ({ phone, code }: { phone: string; code: string }) => verifyOtp(phone, code),
  })
