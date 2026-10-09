import { TextField } from '@/components/shared/form-controls'
import { Button } from '@/components/ui/button'
import { lastDays, type DateRange } from '../model/partner'

const PRESETS = [
  { days: 7, label: '7 días' },
  { days: 30, label: '30 días' },
  { days: 90, label: '90 días' },
] as const

interface RangePickerProps {
  value: DateRange
  onChange: (range: DateRange) => void
}

/** Atajos de 7, 30 y 90 días, o un rango a mano (máximo 92 días, lo valida la API). */
export function RangePicker({ value, onChange }: RangePickerProps) {
  return (
    <div className='flex flex-wrap items-end gap-3'>
      <div className='flex gap-1' role='group' aria-label='Periodo'>
        {PRESETS.map((preset) => {
          const range = lastDays(preset.days)
          const active = range.from === value.from && range.to === value.to
          return (
            <Button
              key={preset.days}
              type='button'
              className='h-11 rounded-md'
              variant={active ? 'default' : 'outline'}
              aria-pressed={active}
              onClick={() => onChange(range)}
            >
              {preset.label}
            </Button>
          )
        })}
      </div>
      <div className='w-40'>
        <TextField
          label='Desde'
          type='date'
          value={value.from}
          max={value.to}
          onChange={(event) =>
            event.target.value && onChange({ ...value, from: event.target.value })
          }
        />
      </div>
      <div className='w-40'>
        <TextField
          label='Hasta'
          type='date'
          value={value.to}
          min={value.from}
          onChange={(event) => event.target.value && onChange({ ...value, to: event.target.value })}
        />
      </div>
    </div>
  )
}
