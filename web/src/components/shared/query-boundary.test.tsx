import { useSuspenseQuery } from '@tanstack/react-query'
import { screen } from '@testing-library/react'
import { describe, expect, it, vi } from 'vitest'
import { ApiError } from '@/app/api'
import { renderWithProviders } from '@/test/render'
import { QueryBoundary } from './query-boundary'

function Greeting({ load }: { load: () => Promise<string> }) {
  const { data } = useSuspenseQuery({ queryKey: ['greeting'], queryFn: load })
  return <p>{data}</p>
}

describe('QueryBoundary', () => {
  it('muestra la carga, luego el error y se recupera al reintentar', async () => {
    vi.spyOn(console, 'error').mockImplementation(() => undefined)
    const load = vi
      .fn<() => Promise<string>>()
      .mockRejectedValueOnce(new ApiError(500, 'INTERNAL_ERROR', 'boom', undefined, 'req_1'))
      .mockResolvedValueOnce('Hola')
    const { user } = renderWithProviders(
      <QueryBoundary fallback={<p>Cargando</p>}>
        <Greeting load={load} />
      </QueryBoundary>,
    )

    expect(screen.getByText('Cargando')).toBeInTheDocument()
    expect(await screen.findByText('Tuvimos un problema de nuestro lado')).toBeInTheDocument()
    await user.click(screen.getByRole('button', { name: 'Reintentar' }))
    expect(await screen.findByText('Hola')).toBeInTheDocument()
    expect(load).toHaveBeenCalledTimes(2)
  })
})
