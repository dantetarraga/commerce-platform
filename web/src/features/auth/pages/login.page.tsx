import { useNavigate, useRouter, useSearch } from '@tanstack/react-router'
import { LoginForm } from '../components/login-form'
import { panelHomeFor, type SessionUser } from '../model/user'

export function LoginPage() {
  const navigate = useNavigate()
  const router = useRouter()
  const { redirect } = useSearch({ strict: false }) as { redirect?: string }

  function goHome(user: SessionUser) {
    if (redirect) return router.history.push(redirect)
    const home = panelHomeFor(user)
    if (home) void navigate({ to: home })
  }

  return (
    <div className='space-y-8'>
      <div className='space-y-2'>
        <h1 className='text-3xl font-semibold'>Ingresa al panel</h1>
        <p className='text-muted-foreground'>Con el celular que registraste en Apamuy.</p>
      </div>
      <LoginForm onAuthenticated={goHome} />
    </div>
  )
}
