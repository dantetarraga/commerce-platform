import { useSessionStore } from '../stores/session.store'

export function useCurrentUser() {
  return useSessionStore((state) => state.user)
}
