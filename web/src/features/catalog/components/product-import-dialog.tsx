import { useMutation } from '@tanstack/react-query'
import { Download, FileSpreadsheet, LoaderCircle } from 'lucide-react'
import { useId, useRef, useState } from 'react'
import { toast } from 'sonner'
import { EditorDialog } from '@/components/shared/editor-dialog'
import { ErrorNotice } from '@/components/shared/query-feedback'
import { Button } from '@/components/ui/button'
import { readSpreadsheet, toCsvBlob } from '@/lib/spreadsheet'
import { useCatalogScope } from '../hooks/use-catalog-scope'
import type { StoreDetail } from '../model/catalog'
import {
  IMPORT_COLUMNS,
  sheetToRows,
  TEMPLATE_SHEET,
  type ImportResult,
  type ImportRow,
} from '../model/product-import'
import { importProductsMutation } from '../mutations/products.mutations'

async function downloadTemplate() {
  const url = URL.createObjectURL(await toCsvBlob(TEMPLATE_SHEET))
  const link = document.createElement('a')
  link.href = url
  link.download = 'plantilla-carta-apamuy.csv'
  link.click()
  URL.revokeObjectURL(url)
}

/** Así debe verse el archivo: las mismas filas que trae la plantilla. */
function TemplateExample() {
  const [header, ...rows] = TEMPLATE_SHEET
  return (
    <div className='space-y-3'>
      <h3 className='text-sm font-semibold'>Ejemplo</h3>
      <div className='overflow-x-auto rounded-lg border'>
        <table className='w-full text-left text-xs'>
          <thead className='bg-secondary'>
            <tr>
              <th scope='col' className='text-muted-foreground px-2 py-2 font-medium'>
                <span className='sr-only'>Fila</span>
              </th>
              {header.map((cell) => (
                <th key={cell} scope='col' className='px-3 py-2 font-mono font-semibold'>
                  {cell}
                </th>
              ))}
            </tr>
          </thead>
          <tbody className='divide-y'>
            {rows.map((row, index) => (
              <tr key={row[1]}>
                <td className='text-muted-foreground bg-secondary px-2 py-2 text-center tabular-nums'>
                  {index + 2}
                </td>
                {row.map((cell, column) => (
                  <td key={header[column]} className='px-3 py-2 whitespace-nowrap'>
                    {cell}
                  </td>
                ))}
              </tr>
            ))}
          </tbody>
        </table>
      </div>
      <details className='text-sm'>
        <summary className='cursor-pointer font-semibold'>Qué va en cada columna</summary>
        <dl className='mt-3 space-y-2'>
          {IMPORT_COLUMNS.map((column) => (
            <div key={column.field} className='grid gap-1 sm:grid-cols-[8rem_1fr] sm:gap-3'>
              <dt className='font-mono font-semibold'>
                {column.header}
                {column.required && <span className='text-primary'> *</span>}
              </dt>
              <dd className='text-muted-foreground'>{column.help}</dd>
            </div>
          ))}
        </dl>
        <p className='text-muted-foreground mt-3'>
          <span className='text-primary'>*</span> Obligatorio. El orden de las columnas no importa y
          puedes dejar fuera las que no uses.
        </p>
      </details>
    </div>
  )
}

function FileStep({
  busy,
  error,
  onFile,
}: {
  busy: boolean
  error: string | null
  onFile: (file: File) => void
}) {
  const id = useId()
  const input = useRef<HTMLInputElement>(null)
  return (
    <div className='space-y-5'>
      <ol className='text-muted-foreground list-decimal space-y-2 pl-5 text-sm'>
        <li>Descarga la plantilla y ábrela en Excel o Google Sheets.</li>
        <li>
          Escribe un producto por fila, como en el ejemplo. Solo{' '}
          <strong className='text-foreground'>nombre</strong> y{' '}
          <strong className='text-foreground'>precio</strong> son obligatorios.
        </li>
        <li>
          Guarda como .xlsx o .csv y súbelo. Antes de guardar te mostramos qué cambia y si alguna
          fila tiene errores.
        </li>
      </ol>
      <div className='flex flex-wrap gap-3'>
        <Button
          type='button'
          variant='outline'
          onClick={() => {
            void downloadTemplate()
          }}
        >
          <Download aria-hidden />
          Descargar plantilla
        </Button>
        <input
          ref={input}
          id={id}
          type='file'
          accept='.xlsx,.csv,text/csv,application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'
          className='sr-only'
          disabled={busy}
          onChange={(event) => {
            const file = event.target.files?.[0]
            event.target.value = ''
            if (file) onFile(file)
          }}
        />
        <Button type='button' disabled={busy} onClick={() => input.current?.click()}>
          {busy ? (
            <LoaderCircle className='animate-spin' aria-hidden />
          ) : (
            <FileSpreadsheet aria-hidden />
          )}
          {busy ? 'Revisando…' : 'Elegir archivo'}
        </Button>
      </div>
      {error && (
        <p role='alert' className='text-destructive text-sm font-medium'>
          {error}
        </p>
      )}
      <TemplateExample />
    </div>
  )
}

const plural = (count: number, one: string, many: string) => `${count} ${count === 1 ? one : many}`

