import { Injectable } from '@nestjs/common';
import { AppException } from '../../common/exceptions/app.exception';
import { GeoPoint } from '../../common/utils/geo';
import { money } from '../../common/utils/money';
import { PrismaService } from '../../database/prisma.service';
import { isProductAvailable, isStoreOpen, storeDelivery } from '../stores/store-presenter';
import { StoresService, visibleStore } from '../stores/stores.service';

const PRODUCT_NOT_FOUND = 'Este producto ya no está disponible.';

@Injectable()
export class ProductsService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly stores: StoresService,
  ) {}

  /** `ProductDetailDto` de la app: variantes, grupos de opciones y resumen del negocio. */
  async detail(productId: string, point?: GeoPoint, now = new Date()) {
    const product = await this.prisma.product.findFirst({
      where: { id: productId, deletedAt: null, store: visibleStore },
      include: {
        variants: { orderBy: { sortOrder: 'asc' } },
        options: {
          orderBy: { sortOrder: 'asc' },
          include: { values: { orderBy: { sortOrder: 'asc' } } },
        },
      },
    });
    if (!product) throw AppException.notFound(PRODUCT_NOT_FOUND);

    const { store, city } = await this.stores.load(product.storeId);
    const delivery = storeDelivery(store, city, point ?? city.center);
    const price = (amount: number) => money(amount, city.currency);

    return {
      id: product.id,
      storeId: store.id,
      storeName: store.name,
      name: product.name,
      description: product.description,
      imageUrl: product.imageUrl,
      basePrice: price(product.basePrice),
      isAvailable: isProductAvailable(product),
      variants: product.variants.map((v) => ({
        id: v.id,
        name: v.name,
        price: price(v.price),
        isAvailable: v.isAvailable,
      })),
      options: product.options.map((o) => ({
        id: o.id,
        name: o.name,
        minSelect: o.minSelect,
        maxSelect: o.maxSelect,
        values: o.values.map((value) => ({
          id: value.id,
          name: value.name,
          priceDelta: price(value.priceDelta),
          isAvailable: value.isAvailable,
        })),
      })),
      store: {
        logoUrl: store.logoUrl,
        deliveryFee: price(delivery.fee),
        minOrderAmount: price(store.minOrderAmount),
        etaMinutes: delivery.etaMinutes,
        isOpenNow: isStoreOpen(store, city, now),
      },
    };
  }
}
