import { z } from 'zod'

export const phoneSchema = z.object({
  phone: z
    .string()
    .transform((value) => value.replace(/[\s-]/g, ''))
    .pipe(z.string().regex(/^9\d{8}$/, 'Ingresa un celular de 9 dígitos que empiece con 9.')),
})

export const codeSchema = z.object({
  code: z.string().regex(/^\d{6}$/, 'El código tiene 6 dígitos.'),
})

export type PhoneFormInput = z.input<typeof phoneSchema>
export type PhoneFormValues = z.output<typeof phoneSchema>
export type CodeFormValues = z.infer<typeof codeSchema>

/** Solo rutas internas del panel: evita redirigir a otro sitio con `?redirect=`. */
export const loginSearchSchema = z.object({
  redirect: z
    .string()
    .refine((value) => value.startsWith('/') && !value.startsWith('//'))
    .optional()
    .catch(undefined),
})
