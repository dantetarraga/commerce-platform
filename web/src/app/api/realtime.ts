import { io, type Socket } from 'socket.io-client'
import { env } from '@/app/config/env'

type Handler = (payload: unknown) => void

export type RealtimeStatus = 'idle' | 'connected' | 'reconnecting'

export interface RealtimeOptions {
  getAccessToken: () => string | null
  /** Para reconectar cuando el backend rechaza el token vencido del handshake. */
  refreshAccessToken?: () => Promise<string>
}

/** Sin esto, un handshake rechazado deja el socket muerto hasta recargar la página. */
const RETRY_AFTER_REJECT_MS = 5_000

/**
 * Una sola conexión Socket.IO al namespace `/ws` del backend. Se abre con el primer
 * suscriptor y se cierra con el último. El token se pide en cada (re)conexión, así
 * que sirve el renovado por el interceptor.
 */
class Realtime {
  #socket: Socket | null = null
  #options: RealtimeOptions | null = null
  #status: RealtimeStatus = 'idle'
  #wasConnected = false
  #retry: ReturnType<typeof setTimeout> | null = null
  readonly #handlers = new Map<string, Set<Handler>>()
  readonly #statusListeners = new Set<() => void>()
  readonly #reconnectListeners = new Set<() => void>()

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

  get status() {
    return this.#status
  }

  /** Para `useSyncExternalStore`. */
  subscribeStatus = (listener: () => void) => {
    this.#statusListeners.add(listener)
    return () => {
      this.#statusListeners.delete(listener)
    }
  }

  /** Volvió la conexión: lo que pasó mientras tanto no llegó por el socket. */
  onReconnect(listener: () => void) {
    this.#reconnectListeners.add(listener)
    return () => {
      this.#reconnectListeners.delete(listener)
    }
  }

  #setStatus(status: RealtimeStatus) {
    if (status === this.#status) return
    this.#status = status
    this.#statusListeners.forEach((listener) => listener())
  }

  #connect(): Socket {
    if (this.#socket) return this.#socket
    const socket = io(env.wsUrl, {
      auth: (callback) => callback({ token: this.#options?.getAccessToken() ?? '' }),
      transports: ['websocket'],
    })
    socket.on('connect', () => {
      this.#setStatus('connected')
      if (this.#wasConnected) this.#reconnectListeners.forEach((listener) => listener())
      this.#wasConnected = true
    })
    socket.on('disconnect', () => this.#setStatus('reconnecting'))
    socket.on('connect_error', () => {
      this.#setStatus('reconnecting')
      // `active` en falso: el backend rechazó el handshake y Socket.IO no reintenta.
      if (!socket.active) this.#retryWithFreshToken(socket)
    })
    this.#socket = socket
    return socket
  }

  #retryWithFreshToken(socket: Socket) {
    if (this.#retry) return
    this.#retry = setTimeout(() => {
      this.#retry = null
      if (this.#socket !== socket) return
      const refresh = this.#options?.refreshAccessToken
      const ready = refresh ? refresh().catch(() => undefined) : Promise.resolve()
      ready
        .then(() => {
          if (this.#socket === socket) socket.connect()
        })
        .catch(() => undefined)
    }, RETRY_AFTER_REJECT_MS)
  }

  #disconnect() {
    if (this.#retry) clearTimeout(this.#retry)
    this.#retry = null
    this.#socket?.disconnect()
    this.#socket = null
    this.#wasConnected = false
    this.#setStatus('idle')
  }
}

export const realtime = new Realtime()
