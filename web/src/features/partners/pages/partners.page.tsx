import { zodResolver } from '@hookform/resolvers/zod'
import { useQuery } from '@tanstack/react-query'
import { Search, Users } from 'lucide-react'
import { useState } from 'react'
import { useForm } from 'react-hook-form'
import { ApiError } from '@/app/api'
import { partnerQuery } from '@/app/api/admin-lookups'
import { EmptyState } from '@/components/shared/empty-state'
import { TextField } from '@/components/shared/form-controls'
import { PageHeader } from '@/components/shared/page-header'
import { ErrorState } from '@/components/shared/error-state'
import { LoadingState } from '@/components/shared/query-feedback'
import { Button } from '@/components/ui/button'
import { PartnerCard } from '../components/partner-card'
import { PartnerFormDialog } from '../components/partner-form'
import { partnerSearchSchema, type PartnerRole } from '../schemas/partners.schemas'

export function PartnersPage() {
  const [phone, setPhone] = useState('')
  const [editor, setEditor] = useState<{ role: PartnerRole; existing: boolean } | null>(null)
  const account = useQuery(partnerQuery(phone))
  const form = useForm<{ phone: string }>({
    resolver: zodResolver(partnerSearchSchema),
    defaultValues: { phone: '' },
  })
  const notFound = account.error instanceof ApiError && account.error.status === 404
  const submit = form.handleSubmit(({ phone: value }) => {
    if (phone === value) void account.refetch()
    else setPhone(value)
  })
  return (
    <div className='space-y-8'>
      <PageHeader
        eyebrow='Administración'
        title='Socios'
        description='Personas y negocios que hacen posible cada entrega.'
        actions={
          <>
            <Button
              variant='outline'
              onClick={() => setEditor({ role: 'COURIER', existing: false })}
            >
              Nuevo repartidor
            </Button>
            <Button onClick={() => setEditor({ role: 'MERCHANT', existing: false })}>
              Nuevo socio de negocio
            </Button>
          </>
        }
      />
      <form
        onSubmit={submit}
        noValidate
        className='corner-exit-m bg-card flex flex-wrap items-start gap-3 border p-5'
      >
        <div className='w-full max-w-sm'>
          <TextField
            label='Buscar por celular'
            type='tel'
            inputMode='numeric'
            placeholder='987 654 321'
            error={form.formState.errors.phone?.message}
            {...form.register('phone')}
          />
        </div>
        <Button type='submit' className='mt-6' disabled={account.isFetching}>
          <Search aria-hidden />
          Buscar
        </Button>
      </form>
      {!phone ? (
        <EmptyState
          icon={Users}
          title='Encuentra a un socio'
          description='Busca su celular para consultar sus roles, asignar negocios o actualizar su vehículo.'
        />
      ) : account.isPending ? (
        <LoadingState label='Buscando cuenta…' />
      ) : notFound ? (
        <EmptyState
          icon={Users}
          title='No encontramos ese celular'
          description='Puedes darlo de alta como socio de negocio o repartidor desde los botones de arriba.'
        />
      ) : account.isError ? (
        <ErrorState
          error={account.error}
          isRetrying={account.isFetching}
          onRetry={() => {
            void account.refetch()
          }}
        />
      ) : (
        <PartnerCard
          account={account.data}
          onEdit={(role) => setEditor({ role, existing: true })}
        />
      )}
      {editor && (
        <PartnerFormDialog
          role={editor.role}
          account={editor.existing ? account.data : undefined}
          phone={editor.existing || notFound ? phone : ''}
          onClose={() => setEditor(null)}
          onSaved={(savedPhone) => {
            setPhone(savedPhone)
            form.setValue('phone', savedPhone)
            setEditor(null)
          }}
        />
      )}
    </div>
  )
}
