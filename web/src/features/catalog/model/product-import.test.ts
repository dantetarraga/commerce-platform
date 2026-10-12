import { describe, expect, it } from 'vitest'
import { sheetToRows, TEMPLATE_SHEET } from './product-import'

describe('sheetToRows', () => {
  it('lee la plantilla tal cual', () => {
    const result = sheetToRows(TEMPLATE_SHEET)
    expect(result).toEqual({
      ok: true,
      ignoredColumns: [],
      rows: [
        expect.objectContaining({ line: 2, name: 'Pollo a la brasa entero', price: '62.00' }),
        expect.objectContaining({ line: 3, name: '1/4 de pollo', price: '17,50' }),
        expect.objectContaining({ line: 4, name: 'Chicha morada 1 L', stock: '20' }),
        {
          line: 5,
          section: 'Postres',
          name: 'Mazamorra morada',
          price: '4',
          stock: 'sin límite',
          available: 'no',
        },
      ],
    })
  })

  it('acepta encabezados con tildes, mayúsculas u otros nombres', () => {
    const result = sheetToRows([
      ['', ''],
      ['Producto', 'Precio (S/)', 'Categoría', 'Proveedor'],
      ['Té', '2', 'Bebidas', 'Don Pepe'],
      ['', '', '', ''],
      ['Café', '4', '', ''],
    ])
    expect(result).toEqual({
      ok: true,
      ignoredColumns: ['Proveedor'],
      rows: [
        { line: 3, name: 'Té', price: '2', section: 'Bebidas' },
        { line: 5, name: 'Café', price: '4' },
      ],
    })
  })

  it('sin columna de nombre o sin filas explica qué falta', () => {
    expect(sheetToRows([['precio'], ['5']])).toMatchObject({ ok: false, message: /nombre/ })
    expect(sheetToRows([['nombre', 'precio']])).toMatchObject({
      ok: false,
      message: 'El archivo no tiene productos.',
    })
    expect(sheetToRows([])).toMatchObject({ ok: false, message: 'El archivo está vacío.' })
  })
})
