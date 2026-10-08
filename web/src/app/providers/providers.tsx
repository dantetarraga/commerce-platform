import { QueryClientProvider } from '@tanstack/react-query'
import { ReactQueryDevtools } from '@tanstack/react-query-devtools'
import { RouterProvider } from '@tanstack/react-router'
import { Toaster } from 'sonner'
import { useSystemTheme } from '@/hooks/use-system-theme'
import { createAppRouter } from '../router/router'
import { setupHttp } from './http-setup'
import { createQueryClient } from './query-client'

const queryClient = createQueryClient()
const router = createAppRouter(queryClient)
setupHttp(queryClient, router)

export function AppProviders() {
  useSystemTheme()

  return (
    <QueryClientProvider client={queryClient}>
      <RouterProvider router={router} />
      <Toaster position='top-right' richColors closeButton />
      {import.meta.env.DEV && <ReactQueryDevtools buttonPosition='bottom-left' />}
    </QueryClientProvider>
  )
}
