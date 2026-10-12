import { useMutation } from '@tanstack/react-query'
import { ImageUp, Link2, LoaderCircle, Trash2 } from 'lucide-react'
import { useId, useRef, useState } from 'react'
import { ApiError, uploadImage, type ImageTarget } from '@/app/api'
import { Button } from '@/components/ui/button'
import { Field, FieldDescription, FieldError, FieldLabel } from '@/components/ui/field'
import { Input } from '@/components/ui/input'
import { cn } from '@/lib/cn'
import { describeError } from '@/lib/errors'
import { IMAGE_ACCEPT, MAX_SOURCE_BYTES, prepareImage } from '@/lib/images'
import { SafeImage } from './safe-image'

interface ImageUploadFieldProps {
  label: string
  value: string
  onChange: (url: string) => void
  target: ImageTarget
  /** `wide` para portadas y banners. */
  shape?: 'square' | 'wide'
  error?: string
  hint?: string
  disabled?: boolean
}

function uploadErrorMessage(error: unknown) {
  if (error instanceof ApiError && error.code === 'STORAGE_NOT_CONFIGURED') {
    return 'La subida de fotos aún no está activada. Pega la URL de la imagen.'
  }
  if (error instanceof ApiError && error.status >= 400 && error.status < 500) return error.message
  if (error instanceof Error && !(error instanceof ApiError)) return error.message
  return describeError(error).title
}

/** Foto que se sube al storage de Apamuy; también acepta pegar una URL https. */
export function ImageUploadField({
  label,
  value,
  onChange,
  target,
  shape = 'square',
  error,
  hint,
  disabled = false,
}: ImageUploadFieldProps) {
  const id = useId()
  const fileInput = useRef<HTMLInputElement>(null)
  const [progress, setProgress] = useState(0)
  const [showUrl, setShowUrl] = useState(false)
  const [fileError, setFileError] = useState<string | null>(null)
  const upload = useMutation({
    mutationFn: async (file: File) => {
      setProgress(0)
      return uploadImage(await prepareImage(file), target, setProgress)
    },
    onSuccess: onChange,
    onError: (uploadError) => {
      if (uploadError instanceof ApiError && uploadError.code === 'STORAGE_NOT_CONFIGURED') {
        setShowUrl(true)
      }
    },
  })

  const handleFile = (file: File | undefined) => {
    setFileError(null)
    if (!file) return
    if (!IMAGE_ACCEPT.split(',').includes(file.type)) {
      setFileError('Elige una foto JPG, PNG o WebP.')
      return
    }
    if (file.size > MAX_SOURCE_BYTES) {
      setFileError('La foto pesa más de 15 MB.')
      return
    }
    upload.mutate(file)
  }

  const busy = upload.isPending
  const message =
    error ?? fileError ?? (upload.error ? uploadErrorMessage(upload.error) : undefined)
  return (
    <Field>
      <FieldLabel htmlFor={`${id}-file`}>{label}</FieldLabel>
      <div className='flex flex-wrap items-center gap-4'>
        <div
          className={cn(
            'bg-muted relative shrink-0 overflow-hidden rounded-lg border',
            shape === 'wide' ? 'aspect-video w-40' : 'size-24',
          )}
        >
          {value && <SafeImage src={value} alt='' className='size-full object-cover' />}
          {busy && (
            <div className='bg-ink/60 text-ink-foreground absolute inset-0 flex items-center justify-center text-xs font-semibold'>
              <LoaderCircle className='mr-1 size-4 animate-spin' aria-hidden />
              {Math.round(progress * 100)}%
            </div>
          )}
        </div>
        <div className='flex flex-wrap gap-2'>
          <input
            ref={fileInput}
            id={`${id}-file`}
            type='file'
            accept={IMAGE_ACCEPT}
            className='sr-only'
            disabled={disabled || busy}
            onChange={(event) => {
              handleFile(event.target.files?.[0])
              event.target.value = ''
            }}
          />
          <Button
            type='button'
            variant='outline'
            size='sm'
            disabled={disabled || busy}
            onClick={() => fileInput.current?.click()}
          >
            <ImageUp aria-hidden />
            {busy ? 'Subiendo…' : value ? 'Cambiar foto' : 'Subir foto'}
          </Button>
          {value && (
            <Button
              type='button'
              variant='ghost'
              size='sm'
              disabled={disabled || busy}
              onClick={() => onChange('')}
            >
              <Trash2 aria-hidden />
              Quitar
            </Button>
          )}
          {!showUrl && (
            <Button
              type='button'
              variant='ghost'
              size='sm'
              disabled={disabled || busy}
              onClick={() => setShowUrl(true)}
            >
              <Link2 aria-hidden />
              Pegar URL
            </Button>
          )}
        </div>
      </div>
      {showUrl && (
        <Input
          type='url'
          aria-label={`${label}: URL https`}
          placeholder='https://…'
          value={value}
          disabled={disabled || busy}
          aria-invalid={Boolean(error)}
          onChange={(event) => onChange(event.target.value)}
        />
      )}
      {hint && <FieldDescription>{hint}</FieldDescription>}
      <FieldError>{message}</FieldError>
    </Field>
  )
}
