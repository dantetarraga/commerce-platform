/// <reference types="node" />
import { readFileSync } from 'node:fs'
import path from 'node:path'
import { legalDocuments, legalHref } from './legal'

const mobileLegal = path.resolve(import.meta.dirname, '../../../../../mobile/assets/legal')
const normalize = (text: string) => text.replace(/\r\n/g, '\n')

describe('textos legales', () => {
  it.each(Object.values(legalDocuments))('$slug es igual al de las apps', ({ slug, markdown }) => {
    const source = readFileSync(path.join(mobileLegal, `${slug}.md`), 'utf8')
    expect(normalize(markdown)).toBe(normalize(source))
  })

  it('traduce los enlaces entre textos', () => {
    expect(legalHref('apamuy:privacidad')).toBe('/privacy')
    expect(legalHref('apamuy:otro')).toBeUndefined()
    expect(legalHref('https://apamuy.pe')).toBeUndefined()
  })
})
