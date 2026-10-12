/** Filas que se envían al backend: celdas como texto; él las interpreta y explica los errores. */
export interface ImportRow {
  line: number
  section?: string
  name?: string
  description?: string
  price?: string
  stock?: string
  available?: string
  imageUrl?: string
}

type ImportField = Exclude<keyof ImportRow, 'line'>

export type ImportAction = 'create' | 'update' | 'unchanged' | 'error'

export interface ImportRowResult {
  line: number
  name: string
  action: ImportAction
  errors: string[]
  warnings: string[]
}

export interface ImportResult {
  dryRun: boolean
  created: number
  updated: number
  unchanged: number
  failed: number
  sectionsCreated: string[]
  rows: ImportRowResult[]
}

export const MAX_IMPORT_ROWS = 500

const normalize = (value: string) =>
  value
    .normalize('NFD')
    .replace(/[\u0300-\u036f]/g, '')
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, ' ')
    .trim()

export interface ImportColumn {
  field: ImportField
  /** Encabezado de la plantilla. */
  header: string
  /** Otros encabezados que también se aceptan. */
  aliases: string[]
  required: boolean
  help: string
}

export const IMPORT_COLUMNS: ImportColumn[] = [
  {
    field: 'section',
    header: 'seccion',
    aliases: ['seccion', 'categoria', 'section'],
    required: false,
    help: 'Dónde aparece en la carta. Si no existe, se crea.',
  },
  {
    field: 'name',
    header: 'nombre',
    aliases: ['nombre', 'producto', 'name'],
    required: true,
    help: 'Si ya está en la carta, se actualiza ese producto.',
  },
  {
    field: 'description',
    header: 'descripcion',
    aliases: ['descripcion', 'detalle'],
    required: false,
    help: 'Lo que lleva o acompaña.',
  },
  {
    field: 'price',
    header: 'precio',
    aliases: ['precio', 'precio s', 'price'],
    required: true,
    help: 'En soles: 12.50, 12,50 o S/ 12. Obligatorio para productos nuevos.',
  },
  {
    field: 'stock',
    header: 'stock',
    aliases: ['stock', 'cantidad'],
    required: false,
    help: 'Unidades disponibles. Vacío o «sin límite»: no se controla.',
  },
  {
    field: 'available',
    header: 'disponible',
    aliases: ['disponible', 'activo', 'available'],
    required: false,
    help: '«sí» o «no». Vacío: sí.',
  },
  {
    field: 'imageUrl',
    header: 'foto_url',
    aliases: ['foto url', 'foto', 'imagen', 'image url'],
    required: false,
    help: 'Enlace https a la foto. También puedes subirla después desde el producto.',
  },
]

export const TEMPLATE_SHEET: string[][] = [
  IMPORT_COLUMNS.map((column) => column.header),
  ['Pollos', 'Pollo a la brasa entero', 'Con papas fritas y ensalada', '62.00', '', 'sí', ''],
  ['Pollos', '1/4 de pollo', 'Con papas y cremas', '17,50', '', 'sí', ''],
  ['Bebidas', 'Chicha morada 1 L', 'Hecha en casa', 'S/ 8', '20', 'sí', ''],
  ['Postres', 'Mazamorra morada', '', '4', 'sin límite', 'no', ''],
]

export type SheetParse =
  { ok: true; rows: ImportRow[]; ignoredColumns: string[] } | { ok: false; message: string }

/**
 * Toma la primera fila con datos como encabezado. Las filas vacías se saltan, pero cada
 * fila conserva su número del archivo para que el error se encuentre en Excel.
 */
export function sheetToRows(sheet: string[][]): SheetParse {
  const headerIndex = sheet.findIndex((row) => row.some((cell) => cell.trim() !== ''))
  if (headerIndex === -1) return { ok: false, message: 'El archivo está vacío.' }

  const fields = sheet[headerIndex].map((cell) => {
    const key = normalize(cell)
    return IMPORT_COLUMNS.find((column) => column.aliases.includes(key))?.field
  })
  if (!fields.includes('name')) {
    return {
      ok: false,
      message: 'Falta la columna «nombre». Descarga la plantilla para ver el formato.',
    }
  }
  const ignoredColumns = sheet[headerIndex].filter(
    (cell, index) => cell.trim() !== '' && !fields[index],
  )

  const rows: ImportRow[] = []
  sheet.slice(headerIndex + 1).forEach((cells, index) => {
    if (!cells.some((cell) => cell.trim() !== '')) return
    const row: ImportRow = { line: headerIndex + index + 2 }
    fields.forEach((field, column) => {
      const value = cells[column]?.trim()
      if (field && value) row[field] = value
    })
    rows.push(row)
  })
  if (rows.length === 0) return { ok: false, message: 'El archivo no tiene productos.' }
  if (rows.length > MAX_IMPORT_ROWS) {
    return {
      ok: false,
      message: `El archivo tiene ${rows.length} productos. Importa hasta ${MAX_IMPORT_ROWS} por vez.`,
    }
  }
  return { ok: true, rows, ignoredColumns }
}
