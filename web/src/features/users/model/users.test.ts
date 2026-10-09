import { suspendedPartnerRoles, type UserDetail } from './users'

const base = { roles: ['CUSTOMER'], stores: [], courier: null } as unknown as UserDetail

describe('suspendedPartnerRoles', () => {
  it('ofrece reactivar lo que la suspensión quitó y sigue registrado', () => {
    const courier = {
      id: 'c1',
      vehicleType: 'MOTO',
      vehicleLabel: 'Moto roja',
      plate: null,
      status: 'OFFLINE',
    }
    expect(suspendedPartnerRoles({ ...base, courier })).toEqual(['COURIER'])
    const stores = [{ id: 's1', name: 'Pollería', isAcceptingOrders: false }]
    expect(suspendedPartnerRoles({ ...base, stores })).toEqual(['MERCHANT'])
  })

  it('no ofrece nada a un cliente ni a un socio activo', () => {
    expect(suspendedPartnerRoles(base)).toEqual([])
    const stores = [{ id: 's1', name: 'Pollería', isAcceptingOrders: true }]
    expect(suspendedPartnerRoles({ ...base, roles: ['CUSTOMER', 'MERCHANT'], stores })).toEqual([])
  })
})
