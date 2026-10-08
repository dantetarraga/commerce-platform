import { Injectable } from '@nestjs/common';
import type { GeoPoint } from '../../common/utils/geo';
import { PrismaService } from '../../database/prisma.service';
import { StoresService } from '../stores/stores.service';

@Injectable()
export class CategoriesService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly stores: StoresService,
  ) {}

  /** Las categorías con cuántos negocios abiertos ahora llegan a la ubicación. */
  async list(point?: GeoPoint) {
    const [categories, open] = await Promise.all([
      this.prisma.category.findMany({
        orderBy: [{ sortOrder: 'asc' }, { name: 'asc' }],
        select: { id: true, name: true, slug: true, iconUrl: true },
      }),
      this.stores.openCountByCategory(point),
    ]);
    return categories.map((category) => ({ ...category, openStoreCount: open.get(category.id) ?? 0 }));
  }
}
