import { useState } from 'react'
import { PageHeader } from '@/components/shared/page-header'
import { QueryBoundary } from '@/components/shared/query-boundary'
import { Button } from '@/components/ui/button'
import { CitiesList } from '../components/cities-list'
import { CitiesSkeleton } from '../components/cities-skeleton'
import { CityFormDialog } from '../components/city-form'
import type { AdminCity } from '../model/city'

export function CitiesPage() {
  const [editor, setEditor] = useState<{ city?: AdminCity } | null>(null)
  return (
    <div className='space-y-8'>
      <PageHeader
        eyebrow='Administración'
        title='Ciudades'
        description='Zona de reparto, tarifas y tiempos de cada ciudad.'
        actions={<Button onClick={() => setEditor({})}>Nueva ciudad</Button>}
      />
      <QueryBoundary fallback={<CitiesSkeleton />}>
        <CitiesList onEdit={(city) => setEditor({ city })} />
      </QueryBoundary>
      {editor && <CityFormDialog city={editor.city} onClose={() => setEditor(null)} />}
    </div>
  )
}
