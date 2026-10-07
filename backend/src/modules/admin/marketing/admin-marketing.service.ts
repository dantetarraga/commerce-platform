import { HttpStatus, Injectable } from '@nestjs/common';
import { AppException, ErrorCode } from '../../../common/exceptions/app.exception';
import { money } from '../../../common/utils/money';
import { PrismaService } from '../../../database/prisma.service';
import { Coupon } from '../../../generated/prisma/client';
import { CouponType } from '../../../generated/prisma/enums';
import { invalid } from '../catalog/catalog-rules';
import { CouponDto, PromotionDto, UpdateCouponDto, UpdatePromotionDto } from './marketing.dto';
import { couponValue, CouponTerms, normalizeCode, periodErrors } from './marketing-rules';

function toAdminCoupon(c: Coupon) {
  return {
    id: c.id,
    code: c.code,
    label: c.label,
    description: c.description,
    type: c.type,
    percentOff: c.type === CouponType.PERCENTAGE ? c.value : null,
    amountOff: c.type === CouponType.FIXED_AMOUNT ? money(c.value) : null,
    maxDiscount: c.maxDiscount === null ? null : money(c.maxDiscount),
    minOrderAmount: money(c.minOrderAmount),
    cityId: c.cityId,
    storeId: c.storeId,
    startsAt: c.startsAt,
    endsAt: c.endsAt,
    usageLimit: c.usageLimit,
    perUserLimit: c.perUserLimit,
    firstOrderOnly: c.firstOrderOnly,
    usedCount: c.usedCount,
    isActive: c.isActive,
  };
}

/** Cupones y banners del inicio, editados por el admin. */
@Injectable()
export class AdminMarketingService {
  constructor(private readonly prisma: PrismaService) {}

  async listCoupons() {
    const coupons = await this.prisma.coupon.findMany({ orderBy: [{ isActive: 'desc' }, { endsAt: 'desc' }] });
    return coupons.map(toAdminCoupon);
  }

  async createCoupon(dto: CouponDto) {
    const code = normalizeCode(dto.code);
    if (await this.prisma.coupon.findUnique({ where: { code }, select: { id: true } })) {
      throw new AppException(ErrorCode.CONFLICT, HttpStatus.CONFLICT, 'Ya hay un cupón con ese código.');
    }
    const terms = this.termsOrThrow({
      type: dto.type,
      percentOff: dto.percentOff,
      amountOff: dto.amountOff?.amount,
      maxDiscount: dto.maxDiscount?.amount ?? null,
    });
    this.assertPeriod(dto.startsAt, dto.endsAt);
    await this.assertScope(dto.cityId ?? null, dto.storeId ?? null);

    const coupon = await this.prisma.coupon.create({
      data: {
        code,
        label: dto.label,
        description: dto.description,
        type: dto.type,
        value: terms.value,
        maxDiscount: dto.type === CouponType.PERCENTAGE ? (dto.maxDiscount?.amount ?? null) : null,
        minOrderAmount: dto.minOrderAmount?.amount ?? 0,
        cityId: dto.cityId ?? null,
        storeId: dto.storeId ?? null,
        startsAt: dto.startsAt,
        endsAt: dto.endsAt,
        usageLimit: dto.usageLimit ?? null,
        perUserLimit: dto.perUserLimit ?? 1,
        firstOrderOnly: dto.firstOrderOnly ?? false,
        isActive: dto.isActive ?? true,
      },
    });
    return toAdminCoupon(coupon);
  }

