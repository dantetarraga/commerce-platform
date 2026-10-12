import { ChevronLeft, ChevronRight } from 'lucide-react'
import { Button } from '@/components/ui/button'
import { dateTime } from '@/lib/datetime'

export interface WeekRange {
  start: string
  end: string
  previous: string
  next: string
  current: boolean
}

/** Semana de lunes a domingo con flechas; no deja pasar de la semana en curso. */
export function WeekNav({ week, onChange }: { week: WeekRange; onChange: (week: string) => void }) {
  return (
    <div className='flex flex-wrap items-center gap-2' role='group' aria-label='Semana'>
      <Button
        type='button'
        variant='outline'
        size='sm'
        aria-label='Semana anterior'
        onClick={() => onChange(week.previous)}
      >
        <ChevronLeft className='size-4' aria-hidden />
      </Button>
      <p className='min-w-44 text-center text-sm font-semibold tabular-nums' aria-live='polite'>
        {dateTime.formatApiDay(week.start)} – {dateTime.formatApiDay(week.end)}
        <span className='text-muted-foreground block text-xs font-normal'>
          {week.current
            ? 'Semana en curso'
            : `Semana del ${dateTime.formatDate(`${week.start}T12:00:00`)}`}
        </span>
      </p>
      <Button
        type='button'
        variant='outline'
        size='sm'
        aria-label='Semana siguiente'
        disabled={week.current}
        onClick={() => onChange(week.next)}
      >
        <ChevronRight className='size-4' aria-hidden />
      </Button>
      {!week.current && (
        <Button
          type='button'
          variant='ghost'
          size='sm'
          onClick={() => onChange(dateTime.toApiDate())}
        >
          Esta semana
        </Button>
      )}
    </div>
  )
}
