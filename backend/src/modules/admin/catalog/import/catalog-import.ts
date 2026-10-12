/**
 * Carga masiva de la carta desde un Excel o CSV. El panel lee el archivo y manda las
 * celdas como texto; aquí se interpretan y se cruzan con la carta actual. Un producto
 * se reconoce por su nombre (sin mayúsculas ni tildes): si ya existe se actualiza, si no
 * se crea. Una celda vacía deja el dato como está.
 */

export const MAX_IMPORT_ROWS = 500;

export interface ImportRow {
  /** Fila del archivo, para los mensajes. */
  line: number;
  section?: string;
  name?: string;
  description?: string;
  price?: string;
  stock?: string;
  available?: string;
  imageUrl?: string;
}

export interface ExistingProduct {
  id: string;
  name: string;
  description: string | null;
  imageUrl: string | null;
  basePrice: number;
  stock: number | null;
  isAvailable: boolean;
  menuSectionId: string | null;
  hasVariants: boolean;
}

export interface ExistingSection {
  id: string;
  name: string;
}

/** Sección por id si ya existe; por nombre si se crea con la importación. */
export type SectionRef = { id: string } | { newName: string };

export interface ProductChanges {
  name?: string;
  description?: string | null;
  imageUrl?: string | null;
  basePrice?: number;
  stock?: number | null;
  isAvailable?: boolean;
  section?: SectionRef | null;
}

export type NewProduct = ProductChanges & { name: string; basePrice: number };

export type RowAction = 'create' | 'update' | 'unchanged' | 'error';

export type ChangedField = 'name' | 'description' | 'imageUrl' | 'price' | 'stock' | 'available' | 'section';

export interface RowResult {
  line: number;
  name: string;
  action: RowAction;
  errors: string[];
  warnings: string[];
  /** Lo que cambia en un producto que ya existe. */
  changes?: ChangedField[];
  /** En céntimos; `from` es nulo en un producto nuevo. */
  price?: { from: number | null; to: number };
}

export interface ImportPlan {
  rows: RowResult[];
  sectionsToCreate: string[];
  creates: NewProduct[];
  updates: { id: string; changes: ProductChanges }[];
}

/** "Pollo a la Brasa " → "pollo a la brasa"; "Café" y "cafe" son el mismo producto. */
export const matchKey = (value: string) =>
  value
    .normalize('NFD')
    .replace(/[\u0300-\u036f]/g, '')
    .toLowerCase()
    .replace(/\s+/g, ' ')
    .trim();

const clean = (value: string | undefined) => value?.replace(/\s+/g, ' ').trim() ?? '';

/** "12.50", "12,50", "S/ 12.5" o "S/.12" → céntimos. */
export function parsePrice(value: string): number | null {
  const text = value
    .replace(/^s\/\.?/i, '')
    .replace(/\s/g, '')
    .replace(',', '.');
  if (!/^\d{1,6}(\.\d{1,2})?$/.test(text)) return null;
  return Math.round(Number(text) * 100);
}

const YES = new Set(['si', 's', 'x', '1', 'true', 'yes', 'disponible']);
const NO = new Set(['no', 'n', '0', 'false', 'agotado', 'no disponible']);

export function parseAvailable(value: string): boolean | null {
  const text = matchKey(value);
  if (YES.has(text)) return true;
  if (NO.has(text)) return false;
  return null;
}

function parseRow(row: ImportRow) {
  const errors: string[] = [];
  const name = clean(row.name);
  if (!name) errors.push('Falta el nombre.');
  else if (name.length < 2 || name.length > 80) errors.push('El nombre debe tener entre 2 y 80 caracteres.');

  const priceText = clean(row.price);
  const price = priceText ? parsePrice(priceText) : undefined;
  if (price === null) errors.push(`Precio no válido: «${priceText}». Usa números como 12.50.`);
  else if (price === 0) errors.push('El precio debe ser mayor que cero.');

  const stockText = clean(row.stock);
  let stock: number | null | undefined;
  if (stockText) {
    if (/^\d{1,9}$/.test(stockText)) stock = Number(stockText);
    else if (matchKey(stockText) === 'sin limite') stock = null;
    else errors.push(`Stock no válido: «${stockText}». Usa un número entero o «sin límite».`);
  }

  const availableText = clean(row.available);
  const available = availableText ? parseAvailable(availableText) : undefined;
  if (available === null) errors.push(`Disponible no válido: «${availableText}». Usa «sí» o «no».`);

  const description = clean(row.description);
  if (description.length > 500) errors.push('La descripción supera los 500 caracteres.');

  const section = clean(row.section);
  if (section.length > 60) errors.push('El nombre de la sección supera los 60 caracteres.');

  const imageUrl = clean(row.imageUrl);
  if (imageUrl && !/^https:\/\/\S+$/.test(imageUrl)) errors.push('La foto debe ser una URL que empiece con https://.');

  return {
    errors,
    name,
    description: description || undefined,
    section: section || undefined,
    imageUrl: imageUrl || undefined,
    price: price ?? undefined,
    stock,
    available: available ?? undefined,
  };
}

