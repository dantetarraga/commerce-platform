export interface Money {
  amount: number
  currency: string
}

const formatters = new Map<string, Intl.NumberFormat>()

function formatterFor(currency: string) {
  let formatter = formatters.get(currency)
  if (!formatter) {
    formatter = new Intl.NumberFormat('es-PE', {
      style: 'currency',
      currency,
      minimumFractionDigits: 2,
    })
    formatters.set(currency, formatter)
  }
  return formatter
}

/** `{ amount: 13850, currency: 'PEN' }` → `S/ 138.50`. */
export function formatMoney(money: Money): string {
  return formatterFor(money.currency)
    .format(money.amount / 100)
    .replace(/\u00a0/g, ' ')
}

export function parseSoles(input: string): number | null {
  const normalized = input.trim().replace(',', '.')
  if (!/^\d+(\.\d{1,2})?$/.test(normalized)) return null
  return Math.round(Number(normalized) * 100)
}
