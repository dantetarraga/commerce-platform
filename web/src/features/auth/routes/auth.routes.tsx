import { LoginPage } from '../pages/login.page'
import { loginSearchSchema } from '../schemas/auth.schemas'

export const loginRoute = {
  path: '/ingresar',
  component: LoginPage,
  validateSearch: loginSearchSchema,
} as const
