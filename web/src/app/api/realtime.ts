import { io, type Socket } from 'socket.io-client'
import { env } from '@/app/config/env'

type Handler = (payload: unknown) => void

export interface RealtimeOptions {
  getAccessToken: () => string | null
}

/**
 * Una sola conexión Socket.IO al namespace `/ws` del backend. Se abre con el primer
 * suscriptor y se cierra con el último. El token se pide en cada (re)conexión, así
 * que sirve el renovado por el interceptor.
 */
class Realtime {
  #socket: Socket | null = null
  #options: RealtimeOptions | null = null
  readonly #handlers = new Map<string, Set<Handler>>()

  configure(options: RealtimeOptions) {
    this.#options = options
  }

  subscribe(event: string, handler: Handler): () => void {
    let handlers = this.#handlers.get(event)
    if (!handlers) {
      handlers = new Set()
      this.#handlers.set(event, handlers)
      this.#connect().on(event, (payload: unknown) => {
        this.#handlers.get(event)?.forEach((listener) => listener(payload))
      })
    }
    handlers.add(handler)
    return () => {
      handlers.delete(handler)
      if (handlers.size > 0) return
      this.#handlers.delete(event)
      this.#socket?.off(event)
      if (this.#handlers.size === 0) this.#disconnect()
    }
  }

  #connect(): Socket {
    if (this.#socket) return this.#socket
    const options = this.#options
    this.#socket = io(env.wsUrl, {
      auth: (callback) => callback({ token: options?.getAccessToken() ?? '' }),
      transports: ['websocket'],
    })
    return this.#socket
  }

  #disconnect() {
    this.#socket?.disconnect()
    this.#socket = null
  }
}

export const realtime = new Realtime()
