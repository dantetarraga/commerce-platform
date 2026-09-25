import { HttpStatus } from '@nestjs/common';
import { AppException, ErrorCode } from '../../common/exceptions/app.exception';

// Precios del pedido como funciones puras: el backend recalcula todo a partir
// de IDs; lo que muestra la app es solo orientativo.

export interface PricedProduct {
  id: string;
  name: string;
  basePrice: number;
  isAvailable: boolean;
  stock: number | null;
  variants: { id: string; name: string; price: number; isAvailable: boolean }[];
  options: {
    id: string;
    name: string;
    minSelect: number;
    maxSelect: number;
    values: { id: string; name: string; priceDelta: number; isAvailable: boolean }[];
  }[];
}

export interface ItemSelection {
  variantId?: string | null;
  optionValueIds: string[];
}

export interface PricedItem {
  unitPrice: number;
  variantId: string | null;
  variantName: string | null;
  options: { optionValueId: string; optionName: string; valueName: string; priceDelta: number }[];
}

/**
 * Precio unitario = variante (o precio base) + opciones elegidas. Valida que
 * la variante y las opciones sean del producto, estén disponibles y cumplan
 * el mínimo y máximo de cada grupo.
 */
export function priceItem(product: PricedProduct, selection: ItemSelection): PricedItem {
  const invalid = () =>
    new AppException(
      ErrorCode.INVALID_PRODUCT_OPTIONS,
      HttpStatus.UNPROCESSABLE_ENTITY,
      `Revisa las opciones de ${product.name}.`,
      { productId: product.id },
    );

  let variant: PricedProduct['variants'][number] | undefined;
  if (product.variants.length > 0) {
    variant = product.variants.find((v) => v.id === selection.variantId);
    if (!variant) throw invalid();
    if (!variant.isAvailable) throw unavailable(product);
  } else if (selection.variantId) {
    throw invalid();
  }

  const chosen = new Set(selection.optionValueIds);
  if (chosen.size !== selection.optionValueIds.length) throw invalid();

  const options: PricedItem['options'] = [];
  for (const option of product.options) {
    const picked = option.values.filter((value) => chosen.has(value.id));
    if (picked.length < option.minSelect || picked.length > option.maxSelect) throw invalid();
    for (const value of picked) {
      if (!value.isAvailable) throw unavailable(product);
      options.push({
        optionValueId: value.id,
        optionName: option.name,
        valueName: value.name,
        priceDelta: value.priceDelta,
      });
      chosen.delete(value.id);
    }
  }
  // Algún ID no pertenece a ningún grupo de este producto.
  if (chosen.size > 0) throw invalid();

  return {
    unitPrice: (variant?.price ?? product.basePrice) + options.reduce((sum, o) => sum + o.priceDelta, 0),
    variantId: variant?.id ?? null,
    variantName: variant?.name ?? null,
    options,
  };
}

export function unavailable(product: { id: string; name: string }) {
  return new AppException(
    ErrorCode.PRODUCT_UNAVAILABLE,
    HttpStatus.CONFLICT,
    `${product.name} se agotó. Quítalo de tu bolsa para continuar.`,
    { productId: product.id },
  );
}

export interface OrderTotals {
  total: number;
  /** IGV incluido en los precios (informativo); la propina no lleva IGV. */
  tax: number;
}

const IGV = 0.18;

export function orderTotals(amounts: {
  subtotal: number;
  deliveryFee: number;
  discount: number;
  tip: number;
}): OrderTotals {
  const taxable = amounts.subtotal + amounts.deliveryFee - amounts.discount;
  return { total: taxable + amounts.tip, tax: taxable - Math.round(taxable / (1 + IGV)) };
}
