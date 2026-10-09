import { useQuery } from '@tanstack/react-query'
import { useState } from 'react'
import { ApiError } from '@/app/api'
import { partnerQuery } from '@/app/api/admin-lookups'
import { TextField } from '@/components/shared/form-controls'
import { ErrorNotice, LoadingState } from '@/components/shared/query-feedback'
import { Button } from '@/components/ui/button'
import { FieldError } from '@/components/ui/field'
import { nationalPhone } from '@/lib/form-schemas'

export function OwnerPicker({
  value,
  onChange,
  error,
}: {
  value: string
  onChange: (id: string) => void
  error?: string
}) {
  const [input, setInput] = useState('')
  const [phone, setPhone] = useState('')
  const [inputError, setInputError] = useState('')
  const account = useQuery(partnerQuery(phone))
  const notFound = account.error instanceof ApiError && account.error.status === 404
  function handleSearch() {
    const result = nationalPhone.safeParse(input)
    setInputError(result.success ? '' : result.error.issues[0].message)
    if (!result.success) return
    if (phone === result.data) void account.refetch()
    else setPhone(result.data)
  }
  const validOwner = account.data?.roles.includes('MERCHANT') && account.data.isActive
  return (
    <div className='bg-secondary/50 space-y-3 rounded-lg p-4'>
      <p className='text-sm font-semibold'>Dueño del negocio</p>
      {value && (
        <p className='text-success text-sm'>
          {account.data?.id === value
            ? `Seleccionado: ${account.data.firstName} ${account.data.lastName}`
            : 'Se conservará el dueño actual.'}
        </p>
      )}
      <div className='flex flex-wrap items-start gap-2'>
        <div className='min-w-0 flex-1'>
          <TextField
            label='Celular del dueño'
            type='tel'
            value={input}
            onChange={(event) => setInput(event.target.value)}
            error={inputError}
          />
        </div>
        <Button
          type='button'
          variant='outline'
          className='mt-6'
          disabled={account.isFetching}
          onClick={handleSearch}
        >
          Buscar dueño
        </Button>
      </div>
      {phone && account.isPending && <LoadingState />}
      {notFound ? (
        <p className='text-muted-foreground text-sm'>
          No hay una cuenta con ese celular. Regístrala primero en Socios.
        </p>
      ) : (
        <ErrorNotice
          error={account.error}
          onRetry={() => {
            void account.refetch()
          }}
        />
      )}
      {account.data && !account.isError && (
        <div className='space-y-2 text-sm'>
          <p>
            {account.data.firstName} {account.data.lastName} · {account.data.phone}
          </p>
          {validOwner ? (
            <Button
              type='button'
              variant='outline'
              size='sm'
              onClick={() => onChange(account.data.id)}
            >
              Seleccionar como dueño
            </Button>
          ) : (
            <p className='text-destructive'>
              Esta cuenta necesita estar activa y tener acceso de negocio. Revísala en Socios.
            </p>
          )}
        </div>
      )}
      <FieldError>{error}</FieldError>
    </div>
  )
}
