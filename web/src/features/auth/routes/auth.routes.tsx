import { LoginPage } from '../pages/login.page'
import { loginSearchSchema } from '../schemas/auth.schemas'

export const loginRoute = {
  path: '/login',
  component: LoginPage,
  validateSearch: loginSearchSchema,
} as const
