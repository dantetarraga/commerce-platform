import { describe, expect, it } from 'vitest'
import { partnerFormSchema, partnerPayload, type PartnerForm } from './partners.schemas'

const partner: PartnerForm = {
  phone: '987 654 321',
  firstName: 'Ana',
  lastName: 'Quispe',
  role: 'MERCHANT',
  storeIds: ['store-1'],
  cityId: '',
  vehicleType: 'MOTO',
  vehicleLabel: '',
  plate: '',
}

describe('Alta de socios', () => {
  it('normaliza el celular y solo envía datos de negocio para el merchant', () => {
    expect(partnerPayload(partnerFormSchema.parse(partner))).toEqual({
      phone: '987654321',
      firstName: 'Ana',
      lastName: 'Quispe',
      storeIds: ['store-1'],
    })
  })

  it('exige ciudad y descripción del vehículo para repartidores', () => {
    const result = partnerFormSchema.safeParse({ ...partner, role: 'COURIER' })
    expect(result.success).toBe(false)
    if (!result.success) {
      expect(result.error.issues.map((issue) => issue.path[0])).toEqual(['cityId', 'vehicleLabel'])
    }
  })

  it('no envía negocios ni placa vacía al alta del repartidor', () => {
    const values = partnerFormSchema.parse({
      ...partner,
      role: 'COURIER',
      cityId: 'espinar',
      vehicleLabel: 'Moto roja',
    })
    expect(partnerPayload(values)).toEqual({
      phone: '987654321',
      firstName: 'Ana',
      lastName: 'Quispe',
      cityId: 'espinar',
      vehicleType: 'MOTO',
      vehicleLabel: 'Moto roja',
    })
  })
})
