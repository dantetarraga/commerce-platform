import { useSessionStore } from '../model/session.store'

export function useCurrentUser() {
  return useSessionStore((state) => state.user)
}
