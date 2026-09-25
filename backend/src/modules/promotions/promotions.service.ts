import { Injectable } from '@nestjs/common';
import { PrismaService } from '../../database/prisma.service';

@Injectable()
export class PromotionsService {
  constructor(private readonly prisma: PrismaService) {}

  /** Banners vigentes del Home (`PromotionDto` de la app). */
  async active(cityId?: string, now = new Date()) {
    const promotions = await this.prisma.promotion.findMany({
      where: {
        isActive: true,
        startsAt: { lte: now },
        endsAt: { gte: now },
        city: { isActive: true, ...(cityId && { id: cityId }) },
      },
      orderBy: [{ sortOrder: 'asc' }, { startsAt: 'desc' }],
      include: {
        coupon: { select: { code: true, isActive: true, startsAt: true, endsAt: true } },
        store: { select: { isActive: true, deletedAt: true } },
      },
    });
    return promotions.map((p) => {
      // Un banner no manda a un negocio cerrado ni muestra un cupón vencido.
      const storeVisible = p.store?.isActive && !p.store.deletedAt;
      const couponValid = p.coupon?.isActive && p.coupon.startsAt <= now && p.coupon.endsAt >= now;
      return {
        id: p.id,
        title: p.title,
        subtitle: p.subtitle,
        imageUrl: p.imageUrl,
        storeId: storeVisible ? p.storeId : null,
        couponCode: couponValid ? p.coupon!.code : null,
      };
    });
  }
}
