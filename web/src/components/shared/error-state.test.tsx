import { screen } from '@testing-library/react'
import { describe, expect, it, vi } from 'vitest'
import { ApiError } from '@/app/api'
import { renderWithProviders } from '@/test/render'
import { ErrorState } from './error-state'

describe('ErrorState', () => {
  it('ante un 500 ofrece reintentar y copiar el código de soporte', async () => {
    const onRetry = vi.fn()
    const { user } = renderWithProviders(
      <ErrorState
        error={new ApiError(503, 'INTERNAL_ERROR', 'upstream', undefined, 'req_9')}
        onRetry={onRetry}
      />,
    )

    expect(screen.getByRole('alert')).toHaveTextContent('Tuvimos un problema de nuestro lado')
    expect(screen.getByText('Error 503')).toBeInTheDocument()
    await user.click(screen.getByRole('button', { name: 'Reintentar' }))
    expect(onRetry).toHaveBeenCalledOnce()
    await user.click(screen.getByRole('button', { name: 'Copiar' }))
    expect(await navigator.clipboard.readText()).toBe('req_9')
    expect(await screen.findByRole('button', { name: 'Copiado' })).toBeInTheDocument()
  })

  it('no ofrece reintentar lo que no se arregla reintentando', () => {
    renderWithProviders(
      <ErrorState
        error={new ApiError(403, 'FORBIDDEN', 'Solo administradores')}
        onRetry={vi.fn()}
      />,
    )
    expect(screen.getByText('Solo administradores')).toBeInTheDocument()
    expect(screen.queryByRole('button', { name: 'Reintentar' })).not.toBeInTheDocument()
  })

  it('mientras reintenta, el botón queda deshabilitado', () => {
    renderWithProviders(
      <ErrorState error={new ApiError(0, 'NETWORK_ERROR', 'x')} onRetry={vi.fn()} isRetrying />,
    )
    expect(screen.getByRole('button', { name: 'Reintentando…' })).toBeDisabled()
  })
})
