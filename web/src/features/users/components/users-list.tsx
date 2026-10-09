import { useSuspenseInfiniteQuery } from '@tanstack/react-query'
import { Link } from '@tanstack/react-router'
import { Users } from 'lucide-react'
import { EmptyState } from '@/components/shared/empty-state'
import { StatusBadge } from '@/components/shared/status-badge'
import { Button } from '@/components/ui/button'
import { Skeleton } from '@/components/ui/skeleton'
import { dateTime } from '@/lib/datetime'
import type { UsersFilters } from '../actions/users.actions'
import { fullName, ROLE_LABEL } from '../model/users'
import { usersQuery } from '../queries/users.queries'

/** Cuentas con sus roles, de 25 en 25. Suspende mientras carga. */
export function UsersList({ filters }: { filters: UsersFilters }) {
  const { data, hasNextPage, fetchNextPage, isFetchingNextPage } = useSuspenseInfiniteQuery(
    usersQuery(filters),
  )
  const users = data.pages.flatMap((page) => page.items)
  const total = data.pages[0]?.total ?? 0
  if (users.length === 0) {
    return (
      <EmptyState
        icon={Users}
        title='Sin resultados'
        description='No hay cuentas con esa búsqueda. Prueba con el celular o con otro filtro.'
      />
    )
  }
  return (
    <div className='space-y-4'>
      <p className='text-muted-foreground text-sm'>
        {total} {total === 1 ? 'cuenta' : 'cuentas'}
      </p>
      <ul className='divide-y'>
        {users.map((user) => (
          <li key={user.id}>
            <Link
              to='/admin/users/$userId'
              params={{ userId: user.id }}
              className='hover:bg-secondary/60 grid gap-2 rounded-md px-2 py-3 text-sm sm:grid-cols-[minmax(0,1fr)_auto_auto] sm:items-center sm:gap-4'
            >
              <span className='min-w-0'>
                <span className='block truncate font-semibold'>{fullName(user)}</span>
                <span className='text-muted-foreground block truncate tabular-nums'>
                  {user.phone}
                  {user.stores.length > 0 && ` · ${user.stores.map((s) => s.name).join(', ')}`}
                  {user.courier && ` · ${user.courier.vehicleLabel}`}
                </span>
              </span>
              <span className='flex flex-wrap gap-1'>
                {!user.isActive && <StatusBadge>Bloqueada</StatusBadge>}
                {user.roles
                  .filter((role) => role !== 'CUSTOMER' || user.roles.length === 1)
                  .map((role) => (
                    <StatusBadge key={role} active={role !== 'CUSTOMER'}>
                      {ROLE_LABEL[role]}
                    </StatusBadge>
                  ))}
              </span>
              <span className='text-muted-foreground tabular-nums sm:text-right'>
                {user.orders} {user.orders === 1 ? 'pedido' : 'pedidos'}
                <span className='block text-xs'>
                  {user.lastOrderAt
                    ? `Último: ${dateTime.formatRelative(user.lastOrderAt)}`
                    : `Desde ${dateTime.formatDate(user.createdAt)}`}
                </span>
              </span>
            </Link>
          </li>
        ))}
      </ul>
      {hasNextPage && (
        <div className='flex justify-center'>
          <Button
            variant='outline'
            disabled={isFetchingNextPage}
            onClick={() => {
              void fetchNextPage()
            }}
          >
            {isFetchingNextPage ? 'Cargando…' : 'Ver más cuentas'}
          </Button>
        </div>
      )}
    </div>
  )
}

export function UsersListSkeleton() {
  return (
    <div role='status' aria-label='Cargando cuentas' className='space-y-3'>
      {Array.from({ length: 8 }, (_, index) => (
        <Skeleton key={index} className='h-14 w-full' />
      ))}
    </div>
  )
}
