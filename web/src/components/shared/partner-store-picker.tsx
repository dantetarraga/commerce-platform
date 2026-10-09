import { usePartnerStore } from '@/hooks/use-partner-store'
import { SelectField } from './form-controls'

/** Selector del negocio para quien tiene más de uno. Suspende mientras carga. */
export function PartnerStorePicker() {
  const { stores, store, select } = usePartnerStore()
  if (stores.length < 2 || !store) return null
  return (
    <div className='w-60'>
      <SelectField
        label='Negocio'
        value={store.id}
        onChange={(event) => select(event.target.value)}
      >
        {stores.map((item) => (
          <option key={item.id} value={item.id}>
            {item.name}
          </option>
        ))}
      </SelectField>
    </div>
  )
}
