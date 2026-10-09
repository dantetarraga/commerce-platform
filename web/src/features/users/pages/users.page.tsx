import { Link } from '@tanstack/react-router'
import { UserPlus } from 'lucide-react'
import { useDeferredValue, useState } from 'react'
import { SelectField, TextField } from '@/components/shared/form-controls'
import { PageHeader } from '@/components/shared/page-header'
import { QueryBoundary } from '@/components/shared/query-boundary'
import { Button } from '@/components/ui/button'
import { useDebouncedValue } from '@/hooks/use-debounced-value'
import { cn } from '@/lib/cn'
import type { UsersFilters } from '../actions/users.actions'
import { UsersList, UsersListSkeleton } from '../components/users-list'
import type { UserRole } from '../model/users'

const TABS: { role: UserRole | ''; label: string }[] = [
  { role: '', label: 'Todos' },
  { role: 'CUSTOMER', label: 'Clientes' },
  { role: 'MERCHANT', label: 'Negocios' },
  { role: 'COURIER', label: 'Repartidores' },
  { role: 'ADMIN', label: 'Equipo' },
]

export function UsersPage() {
  const [filters, setFilters] = useState<UsersFilters>({ q: '', role: '', status: '' })
  // Se busca al dejar de escribir; mientras llega, se queda la lista anterior.
  const q = useDebouncedValue(filters.q.trim())
  const query = { ...filters, q }
  const deferred = useDeferredValue(query)
  return (
    <div className='space-y-8'>
      <PageHeader
        eyebrow='Administración'
        title='Usuarios'
        description='Clientes, negocios, repartidores y equipo. Abre una cuenta para ver su actividad y gestionar su acceso.'
        actions={
          <Button asChild>
            <Link to='/admin/partners'>
              <UserPlus aria-hidden />
              Alta de socio
            </Link>
          </Button>
        }
      />
      <div role='tablist' aria-label='Tipo de cuenta' className='flex flex-wrap gap-2 border-b'>
        {TABS.map((tab) => (
          <button
            key={tab.label}
            type='button'
            role='tab'
            aria-selected={filters.role === tab.role}
            onClick={() => setFilters({ ...filters, role: tab.role })}
            className={cn(
              '-mb-px border-b-2 px-4 py-2 text-sm font-semibold transition-colors',
              filters.role === tab.role
                ? 'border-primary text-primary'
                : 'text-muted-foreground hover:text-foreground border-transparent',
            )}
          >
            {tab.label}
          </button>
        ))}
      </div>
      <div className='grid gap-3 sm:grid-cols-[minmax(0,1fr)_12rem]'>
        <TextField
          label='Buscar'
          placeholder='Nombre o celular'
          value={filters.q}
          onChange={(event) => setFilters({ ...filters, q: event.target.value })}
        />
        <SelectField
          label='Estado'
          value={filters.status}
          onChange={(event) =>
            setFilters({ ...filters, status: event.target.value as UsersFilters['status'] })
          }
        >
          <option value=''>Todas</option>
          <option value='active'>Activas</option>
          <option value='blocked'>Bloqueadas</option>
        </SelectField>
      </div>
      <QueryBoundary fallback={<UsersListSkeleton />}>
        <div className={cn(deferred.q !== filters.q.trim() && 'opacity-60 transition-opacity')}>
          <UsersList filters={deferred} />
        </div>
      </QueryBoundary>
    </div>
  )
}
