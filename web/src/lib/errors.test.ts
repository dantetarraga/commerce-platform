import { describe, expect, it } from 'vitest'
import { ApiError } from '@/app/api'
import { describeError } from './errors'

describe('describeError', () => {
  it('un 5xx no muestra el mensaje técnico y conserva el código de soporte', () => {
    const result = describeError(
      new ApiError(500, 'INTERNAL_ERROR', 'Internal server error', undefined, 'req_1'),
    )
    expect(result).toMatchObject({
      kind: 'server',
      status: 500,
      requestId: 'req_1',
      retriable: true,
    })
    expect(result.title).not.toContain('Internal')
  })

  it('sin respuesta del servidor es un problema de conexión', () => {
    expect(describeError(new ApiError(0, 'NETWORK_ERROR', 'x'))).toMatchObject({
      kind: 'network',
      retriable: true,
    })
  })

  it('un 4xx muestra el mensaje del backend y no se reintenta', () => {
    expect(
      describeError(new ApiError(422, 'VALIDATION_ERROR', 'El celular no es válido')),
    ).toMatchObject({
      kind: 'request',
      title: 'El celular no es válido',
      retriable: false,
    })
    expect(describeError(new ApiError(403, 'FORBIDDEN', 'Solo administradores')).kind).toBe(
      'forbidden',
    )
    expect(describeError(new ApiError(404, 'NOT_FOUND', 'No existe')).kind).toBe('notFound')
  })

  it('un error que no viene de la API es genérico', () => {
    expect(describeError(new TypeError('boom'))).toMatchObject({ kind: 'unknown', retriable: true })
  })
})
