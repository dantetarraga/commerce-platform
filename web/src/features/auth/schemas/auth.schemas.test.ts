import { describe, expect, it } from 'vitest'
import { codeSchema, loginSearchSchema, phoneSchema } from './auth.schemas'

describe('phoneSchema', () => {
  it('acepta celulares peruanos y quita espacios y guiones', () => {
    expect(phoneSchema.parse({ phone: '987 654-321' })).toEqual({ phone: '987654321' })
  })

  it('rechaza números que no son celulares', () => {
    expect(phoneSchema.safeParse({ phone: '87654321' }).success).toBe(false)
    expect(phoneSchema.safeParse({ phone: '887654321' }).success).toBe(false)
  })
})

describe('codeSchema', () => {
  it('exige 6 dígitos', () => {
    expect(codeSchema.safeParse({ code: '123456' }).success).toBe(true)
    expect(codeSchema.safeParse({ code: '12345' }).success).toBe(false)
  })
})

describe('loginSearchSchema', () => {
  it('solo acepta redirecciones internas', () => {
    expect(loginSearchSchema.parse({ redirect: '/admin' })).toEqual({ redirect: '/admin' })
    expect(loginSearchSchema.parse({ redirect: 'https://otro.sitio' })).toEqual({})
    expect(loginSearchSchema.parse({ redirect: '//otro.sitio' })).toEqual({})
  })
})