const CHANGED_FIELDS: Record<keyof ProductChanges, ChangedField> = {
  name: 'name',
  description: 'description',
  imageUrl: 'imageUrl',
  basePrice: 'price',
  stock: 'stock',
  isAvailable: 'available',
  section: 'section',
};

export function planImport(
  rows: readonly ImportRow[],
  existing: { products: readonly ExistingProduct[]; sections: readonly ExistingSection[] },
): ImportPlan {
  const products = new Map(existing.products.map((p) => [matchKey(p.name), p]));
  const sections = new Map(existing.sections.map((s) => [matchKey(s.name), s]));
  const newSections = new Map<string, string>();
  const seen = new Map<string, number>();
  const plan: ImportPlan = { rows: [], sectionsToCreate: [], creates: [], updates: [] };

  for (const row of rows) {
    const parsed = parseRow(row);
    const key = matchKey(parsed.name);
    const result: RowResult = {
      line: row.line,
      name: parsed.name,
      action: 'error',
      errors: parsed.errors,
      warnings: [],
    };
    plan.rows.push(result);

    if (key) {
      const previous = seen.get(key);
      if (previous !== undefined) result.errors.push(`Este producto ya está en la fila ${previous}.`);
      else seen.set(key, row.line);
    }
    const current = key ? products.get(key) : undefined;
    if (result.errors.length) continue;
    if (!current && parsed.price === undefined) {
      result.errors.push('Falta el precio: es un producto nuevo.');
      continue;
    }

    let section: SectionRef | undefined;
    if (parsed.section) {
      const sectionKey = matchKey(parsed.section);
      const found = sections.get(sectionKey);
      if (found) section = { id: found.id };
      else {
        if (!newSections.has(sectionKey)) newSections.set(sectionKey, parsed.section);
        section = { newName: newSections.get(sectionKey)! };
      }
    }

    if (!current) {
      result.action = 'create';
      result.price = { from: null, to: parsed.price! };
      plan.creates.push({
        name: parsed.name,
        description: parsed.description ?? null,
        imageUrl: parsed.imageUrl ?? null,
        basePrice: parsed.price!,
        stock: parsed.stock ?? null,
        isAvailable: parsed.available ?? true,
        section: section ?? null,
      });
      continue;
    }

    const changes: ProductChanges = {};
    if (parsed.name !== current.name) changes.name = parsed.name;
    if (parsed.description !== undefined && parsed.description !== current.description) {
      changes.description = parsed.description;
    }
    if (parsed.imageUrl !== undefined && parsed.imageUrl !== current.imageUrl) changes.imageUrl = parsed.imageUrl;
    if (parsed.stock !== undefined && parsed.stock !== current.stock) changes.stock = parsed.stock;
    if (parsed.available !== undefined && parsed.available !== current.isAvailable) {
      changes.isAvailable = parsed.available;
    }
    if (section && !('id' in section && section.id === current.menuSectionId)) changes.section = section;
    if (parsed.price !== undefined && parsed.price !== current.basePrice) {
      if (current.hasVariants) result.warnings.push('Tiene variantes: el precio se cambia en cada variante.');
      else changes.basePrice = parsed.price;
    }

    if (Object.keys(changes).length === 0) {
      result.action = 'unchanged';
    } else {
      result.action = 'update';
      result.changes = Object.keys(changes).map((key) => CHANGED_FIELDS[key as keyof ProductChanges]);
      if (changes.basePrice !== undefined) result.price = { from: current.basePrice, to: changes.basePrice };
      plan.updates.push({ id: current.id, changes });
    }
  }

  plan.sectionsToCreate = [...newSections.values()];
  return plan;
}

/** Lo que ve el panel: el detalle por fila y los totales. */
export function importSummary(plan: ImportPlan) {
  const count = (action: RowAction) => plan.rows.filter((r) => r.action === action).length;
  return {
    created: count('create'),
    updated: count('update'),
    unchanged: count('unchanged'),
    failed: count('error'),
    sectionsCreated: plan.sectionsToCreate,
    rows: plan.rows,
  };
}
