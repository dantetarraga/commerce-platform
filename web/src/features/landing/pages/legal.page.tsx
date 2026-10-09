import { Link } from '@tanstack/react-router'
import Markdown, { defaultUrlTransform, type Components } from 'react-markdown'
import remarkGfm from 'remark-gfm'
import { legalDocuments, legalHref, type LegalDocumentKey } from '../content/legal'
import { SiteFooter } from '../components/site-footer'
import { SiteHeader } from '../components/site-header'

const components: Components = {
  h1: ({ children }) => <h1 className='text-4xl font-semibold md:text-5xl'>{children}</h1>,
  h2: ({ children }) => <h2 className='pt-4 text-2xl font-semibold'>{children}</h2>,
  p: ({ children }) => <p className='text-muted-foreground leading-relaxed'>{children}</p>,
  ul: ({ children }) => (
    <ul className='text-muted-foreground list-disc space-y-2 pl-5 leading-relaxed'>{children}</ul>
  ),
  strong: ({ children }) => <strong className='text-foreground font-semibold'>{children}</strong>,
  blockquote: ({ children }) => (
    <blockquote className='corner-exit-s bg-primary-soft border-primary border-l-4 px-4 py-3'>
      {children}
    </blockquote>
  ),
  table: ({ children }) => (
    <div className='overflow-x-auto border'>
      <table className='w-full min-w-xl text-left text-sm'>{children}</table>
    </div>
  ),
  th: ({ children }) => <th className='bg-secondary px-3 py-2 font-semibold'>{children}</th>,
  td: ({ children }) => (
    <td className='text-muted-foreground border-t px-3 py-2 align-top'>{children}</td>
  ),
  a: ({ href = '', children }) =>
    href.startsWith('/') ? (
      <Link to={href} className='text-primary font-semibold underline-offset-4 hover:underline'>
        {children}
      </Link>
    ) : (
      <a
        href={href}
        className='text-primary font-semibold underline-offset-4 hover:underline'
        target='_blank'
        rel='noreferrer'
      >
        {children}
      </a>
    ),
}

const urlTransform = (url: string) => legalHref(url) ?? defaultUrlTransform(url)

/** Términos o privacidad: el mismo texto que muestran las apps, para enlazarlo desde Google Play. */
export function LegalPage({ document }: { document: LegalDocumentKey }) {
  return (
    <div className='min-h-svh'>
      <SiteHeader />
      <main className='mx-auto max-w-3xl space-y-5 px-4 py-16 sm:px-6'>
        <Markdown remarkPlugins={[remarkGfm]} components={components} urlTransform={urlTransform}>
          {legalDocuments[document].markdown}
        </Markdown>
      </main>
      <SiteFooter />
    </div>
  )
}

export const PrivacyPage = () => <LegalPage document='privacy' />
export const TermsPage = () => <LegalPage document='terms' />
