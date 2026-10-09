import { MessageCircle, Smartphone } from 'lucide-react'
import type { ReactNode } from 'react'
import { Button } from '@/components/ui/button'
import { supportWhatsappUrl } from '@/lib/contact'
import { SiteFooter } from '../components/site-footer'
import { SiteHeader } from '../components/site-header'

function Section({ title, children }: { title: string; children: ReactNode }) {
  return (
    <section className='space-y-3'>
      <h2 className='text-2xl font-semibold'>{title}</h2>
      <div className='text-muted-foreground space-y-3'>{children}</div>
    </section>
  )
}

/**
 * Página pública para pedir la eliminación de la cuenta. Google Play exige una URL
 * así para las apps con registro, además de la opción dentro de la app.
 */
export function AccountDeletionPage() {
  const whatsapp = supportWhatsappUrl('Hola, quiero eliminar mi cuenta de Apamuy.')
  return (
    <div className='min-h-svh'>
      <SiteHeader />
      <main className='mx-auto max-w-3xl space-y-10 px-4 py-16 sm:px-6'>
        <header className='space-y-3'>
          <p className='text-primary text-xs font-bold tracking-widest uppercase'>Tu cuenta</p>
          <h1 className='text-4xl font-semibold md:text-5xl'>Eliminar tu cuenta de Apamuy</h1>
          <p className='text-muted-foreground text-lg'>
            Puedes eliminarla tú mismo desde la app, en un minuto. Si ya no tienes la app,
            escríbenos y lo hacemos por ti.
          </p>
        </header>

        <Section title='Desde la app Apamuy'>
          <ol className='list-inside list-decimal space-y-2'>
            <li>Abre la app e ingresa con tu celular.</li>
            <li>
              Ve a la pestaña <strong className='text-foreground'>Tú</strong>.
            </li>
            <li>
              Al final, toca <strong className='text-foreground'>Eliminar mi cuenta</strong> y
              confirma.
            </li>
          </ol>
          <p className='flex items-start gap-2'>
            <Smartphone className='text-primary mt-1 size-4 shrink-0' aria-hidden />
            Si tienes un pedido en curso, podrás eliminarla cuando termine.
          </p>
        </Section>

        <Section title='Qué borramos y qué guardamos'>
          <p>
            <strong className='text-foreground'>Borramos al instante:</strong> tu nombre, celular,
            correo, foto, direcciones guardadas, avisos y los teléfonos donde tenías la sesión
            abierta. Se cierra la sesión en todos ellos.
          </p>
          <p>
            <strong className='text-foreground'>Guardamos sin tus datos:</strong> los pedidos que ya
            hiciste (productos, montos y fechas), porque la ley nos pide conservarlos para la
            contabilidad. Ya no se pueden relacionar contigo.
          </p>
          <p>
            Si después vuelves a registrarte con el mismo celular, empiezas una cuenta nueva, sin tu
            historial anterior.
          </p>
        </Section>

        <Section title='Si eres un negocio o repartidor'>
          <p>
            Tu cuenta de Apamuy Socios está unida a tu negocio o a tus repartos, así que la damos de
            baja nosotros: cerramos tus pedidos pendientes y borramos tus datos personales.
            Escríbenos y lo hacemos en un máximo de 7 días.
          </p>
        </Section>

        {whatsapp && (
          <div className='corner-exit-m bg-card flex flex-wrap items-center justify-between gap-4 border p-6'>
            <div>
              <p className='font-semibold'>¿No tienes la app o eres socio?</p>
              <p className='text-muted-foreground text-sm'>
                Escríbenos desde el celular de tu cuenta.
              </p>
            </div>
            <Button asChild size='lg'>
              <a href={whatsapp} target='_blank' rel='noreferrer'>
                <MessageCircle aria-hidden />
                Pedir por WhatsApp
              </a>
            </Button>
          </div>
        )}
      </main>
      <SiteFooter />
    </div>
  )
}
