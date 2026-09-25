import { AppException } from '../../common/exceptions/app.exception';
import { orderTotals, PricedProduct, priceItem } from './order-pricing';

const cuarto: PricedProduct = {
  id: 'pr_pollo_cuarto',
  name: '1/4 de pollo',
  basePrice: 1800,
  isAvailable: true,
  stock: null,
  variants: [
    { id: 'pierna', name: 'Pierna', price: 1800, isAvailable: true },
    { id: 'pecho', name: 'Pecho', price: 1900, isAvailable: true },
  ],
  options: [
    {
      id: 'extras',
      name: 'Agrega un extra',
      minSelect: 0,
      maxSelect: 2,
      values: [
        { id: 'huevo', name: 'Huevo frito', priceDelta: 200, isAvailable: true },
        { id: 'platano', name: 'Plátano frito', priceDelta: 300, isAvailable: false },
      ],
    },
  ],
};

const inca: PricedProduct = { ...cuarto, id: 'inca', name: 'Inca Kola', basePrice: 900, variants: [], options: [] };

function codeOf(fn: () => unknown) {
  try {
    fn();
  } catch (e) {
    return (e as AppException).code;
  }
  throw new Error('no lanzó');
}

describe('priceItem', () => {
  it('precio = variante + opciones elegidas', () => {
    expect(priceItem(cuarto, { variantId: 'pecho', optionValueIds: ['huevo'] })).toEqual({
      unitPrice: 2100,
      variantId: 'pecho',
      variantName: 'Pecho',
      options: [{ optionValueId: 'huevo', optionName: 'Agrega un extra', valueName: 'Huevo frito', priceDelta: 200 }],
    });
  });

  it('sin variantes usa el precio base', () => {
    expect(priceItem(inca, { optionValueIds: [] }).unitPrice).toBe(900);
  });

  it.each([
    ['falta la variante obligatoria', cuarto, { optionValueIds: [] }],
    ['variante de otro producto', cuarto, { variantId: 'otra', optionValueIds: [] }],
    ['variante en un producto sin variantes', inca, { variantId: 'pecho', optionValueIds: [] }],
    ['opción que no es del producto', cuarto, { variantId: 'pecho', optionValueIds: ['queso'] }],
    ['opción repetida', cuarto, { variantId: 'pecho', optionValueIds: ['huevo', 'huevo'] }],
  ])('%s → INVALID_PRODUCT_OPTIONS', (_label, product, selection) => {
    expect(codeOf(() => priceItem(product, selection))).toBe('INVALID_PRODUCT_OPTIONS');
  });

  it('respeta el mínimo y el máximo del grupo', () => {
    const required: PricedProduct = { ...cuarto, options: [{ ...cuarto.options[0], minSelect: 1, maxSelect: 1 }] };
    expect(codeOf(() => priceItem(required, { variantId: 'pecho', optionValueIds: [] }))).toBe(
      'INVALID_PRODUCT_OPTIONS',
    );
    const withTwo = { ...required, options: [{ ...required.options[0], values: [...cuarto.options[0].values] }] };
    withTwo.options[0].values[1] = { ...withTwo.options[0].values[1], isAvailable: true };
    expect(codeOf(() => priceItem(withTwo, { variantId: 'pecho', optionValueIds: ['huevo', 'platano'] }))).toBe(
      'INVALID_PRODUCT_OPTIONS',
    );
  });

  it('una opción agotada → PRODUCT_UNAVAILABLE', () => {
    expect(codeOf(() => priceItem(cuarto, { variantId: 'pecho', optionValueIds: ['platano'] }))).toBe(
      'PRODUCT_UNAVAILABLE',
    );
  });
});

describe('orderTotals', () => {
  it('total = subtotal + delivery − descuento + propina', () => {
    expect(orderTotals({ subtotal: 4200, deliveryFee: 350, discount: 300, tip: 200 }).total).toBe(4450);
  });

  it('el IGV incluido no cuenta la propina', () => {
    // 4250 con IGV → base 3602 → IGV 648.
    expect(orderTotals({ subtotal: 4200, deliveryFee: 350, discount: 300, tip: 200 }).tax).toBe(648);
  });
});