function PreviewStep({
  fileName,
  result,
  ignoredColumns,
}: {
  fileName: string
  result: ImportResult
  ignoredColumns: string[]
}) {
  const issues = result.rows.filter((row) => row.errors.length || row.warnings.length)
  const totals = [
    { label: 'Nuevos', value: result.created },
    { label: 'Se actualizan', value: result.updated },
    { label: 'Sin cambios', value: result.unchanged },
    { label: 'Con errores', value: result.failed },
  ]
  return (
    <div className='space-y-5'>
      <p className='text-muted-foreground text-sm'>
        Revisamos <strong className='text-foreground'>{fileName}</strong>. Todavía no se guardó
        nada.
      </p>
      <dl className='grid grid-cols-2 gap-3 sm:grid-cols-4'>
        {totals.map((total) => (
          <div key={total.label} className='bg-secondary rounded-lg p-3'>
            <dt className='text-muted-foreground text-xs'>{total.label}</dt>
            <dd className='text-2xl font-semibold tabular-nums'>{total.value}</dd>
          </div>
        ))}
      </dl>
      {result.sectionsCreated.length > 0 && (
        <p className='text-sm'>
          Secciones nuevas: <strong>{result.sectionsCreated.join(', ')}</strong>
        </p>
      )}
      {ignoredColumns.length > 0 && (
        <p className='text-muted-foreground text-sm'>
          Columnas que no se usan: {ignoredColumns.join(', ')}.
        </p>
      )}
      {issues.length > 0 && (
        <div className='space-y-2'>
          <h3 className='font-semibold'>
            {result.failed > 0
              ? `Corrige ${plural(result.failed, 'fila', 'filas')} en el archivo y vuelve a subirlo`
              : 'Avisos'}
          </h3>
          <ul className='max-h-64 divide-y overflow-y-auto rounded-lg border text-sm'>
            {issues.map((row) => (
              <li key={row.line} className='space-y-1 p-3'>
                <p className='font-medium'>
                  Fila {row.line}
                  {row.name && ` · ${row.name}`}
                </p>
                {row.errors.map((message) => (
                  <p key={message} className='text-destructive'>
                    {message}
                  </p>
                ))}
                {row.warnings.map((message) => (
                  <p key={message} className='text-muted-foreground'>
                    {message}
                  </p>
                ))}
              </li>
            ))}
          </ul>
        </div>
      )}
    </div>
  )
}

interface Preview {
  fileName: string
  rows: ImportRow[]
  ignoredColumns: string[]
  result: ImportResult
}

/** Carga masiva de la carta: primero revisa el archivo y muestra qué haría; luego guarda todo junto. */
export function ProductImportDialog({
  store,
  onClose,
}: {
  store: StoreDetail
  onClose: () => void
}) {
  const scope = useCatalogScope()
  const mutation = useMutation(importProductsMutation(store.id, scope))
  const [reading, setReading] = useState(false)
  const [fileError, setFileError] = useState<string | null>(null)
  const [preview, setPreview] = useState<Preview | null>(null)

  const handleFile = async (file: File) => {
    setFileError(null)
    mutation.reset()
    setReading(true)
    try {
      let sheet: string[][]
      try {
        sheet = await readSpreadsheet(file)
      } catch {
        setFileError(
          'No pudimos leer el archivo. Guárdalo como .xlsx o .csv y vuelve a intentarlo.',
        )
        return
      }
      const parsed = sheetToRows(sheet)
      if (!parsed.ok) {
        setFileError(parsed.message)
        return
      }
      const result = await mutation.mutateAsync({ rows: parsed.rows, dryRun: true })
      setPreview({
        fileName: file.name,
        rows: parsed.rows,
        ignoredColumns: parsed.ignoredColumns,
        result,
      })
    } catch {
      /* Error del backend visible en ErrorNotice. */
    } finally {
      setReading(false)
    }
  }

  const handleConfirm = async () => {
    if (!preview) return
    try {
      const result = await mutation.mutateAsync({ rows: preview.rows, dryRun: false })
      toast.success(
        `Carta actualizada: ${plural(result.created, 'producto nuevo', 'productos nuevos')} y ${plural(result.updated, 'actualizado', 'actualizados')}.`,
      )
      onClose()
    } catch {
      /* Error visible en el diálogo. */
    }
  }

  const busy = reading || mutation.isPending
  const pending = preview ? preview.result.created + preview.result.updated : 0
  return (
    <EditorDialog
      title='Importar productos'
      description={`Carta de ${store.name}. Desde un Excel (.xlsx) o un CSV, hasta 500 productos.`}
      onClose={onClose}
      busy={busy}
    >
      <div className='space-y-5'>
        {preview ? (
          <PreviewStep
            fileName={preview.fileName}
            result={preview.result}
            ignoredColumns={preview.ignoredColumns}
          />
        ) : (
          <FileStep
            busy={busy}
            error={fileError}
            onFile={(file) => {
              void handleFile(file)
            }}
          />
        )}
        <ErrorNotice error={mutation.error} />
        <div className='flex flex-wrap justify-end gap-3'>
          <Button type='button' variant='outline' disabled={busy} onClick={onClose}>
            Cancelar
          </Button>
          {preview && (
            <>
              <Button
                type='button'
                variant='outline'
                disabled={busy}
                onClick={() => {
                  mutation.reset()
                  setPreview(null)
                }}
              >
                Elegir otro archivo
              </Button>
              <Button
                type='button'
                disabled={busy || preview.result.failed > 0 || pending === 0}
                onClick={() => {
                  void handleConfirm()
                }}
              >
                {mutation.isPending
                  ? 'Guardando…'
                  : pending === 0
                    ? 'No hay cambios'
                    : `Guardar ${plural(pending, 'producto', 'productos')}`}
              </Button>
            </>
          )}
        </div>
      </div>
    </EditorDialog>
  )
}