  /** Para dar de baja un cupón se usa `isActive: false`: no se borra porque hay pedidos que lo usaron. */
  async updateCoupon(id: string, dto: UpdateCouponDto) {
    const current = await this.prisma.coupon.findUnique({ where: { id } });
    if (!current) throw AppException.notFound('No encontramos ese cupón.');

    const type = dto.type ?? current.type;
    // Si cambia el tipo, el descuento anterior ya no sirve: hay que mandar el nuevo.
    const keep = type === current.type;
    const merged: CouponTerms = {
      type,
      percentOff: dto.percentOff ?? (keep && type === CouponType.PERCENTAGE ? current.value : undefined),
      amountOff: dto.amountOff?.amount ?? (keep && type === CouponType.FIXED_AMOUNT ? current.value : undefined),
      maxDiscount:
        dto.maxDiscount === null
          ? null
          : (dto.maxDiscount?.amount ?? (type === CouponType.PERCENTAGE ? current.maxDiscount : null)),
    };
    const { value } = this.termsOrThrow(merged);
    this.assertPeriod(dto.startsAt ?? current.startsAt, dto.endsAt ?? current.endsAt);
    const cityId = dto.cityId === undefined ? current.cityId : dto.cityId;
    const storeId = dto.storeId === undefined ? current.storeId : dto.storeId;
    await this.assertScope(cityId, storeId);

    const coupon = await this.prisma.coupon.update({
      where: { id },
      data: {
        label: dto.label,
        description: dto.description,
        type,
        value,
        startsAt: dto.startsAt,
        endsAt: dto.endsAt,
        usageLimit: dto.usageLimit,
        perUserLimit: dto.perUserLimit,
        firstOrderOnly: dto.firstOrderOnly,
        isActive: dto.isActive,
        maxDiscount: merged.maxDiscount ?? null,
        cityId,
        storeId,
        ...(dto.minOrderAmount && { minOrderAmount: dto.minOrderAmount.amount }),
      },
    });
    return toAdminCoupon(coupon);
  }

  async listPromotions(cityId?: string) {
    return this.prisma.promotion.findMany({
      where: cityId ? { cityId } : {},
      orderBy: [{ isActive: 'desc' }, { sortOrder: 'asc' }, { startsAt: 'desc' }],
    });
  }

  async createPromotion(dto: PromotionDto) {
    this.assertPeriod(dto.startsAt, dto.endsAt);
    await this.assertPromotionLinks(dto.cityId, dto.storeId ?? null, dto.couponId ?? null);
    return this.prisma.promotion.create({ data: dto });
  }

  async updatePromotion(id: string, dto: UpdatePromotionDto) {
    const current = await this.prisma.promotion.findUnique({ where: { id } });
    if (!current) throw AppException.notFound('No encontramos esa promoción.');
    this.assertPeriod(dto.startsAt ?? current.startsAt, dto.endsAt ?? current.endsAt);
    await this.assertPromotionLinks(
      dto.cityId ?? current.cityId,
      dto.storeId === undefined ? current.storeId : dto.storeId,
      dto.couponId === undefined ? current.couponId : dto.couponId,
    );
    return this.prisma.promotion.update({ where: { id }, data: dto });
  }

  async removePromotion(id: string) {
    const { count } = await this.prisma.promotion.deleteMany({ where: { id } });
    if (count === 0) throw AppException.notFound('No encontramos esa promoción.');
  }

  private termsOrThrow(terms: CouponTerms) {
    const result = couponValue(terms);
    if ('errors' in result) throw invalid(result.errors);
    return result;
  }

  private assertPeriod(startsAt: Date, endsAt: Date) {
    const errors = periodErrors(startsAt, endsAt);
    if (Object.keys(errors).length) throw invalid(errors);
  }

  private async assertScope(cityId: string | null, storeId: string | null) {
    if (cityId && !(await this.prisma.city.findUnique({ where: { id: cityId }, select: { id: true } }))) {
      throw invalid({ cityId: 'Esa ciudad no existe.' });
    }
    if (storeId) {
      const store = await this.prisma.store.findFirst({
        where: { id: storeId, deletedAt: null },
        select: { cityId: true },
      });
      if (!store) throw invalid({ storeId: 'Ese negocio no existe.' });
      if (cityId && store.cityId !== cityId) throw invalid({ storeId: 'El negocio es de otra ciudad.' });
    }
  }

  private async assertPromotionLinks(cityId: string, storeId: string | null, couponId: string | null) {
    await this.assertScope(cityId, storeId);
    if (couponId && !(await this.prisma.coupon.findUnique({ where: { id: couponId }, select: { id: true } }))) {
      throw invalid({ couponId: 'Ese cupón no existe.' });
    }
  }
}
