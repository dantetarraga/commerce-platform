import { zodResolver } from '@hookform/resolvers/zod'
import { useQueryClient, useSuspenseQuery } from '@tanstack/react-query'
import { Search, Users } from 'lucide-react'
import { useState, useTransition } from 'react'
import { useForm } from 'react-hook-form'
import { partnerQuery, type PartnerAccount } from '@/app/api/lookups'
import { EmptyState } from '@/components/shared/empty-state'
import { TextField } from '@/components/shared/form-controls'
import { PageHeader } from '@/components/shared/page-header'
import { QueryBoundary } from '@/components/shared/query-boundary'
import { Button } from '@/components/ui/button'
import { PartnerCard } from '../components/partner-card'
import { PartnerCardSkeleton } from '../components/partner-card-skeleton'
import { PartnerFormDialog } from '../components/partner-form'
import { partnerSearchSchema, type PartnerRole } from '../schemas/partners.schemas'
import { useLastPartnerPhone, usePartnerSearchActions } from '../stores/partner-search.store'

interface Editor {
  role: PartnerRole
  account?: PartnerAccount
  phone: string
}

export function PartnersPage() {
  // El store recuerda la búsqueda entre visitas; el estado local permite cambiarla dentro de
  // una transición (las actualizaciones de Zustand son síncronas y mostrarían el fallback).
  const lastPhone = useLastPartnerPhone()
  const { remember } = usePartnerSearchActions()
  const [phone, setPhone] = useState(lastPhone)
  const [editor, setEditor] = useState<Editor | null>(null)
  const [isSearching, startSearch] = useTransition()
  const queryClient = useQueryClient()
  const form = useForm<{ phone: string }>({
    resolver: zodResolver(partnerSearchSchema),
    defaultValues: { phone: lastPhone },
  })
  function search(value: string) {
    remember(value)
    startSearch(() => setPhone(value))
  }
  const submit = form.handleSubmit(({ phone: value }) => {
    if (phone === value) void queryClient.refetchQueries({ queryKey: partnerQuery(value).queryKey })
    // Mientras busca otro celular, se queda el resultado anterior en vez del indicador.
    else search(value)
  })
  function openCreate(role: PartnerRole) {
    // Si la última búsqueda no encontró a nadie, ese celular es el que se quiere dar de alta.
    const lastResult = phone ? queryClient.getQueryData(partnerQuery(phone).queryKey) : undefined
    setEditor({ role, phone: lastResult === null ? phone : '' })
  }
  return (
    <div className='space-y-8'>
      <PageHeader
        eyebrow='Administración'
        title='Socios'
        description='Personas y negocios que hacen posible cada entrega.'
        actions={
          <>
            <Button variant='outline' onClick={() => openCreate('COURIER')}>
              Nuevo repartidor
            </Button>
            <Button onClick={() => openCreate('MERCHANT')}>Nuevo socio de negocio</Button>
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
        <Button type='submit' className='mt-6' disabled={isSearching}>
          <Search aria-hidden />
          {isSearching ? 'Buscando…' : 'Buscar'}
        </Button>
      </form>
      {phone ? (
        <QueryBoundary fallback={<PartnerCardSkeleton />}>
          <PartnerResult
            phone={phone}
            onEdit={(role, account) => setEditor({ role, account, phone: account.phone })}
          />
        </QueryBoundary>
      ) : (
        <EmptyState
          icon={Users}
          title='Encuentra a un socio'
          description='Busca su celular para consultar sus roles, asignar negocios o actualizar su vehículo.'
        />
      )}
      {editor && (
        <PartnerFormDialog
          role={editor.role}
          account={editor.account}
          phone={editor.phone}
          onClose={() => setEditor(null)}
          onSaved={(savedPhone) => {
            search(savedPhone)
            form.setValue('phone', savedPhone)
            setEditor(null)
          }}
        />
      )}
    </div>
  )
}

interface PartnerResultProps {
  phone: string
  onEdit: (role: PartnerRole, account: PartnerAccount) => void
}

function PartnerResult({ phone, onEdit }: PartnerResultProps) {
  const { data: account } = useSuspenseQuery(partnerQuery(phone))
  if (!account) {
    return (
      <EmptyState
        icon={Users}
        title='No encontramos ese celular'
        description='Puedes darlo de alta como socio de negocio o repartidor desde los botones de arriba.'
      />
    )
  }
  return <PartnerCard account={account} onEdit={(role) => onEdit(role, account)} />
}
