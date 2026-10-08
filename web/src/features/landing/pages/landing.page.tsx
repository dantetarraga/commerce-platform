import { ForPartners } from '../components/for-partners'
import { Hero } from '../components/hero'
import { HowItWorks } from '../components/how-it-works'
import { SiteFooter } from '../components/site-footer'
import { SiteHeader } from '../components/site-header'

/** La portada pública de Apamuy: clientes, negocios y repartidores. */
export function LandingPage() {
  return (
    <div className='min-h-svh'>
      <SiteHeader />
      <main>
        <Hero />
        <HowItWorks />
        <ForPartners />
      </main>
      <SiteFooter />
    </div>
  )
}
