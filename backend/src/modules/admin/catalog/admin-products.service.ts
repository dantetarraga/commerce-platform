import { Injectable } from '@nestjs/common';
import { AppException } from '../../../common/exceptions/app.exception';
import { PrismaService } from '../../../database/prisma.service';
import { Prisma } from '../../../generated/prisma/client';
import { adminProductInclude, toAdminProduct } from './catalog-presenter';
import { invalid, optionErrors, syncPlan } from './catalog-rules';
import { OptionDto, OptionValueDto, ProductDto, UpdateProductDto, VariantDto } from './product.dto';

type Tx = Prisma.TransactionClient;

const variantData = (v: VariantDto, i: number) => ({
  name: v.name,
  price: v.price.amount,
  isAvailable: v.isAvailable ?? true,
  sortOrder: v.sortOrder ?? i,
});
const valueData = (v: OptionValueDto, i: number) => ({
  name: v.name,
  priceDelta: v.priceDelta?.amount ?? 0,
  isAvailable: v.isAvailable ?? true,
  sortOrder: v.sortOrder ?? i,
});
const optionData = (o: OptionDto, i: number) => ({
  name: o.name,
  minSelect: o.minSelect,
  maxSelect: o.maxSelect,
  sortOrder: o.sortOrder ?? i,
});

/** Productos de la carta con sus variantes y grupos de opciones. */
@Injectable()
export class AdminProductsService {
  constructor(private readonly prisma: PrismaService) {}

  async get(id: string) {
    const product = await this.prisma.product.findFirst({
      where: { id, deletedAt: null },
      include: { ...adminProductInclude, store: { select: { city: { select: { currency: true } } } } },
    });
    if (!product) throw AppException.notFound('No encontramos ese producto.');
    return toAdminProduct(product, product.store.city.currency);
  }

  async create(storeId: string, dto: ProductDto) {
    const store = await this.prisma.store.findFirst({ where: { id: storeId, deletedAt: null }, select: { id: true } });
    if (!store) throw AppException.notFound('No encontramos ese negocio.');
    await this.assertSection(storeId, dto.menuSectionId);
    this.assertOptions(dto.options);

    const { variants = [], options = [], basePrice, menuSectionId, ...fields } = dto;
    const product = await this.prisma.product.create({
      data: {
        ...fields,
        storeId,
        menuSectionId: menuSectionId ?? null,
        basePrice: basePrice.amount,
        variants: { create: variants.map(variantData) },
        options: {
          create: options.map((o, i) => ({ ...optionData(o, i), values: { create: o.values.map(valueData) } })),
        },
      },
    });
    return this.get(product.id);
  }

  async update(id: string, dto: UpdateProductDto) {
    const current = await this.prisma.product.findFirst({
      where: { id, deletedAt: null },
      include: {
        variants: { select: { id: true } },
        options: { select: { id: true, values: { select: { id: true } } } },
      },
    });
    if (!current) throw AppException.notFound('No encontramos ese producto.');
    if (dto.menuSectionId !== undefined) await this.assertSection(current.storeId, dto.menuSectionId);
    this.assertOptions(dto.options);

    const { variants, options, basePrice, ...fields } = dto;
    await this.prisma.$transaction(async (tx) => {
      await tx.product.update({
        where: { id },
        data: { ...fields, ...(basePrice && { basePrice: basePrice.amount }) },
      });
      if (variants)
        await this.syncVariants(
          tx,
          id,
          current.variants.map((v) => v.id),
          variants,
        );
      if (options) await this.syncOptions(tx, id, current.options, options);
    });
    return this.get(id);
  }

  /** Sale de la carta; los pedidos pasados guardan su nombre y precio. */
  async remove(id: string) {
    const { count } = await this.prisma.product.updateMany({
      where: { id, deletedAt: null },
      data: { deletedAt: new Date(), isAvailable: false },
    });
    if (count === 0) throw AppException.notFound('No encontramos ese producto.');
  }

  private async syncVariants(tx: Tx, productId: string, current: string[], incoming: VariantDto[]) {
    const plan = syncPlan(current, incoming);
    if (plan.unknownIds.length) throw invalid({ variants: 'Alguna variante no es de este producto.' });
    await tx.productVariant.deleteMany({ where: { id: { in: plan.remove } } });
    for (const v of plan.update) {
      await tx.productVariant.update({ where: { id: v.id }, data: variantData(v, incoming.indexOf(v)) });
    }
    for (const v of plan.create) {
      await tx.productVariant.create({ data: { productId, ...variantData(v, incoming.indexOf(v)) } });
    }
  }

  private async syncOptions(
    tx: Tx,
    productId: string,
    current: { id: string; values: { id: string }[] }[],
    incoming: OptionDto[],
  ) {
    const plan = syncPlan(
      current.map((o) => o.id),
      incoming,
    );
    if (plan.unknownIds.length) throw invalid({ options: 'Algún grupo de opciones no es de este producto.' });
    await tx.productOption.deleteMany({ where: { id: { in: plan.remove } } });
    for (const o of plan.update) {
      const index = incoming.indexOf(o);
      await tx.productOption.update({ where: { id: o.id }, data: optionData(o, index) });
      const values = syncPlan(
        current.find((c) => c.id === o.id)!.values.map((v) => v.id),
        o.values,
      );
      if (values.unknownIds.length) throw invalid({ [`options.${index}.values`]: 'Algún valor no es de este grupo.' });
      await tx.productOptionValue.deleteMany({ where: { id: { in: values.remove } } });
      for (const v of values.update) {
        await tx.productOptionValue.update({ where: { id: v.id }, data: valueData(v, o.values.indexOf(v)) });
      }
      for (const v of values.create) {
        await tx.productOptionValue.create({ data: { optionId: o.id, ...valueData(v, o.values.indexOf(v)) } });
      }
    }
    for (const o of plan.create) {
      await tx.productOption.create({
        data: { productId, ...optionData(o, incoming.indexOf(o)), values: { create: o.values.map(valueData) } },
      });
    }
  }

  private async assertSection(storeId: string, sectionId: string | null | undefined) {
    if (!sectionId) return;
    const section = await this.prisma.menuSection.findFirst({
      where: { id: sectionId, storeId },
      select: { id: true },
    });
    if (!section) throw invalid({ menuSectionId: 'Esa sección no es de este negocio.' });
  }

  private assertOptions(options: OptionDto[] | undefined) {
    const errors = optionErrors(options ?? []);
    if (Object.keys(errors).length) throw invalid(errors);
  }
}
