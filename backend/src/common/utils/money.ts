/** Dinero en la API: céntimos enteros + moneda. Nunca `float`. */
export interface Money {
  amount: number;
  currency: string;
}

export const DEFAULT_CURRENCY = 'PEN';

export function money(amount: number, currency = DEFAULT_CURRENCY): Money {
  return { amount, currency };
}
