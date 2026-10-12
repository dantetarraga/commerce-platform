/**
 * Lectura y escritura de hojas de cálculo. Las librerías se cargan solo al usarse
 * (pesan y casi nadie importa archivos) y solo se importan aquí.
 */

export type Sheet = string[][]

const isExcel = (file: File) =>
  /\.xlsx$/i.test(file.name) ||
  file.type === 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'

/** Primera hoja de un `.xlsx` o un `.csv` (con coma o punto y coma), con cada celda como texto. */
export async function readSpreadsheet(file: File): Promise<Sheet> {
  if (isExcel(file)) {
    const { readSheet } = await import('read-excel-file/browser')
    // Los números quedan como el texto de la celda: el backend interpreta "12,50" o "S/ 8".
    const data = await readSheet<string>(file, { parseNumber: (value) => value })
    return data.map((row) => row.map((cell) => (cell == null ? '' : String(cell))))
  }
  const { default: Papa } = await import('papaparse')
  const text = await file.text()
  const result = Papa.parse<string[]>(text.replace(/^\uFEFF/, ''), { skipEmptyLines: 'greedy' })
  return result.data
}

/** CSV con BOM: Excel lo abre con las tildes bien. */
export async function toCsvBlob(rows: Sheet): Promise<Blob> {
  const { default: Papa } = await import('papaparse')
  return new Blob(['\uFEFF', Papa.unparse(rows)], { type: 'text/csv;charset=utf-8' })
}
