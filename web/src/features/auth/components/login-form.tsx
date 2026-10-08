import { useState } from 'react'
import { useCountdown } from '@/hooks/use-countdown'
import { useRequestOtp, useVerifyOtp } from '../api/auth.api'
import { signIn } from '../model/session'
import type { SessionUser } from '../model/user'
import { CodeStep } from './code-step'
import { NotPartnerNotice } from './not-partner-notice'
import { PhoneStep } from './phone-step'

type Step =
  { name: 'phone' } | { name: 'code'; phone: string } | { name: 'not-partner'; isCourier: boolean }

interface LoginFormProps {
  onAuthenticated: (user: SessionUser) => void
}

export function LoginForm({ onAuthenticated }: LoginFormProps) {
  const [step, setStep] = useState<Step>({ name: 'phone' })
  const resend = useCountdown()
  const requestOtp = useRequestOtp()
  const verifyOtp = useVerifyOtp()

  async function sendCode(phone: string) {
    const result = await requestOtp.mutateAsync(phone)
    resend.start(result.resendAfterSeconds)
    setStep({ name: 'code', phone: result.phone })
  }

  async function verifyCode(phone: string, code: string) {
    const result = await verifyOtp.mutateAsync({ phone, code })
    if (result.status === 'AUTHENTICATED' && signIn(result)) return onAuthenticated(result.user)
    const isCourier = result.status === 'AUTHENTICATED' && result.user.roles.includes('COURIER')
    setStep({ name: 'not-partner', isCourier })
  }

  function handleResend(phone: string) {
    sendCode(phone).catch(() => undefined)
  }

  switch (step.name) {
    case 'phone':
      return <PhoneStep onSubmit={sendCode} />
    case 'code':
      return (
        <CodeStep
          phone={step.phone}
          resendIn={resend.seconds}
          isResending={requestOtp.isPending}
          onSubmit={(code) => verifyCode(step.phone, code)}
          onResend={() => handleResend(step.phone)}
          onBack={() => setStep({ name: 'phone' })}
        />
      )
    case 'not-partner':
      return (
        <NotPartnerNotice isCourier={step.isCourier} onRetry={() => setStep({ name: 'phone' })} />
      )
  }
}
