import { matchKey, parseAvailable, parsePrice, planImport, type ExistingProduct } from './catalog-import';

const product = (overrides: Partial<ExistingProduct> = {}): ExistingProduct => ({
  id: 'p1',
  name: 'Pollo a la brasa',
  description: null,
  imageUrl: null,
  basePrice: 6000,
  stock: null,
  isAvailable: true,
  menuSectionId: 's1',
  hasVariants: false,
  ...overrides,
});
const existing = { products: [product()], sections: [{ id: 's1', name: 'Pollos' }] };

describe('parsePrice', () => {
  it('acepta punto, coma y el símbolo de soles', () => {
    expect(parsePrice('12.50')).toBe(1250);
    expect(parsePrice('12,5')).toBe(1250);
    expect(parsePrice('S/ 8')).toBe(800);
    expect(parsePrice('S/.0.90')).toBe(90);
  });

  it('rechaza texto y más de dos decimales', () => {
    expect(parsePrice('doce')).toBeNull();
    expect(parsePrice('1.234')).toBeNull();
    expect(parsePrice('-5')).toBeNull();
  });
});

describe('parseAvailable y matchKey', () => {
  it('entiende sí/no con o sin tilde', () => {
    expect(parseAvailable('Sí')).toBe(true);
    expect(parseAvailable('x')).toBe(true);
    expect(parseAvailable('NO')).toBe(false);
    expect(parseAvailable('quizás')).toBeNull();
  });

  it('ignora mayúsculas, tildes y espacios de más', () => {
    expect(matchKey('  Café   con LECHE ')).toBe('cafe con leche');
  });
});

describe('planImport', () => {
  it('crea lo nuevo y la sección que falta, una sola vez', () => {
    const plan = planImport(
      [
        { line: 2, name: 'Chicha morada', price: '3', section: 'Bebidas' },
        { line: 3, name: 'Inca Kola 500 ml', price: '3.5', section: 'bebidas', stock: '20' },
      ],
      existing,
    );
    expect(plan.sectionsToCreate).toEqual(['Bebidas']);
    expect(plan.creates).toEqual([
      expect.objectContaining({ name: 'Chicha morada', basePrice: 300, stock: null, isAvailable: true }),
      expect.objectContaining({ name: 'Inca Kola 500 ml', basePrice: 350, stock: 20, section: { newName: 'Bebidas' } }),
    ]);
    expect(plan.rows.map((r) => r.action)).toEqual(['create', 'create']);
    expect(plan.rows[0].price).toEqual({ from: null, to: 300 });
  });

  it('reconoce el producto por su nombre y solo cambia lo que viene', () => {
    const plan = planImport([{ line: 2, name: 'POLLO A LA BRASA', price: '65', available: 'no' }], existing);
    expect(plan.updates).toEqual([
      { id: 'p1', changes: { name: 'POLLO A LA BRASA', basePrice: 6500, isAvailable: false } },
    ]);
    // La revisión muestra qué cambia y el precio de antes.
    expect(plan.rows[0]).toMatchObject({ changes: ['name', 'available', 'price'], price: { from: 6000, to: 6500 } });
  });

  it('sin cambios no toca el producto', () => {
    const plan = planImport([{ line: 2, name: 'Pollo a la brasa', price: '60.00', section: 'pollos' }], existing);
    expect(plan.rows[0].action).toBe('unchanged');
    expect(plan.updates).toEqual([]);
  });

  it('con variantes, el precio se ignora con un aviso', () => {
    const plan = planImport([{ line: 2, name: 'Pollo a la brasa', price: '70' }], {
      ...existing,
      products: [product({ hasVariants: true })],
    });
    expect(plan.rows[0]).toMatchObject({ action: 'unchanged', warnings: [expect.stringMatching(/variantes/)] });
    expect(plan.rows[0].price).toBeUndefined();
  });

  it('marca cada error con su fila y no lo incluye en el plan', () => {
    const plan = planImport(
      [
        { line: 2, name: '', price: '5' },
        { line: 3, name: 'Caldo de gallina', price: 'barato' },
        { line: 4, name: 'Caldo de gallina nuevo' },
        { line: 5, name: 'Té', price: '2' },
        { line: 6, name: 'te', price: '2' },
        { line: 7, name: 'Anticucho', price: '10', stock: 'muchos', imageUrl: 'http://x.pe/a.jpg' },
      ],
      existing,
    );
    expect(plan.rows.map((r) => [r.line, r.action])).toEqual([
      [2, 'error'],
      [3, 'error'],
      [4, 'error'],
      [5, 'create'],
      [6, 'error'],
      [7, 'error'],
    ]);
    expect(plan.rows[2].errors).toEqual(['Falta el precio: es un producto nuevo.']);
    expect(plan.rows[4].errors).toEqual(['Este producto ya está en la fila 5.']);
    expect(plan.rows[5].errors).toHaveLength(2);
    expect(plan.creates).toHaveLength(1);
  });
});
