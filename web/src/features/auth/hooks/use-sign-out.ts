import { useQueryClient } from '@tanstack/react-query'
import { useNavigate } from '@tanstack/react-router'
import { useCallback } from 'react'
import { signOut } from '../model/session'

export function useSignOut() {
  const queryClient = useQueryClient()
  const navigate = useNavigate()

  return useCallback(() => {
    signOut()
    queryClient.clear()
    void navigate({ to: '/ingresar' })
  }, [queryClient, navigate])
}
