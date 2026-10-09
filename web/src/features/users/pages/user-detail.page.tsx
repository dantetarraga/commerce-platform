import { useSuspenseQuery } from '@tanstack/react-query'
import { Link, useParams } from '@tanstack/react-router'
import { ArrowLeft } from 'lucide-react'
import type { ReactNode } from 'react'
import { QueryBoundary } from '@/components/shared/query-boundary'
import { StatTile } from '@/components/shared/stat-tile'
import { StatusBadge } from '@/components/shared/status-badge'
import { Skeleton } from '@/components/ui/skeleton'
import { dateTime } from '@/lib/datetime'
import { formatMoney } from '@/lib/money'
import { UserActions } from '../components/user-actions'
import {
  ACTION_LABEL,
  fullName,
  ORDER_STATUS_LABEL,
  ROLE_LABEL,
  type UserDetail,
} from '../model/users'
import { userQuery } from '../queries/users.queries'

export function UserDetailPage() {
  const { userId } = useParams({ from: '/admin/users/$userId' })
  return (
    <div className='space-y-8'>
      <Link
        to='/admin/users'
        className='text-muted-foreground hover:text-foreground inline-flex items-center gap-2 text-sm'
      >
        <ArrowLeft className='size-4' aria-hidden />
        Usuarios
      </Link>
      <QueryBoundary fallback={<UserDetailSkeleton />}>
        <UserProfile userId={userId} />
      </QueryBoundary>
    </div>
  )
}

function Card({ title, children }: { title: string; children: ReactNode }) {
  return (
    <section className='corner-exit-m bg-card space-y-4 border p-5'>
      <h2 className='text-lg font-semibold'>{title}</h2>
      {children}
    </section>
  )
}

const minutes = (value: number | null) => (value === null ? '—' : `${value} min`)

function UserProfile({ userId }: { userId: string }) {
  const { data: user } = useSuspenseQuery(userQuery(userId))
  return (
    <div className='space-y-6'>
      <header className='space-y-3'>
        <div className='flex flex-wrap items-center gap-2'>
          <h1 className='text-3xl font-semibold'>{fullName(user)}</h1>
          {!user.isActive && <StatusBadge>Bloqueada</StatusBadge>}
          {user.roles.map((role) => (
            <StatusBadge key={role} active={role !== 'CUSTOMER'}>
              {ROLE_LABEL[role]}
            </StatusBadge>
          ))}
        </div>
        <p className='text-muted-foreground text-sm tabular-nums'>
          {user.phone}
          {user.email && ` · ${user.email}`} · Cuenta desde {dateTime.formatDate(user.createdAt)}
        </p>
        <UserActions user={user} />
      </header>

      <div className='grid grid-cols-2 gap-3 lg:grid-cols-4'>
        <StatTile
          label='Pedidos'
          value={user.stats.orders}
          hint={`${user.stats.delivered} entregados · ${user.stats.cancelled} cancelados`}
        />
        <StatTile
          label='Gastó'
          value={formatMoney(user.stats.spent)}
          hint='En pedidos entregados'
        />
        <StatTile
          label='Ticket promedio'
          value={user.stats.delivered ? formatMoney(user.stats.avgTicket) : '—'}
        />
        <StatTile
          label='Sesiones abiertas'
          value={user.activeSessions}
          hint={`${user.devices.length} ${user.devices.length === 1 ? 'teléfono' : 'teléfonos'} con avisos · ${user.addresses} direcciones`}
        />
      </div>

      <PartnerSection user={user} />

      <div className='grid gap-5 lg:grid-cols-2'>
        <Card title='Últimos pedidos'>
          {user.recentOrders.length === 0 ? (
            <p className='text-muted-foreground text-sm'>Aún no ha pedido.</p>
          ) : (
            <ul className='divide-y text-sm'>
              {user.recentOrders.map((order) => (
                <li key={order.id} className='flex items-baseline gap-3 py-2'>
                  <span className='font-mono font-semibold'>{order.code}</span>
                  <span className='min-w-0 flex-1 truncate'>{order.storeName}</span>
                  <StatusBadge active={order.status === 'DELIVERED'}>
                    {ORDER_STATUS_LABEL[order.status] ?? order.status}
                  </StatusBadge>
                  <span className='text-muted-foreground'>
                    {dateTime.formatRelative(order.createdAt)}
                  </span>
                  <span className='tabular-nums'>{formatMoney(order.total)}</span>
                </li>
              ))}
            </ul>
          )}
        </Card>
        <Card title='Historial de cambios'>
          {user.history.length === 0 ? (
            <p className='text-muted-foreground text-sm'>
              Nadie del equipo ha cambiado esta cuenta.
            </p>
          ) : (
            <ol className='space-y-3 text-sm'>
              {user.history.map((entry) => (
                <li key={entry.id}>
                  <p className='font-semibold'>{ACTION_LABEL[entry.action]}</p>
                  <p className='text-muted-foreground'>
                    {dateTime.formatDateTime(entry.createdAt)}
                    {entry.by && ` · ${entry.by}`}
                    {typeof entry.details?.reason === 'string' && ` · "${entry.details.reason}"`}
                  </p>
                </li>
              ))}
            </ol>
          )}
        </Card>
      </div>
    </div>
  )
}

function PartnerSection({ user }: { user: UserDetail }) {
  const { merchant, courier, days } = user.performance
  if (!merchant && !courier) return null
  return (
    <div className='grid gap-5 lg:grid-cols-2'>
      {merchant && (
        <Card title={`Como negocio · últimos ${days} días`}>
          <p className='text-muted-foreground text-sm'>
            {user.stores
              .map((store) => `${store.name}${store.isAcceptingOrders ? '' : ' (en pausa)'}`)
              .join(' · ')}
          </p>
          <div className='grid grid-cols-2 gap-3'>
            <StatTile
              label='Aceptó'
              value={merchant.acceptRate === null ? '—' : `${merchant.acceptRate} %`}
              hint={`${merchant.accepted} de ${merchant.received} pedidos`}
            />
            <StatTile
              label='Responde en'
              value={minutes(merchant.responseMinutes)}
              hint='Mediana'
            />
            <StatTile label='Rechazó' value={merchant.rejected} />
            <StatTile
              label='Sin responder'
              value={merchant.unanswered}
              hint='Cancelados a los 8 min'
            />
          </div>
        </Card>
      )}
      {courier && user.courier && (
        <Card title={`Como repartidor · últimos ${days} días`}>
          <p className='text-muted-foreground text-sm'>
            {user.courier.vehicleLabel}
            {user.courier.plate && ` · ${user.courier.plate}`}
          </p>
          <div className='grid grid-cols-2 gap-3'>
            <StatTile label='Entregas' value={courier.deliveries} />
            <StatTile
              label='Tarda'
              value={minutes(courier.deliveryMinutes)}
              hint='De listo a entregado'
            />
            <StatTile label='Cobró' value={formatMoney(courier.collected)} hint='Contraentrega' />
          </div>
        </Card>
      )}
    </div>
  )
}

function UserDetailSkeleton() {
  return (
    <div role='status' aria-label='Cargando cuenta' className='space-y-6'>
      <Skeleton className='h-10 w-72' />
      <Skeleton className='h-5 w-96' />
      <div className='grid grid-cols-2 gap-3 lg:grid-cols-4'>
        {[0, 1, 2, 3].map((index) => (
          <Skeleton key={index} className='h-20 w-full' />
        ))}
      </div>
      <div className='grid gap-5 lg:grid-cols-2'>
        <Skeleton className='h-56 w-full' />
        <Skeleton className='h-56 w-full' />
      </div>
    </div>
  )
}
