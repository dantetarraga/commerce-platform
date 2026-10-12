/** Puntos básicos (1000 = 10 %) a texto con el separador de es-PE: `10 %`, `12.5 %`. */
export function formatRate(bps: number): string {
  return `${(bps / 100).toLocaleString('es-PE', { maximumFractionDigits: 2 })} %`
}

/** Lo que escribe una persona (`12,5`) a puntos básicos, de 0 a 100 %. */
export function parsePercent(input: string): number | null {
  const normalized = input.trim().replace('%', '').trim().replace(',', '.')
  if (!/^\d{1,3}(\.\d{1,2})?$/.test(normalized)) return null
  const bps = Math.round(Number(normalized) * 100)
  return bps <= 10_000 ? bps : null
}
