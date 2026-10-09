import { useCallback, useEffect, useState } from 'react'

export function useClipboard(resetAfterMs = 2000) {
  const [copied, setCopied] = useState(false)

  useEffect(() => {
    if (!copied) return
    const timer = window.setTimeout(() => setCopied(false), resetAfterMs)
    return () => window.clearTimeout(timer)
  }, [copied, resetAfterMs])

  const copy = useCallback(async (text: string) => {
    try {
      await navigator.clipboard.writeText(text)
      setCopied(true)
    } catch {
      setCopied(false)
    }
  }, [])

  return { copied, copy }
}
