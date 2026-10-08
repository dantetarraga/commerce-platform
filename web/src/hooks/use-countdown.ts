import { useCallback, useEffect, useState } from 'react'

export function useCountdown() {
  const [seconds, setSeconds] = useState(0)

  useEffect(() => {
    if (seconds <= 0) return
    const timer = setTimeout(() => setSeconds((value) => value - 1), 1000)
    return () => clearTimeout(timer)
  }, [seconds])

  const start = useCallback((from: number) => setSeconds(Math.max(0, Math.floor(from))), [])

  return { seconds, isRunning: seconds > 0, start }
}
