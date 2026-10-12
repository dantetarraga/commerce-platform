import { useEffect, useRef } from 'react'

/**
 * Para lo que no puede esperar a que alguien mire la pestaña: con [count] > 0 pone
 * «(N)» en el título y, cada vez que sube, suena un aviso corto y (si la pestaña está
 * en segundo plano y hay permiso) muestra una notificación del navegador.
 */
export function useAttentionAlert(count: number, message: (count: number) => string) {
  const previous = useRef(count)
  const baseTitle = useRef<string | null>(null)

  useEffect(() => {
    baseTitle.current ??= document.title.replace(/^\(\d+\)\s*/, '')
    document.title = count > 0 ? `(${count}) ${baseTitle.current}` : baseTitle.current
  }, [count])

  useEffect(
    () => () => {
      if (baseTitle.current) document.title = baseTitle.current
    },
    [],
  )

  useEffect(() => {
    const rose = count > previous.current
    previous.current = count
    if (!rose) return
    beep()
    if (document.hidden && 'Notification' in window && Notification.permission === 'granted') {
      const notice = new Notification('Apamuy', { body: message(count), tag: 'apamuy-attention' })
      notice.onclick = () => window.focus()
    }
  }, [count, message])
}

/** Dos tonos cortos con WebAudio: sin archivo de sonido que cargar. */
function beep() {
  const AudioContextClass = window.AudioContext as typeof AudioContext | undefined
  if (!AudioContextClass) return
  try {
    const context = new AudioContextClass()
    for (const [i, frequency] of [880, 660].entries()) {
      const oscillator = context.createOscillator()
      const gain = context.createGain()
      oscillator.frequency.value = frequency
      gain.gain.value = 0.15
      oscillator.connect(gain).connect(context.destination)
      const start = context.currentTime + i * 0.25
      oscillator.start(start)
      oscillator.stop(start + 0.18)
    }
    setTimeout(() => {
      context.close().catch(() => undefined)
    }, 1000)
  } catch {
    // Sin audio (permiso de reproducción automática): queda el título y la notificación.
  }
}
