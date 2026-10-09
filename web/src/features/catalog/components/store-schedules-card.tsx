import { useState } from 'react'
import { Button } from '@/components/ui/button'
import { minutesToTime, WEEK_DAYS, type StoreDetail } from '../model/catalog'
import { ScheduleFormDialog } from './schedule-form'

/** Turnos de atención del negocio, con su editor. */
export function StoreSchedulesCard({ store }: { store: StoreDetail }) {
  const [editing, setEditing] = useState(false)
  return (
    <>
      <section className='corner-exit-m bg-card space-y-4 border p-5'>
        <div className='flex items-center justify-between gap-3'>
          <h2 className='text-xl font-semibold'>Horarios</h2>
          <Button variant='outline' size='sm' onClick={() => setEditing(true)}>
            Editar horarios
          </Button>
        </div>
        {store.schedules.length ? (
          <ul className='space-y-2 text-sm'>
            {store.schedules.map((schedule, index) => (
              <li key={index} className='flex flex-wrap justify-between gap-2'>
                <span>{WEEK_DAYS[schedule.dayOfWeek]}</span>
                <span className='text-muted-foreground tabular-nums'>
                  {minutesToTime(schedule.opensAt)} – {minutesToTime(schedule.closesAt)}
                  {schedule.closesAt < schedule.opensAt ? ' (+1 día)' : ''}
                </span>
              </li>
            ))}
          </ul>
        ) : (
          <p className='text-muted-foreground text-sm'>
            Sin turnos. Añade horarios para que el negocio aparezca abierto.
          </p>
        )}
      </section>
      {editing && <ScheduleFormDialog store={store} onClose={() => setEditing(false)} />}
    </>
  )
}
