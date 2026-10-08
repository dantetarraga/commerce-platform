import { getRouteApi, Link, useNavigate, useRouter } from '@tanstack/react-router'
import { LoginForm } from '../components/login-form'
import { panelHomeFor, type SessionUser } from '../model/user'

const loginRouteApi = getRouteApi('/auth/login')

export function LoginPage() {
  const navigate = useNavigate()
  const router = useRouter()
  const { redirect } = loginRouteApi.useSearch()

  function goHome(user: SessionUser) {
    if (redirect) return router.history.push(redirect)
    const home = panelHomeFor(user)
    if (home) void navigate({ to: home })
  }

  return (
    <div className='space-y-8'>
      <div className='space-y-2'>
        <h1 className='text-4xl font-bold'>Ingresa a Apamuy</h1>
        <p className='text-muted-foreground'>
          Negocios, repartidores y equipo Apamuy: escribe el celular con el que te registraste y te
          enviamos un código por SMS.
        </p>
      </div>
      <LoginForm onAuthenticated={goHome} />
      <p className='text-muted-foreground border-t pt-6 text-sm'>
        ¿Quieres vender con Apamuy?{' '}
        <Link to='/' hash='negocios' className='text-primary font-semibold hover:underline'>
          Mira cómo sumar tu negocio
        </Link>
      </p>
    </div>
  )
}
