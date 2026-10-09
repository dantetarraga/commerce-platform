import { z } from 'zod'
import { nationalPhone } from '@/lib/form-schemas'

export const partnerSearchSchema = z.object({ phone: nationalPhone })
export const partnerFormSchema = z
  .object({
    phone: nationalPhone,
    firstName: z.string().trim().min(1, 'Escribe el nombre.').max(60, 'Máximo 60 caracteres.'),
    lastName: z.string().trim().min(1, 'Escribe el apellido.').max(60, 'Máximo 60 caracteres.'),
    role: z.enum(['MERCHANT', 'COURIER']),
    storeIds: z.array(z.string()),
    cityId: z.string(),
    vehicleType: z.enum(['MOTO', 'BICI', 'AUTO']),
    vehicleLabel: z.string().trim().max(40, 'Máximo 40 caracteres.'),
    plate: z.string().trim().max(12, 'La placa admite hasta 12 caracteres.'),
  })
  .superRefine((value, ctx) => {
    if (value.role !== 'COURIER') return
    if (!value.cityId) {
      ctx.addIssue({ code: 'custom', path: ['cityId'], message: 'Elige una ciudad.' })
    }
    if (!value.vehicleLabel) {
      ctx.addIssue({ code: 'custom', path: ['vehicleLabel'], message: 'Describe el vehículo.' })
    }
  })

export type PartnerForm = z.infer<typeof partnerFormSchema>
export type PartnerRole = PartnerForm['role']

export function partnerPayload(values: PartnerForm) {
  const { phone, firstName, lastName } = values
  const identity = { phone, firstName, lastName }
  return values.role === 'MERCHANT'
    ? { ...identity, storeIds: values.storeIds }
    : {
        ...identity,
        cityId: values.cityId,
        vehicleType: values.vehicleType,
        vehicleLabel: values.vehicleLabel,
        ...(values.plate && { plate: values.plate }),
      }
}
