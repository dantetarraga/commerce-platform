import { describe, expect, it } from 'vitest'
import { panelHomeFor } from './user'

describe('panelHomeFor', () => {
  it('lleva a cada rol a su portal; el admin tiene prioridad', () => {
    expect(panelHomeFor({ roles: ['ADMIN'] })).toBe('/admin')
    expect(panelHomeFor({ roles: ['CUSTOMER', 'MERCHANT'] })).toBe('/partner')
    expect(panelHomeFor({ roles: ['MERCHANT', 'ADMIN'] })).toBe('/admin')
  })

  it('clientes y repartidores no tienen portal web', () => {
    expect(panelHomeFor({ roles: ['CUSTOMER'] })).toBeNull()
    expect(panelHomeFor({ roles: ['COURIER', 'CUSTOMER'] })).toBeNull()
  })
})
