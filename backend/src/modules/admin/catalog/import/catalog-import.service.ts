import { HttpStatus, Injectable } from '@nestjs/common';
import { AppException, ErrorCode } from '../../../../common/exceptions/app.exception';
import { money } from '../../../../common/utils/money';
import { PrismaService } from '../../../../database/prisma.service';
import { importSummary, planImport, type ProductChanges, type SectionRef } from './catalog-import';
import { CatalogImportDto } from './catalog-import.dto';

/** Carga masiva de productos desde un Excel o CSV (reglas en `catalog-import.ts`). */
@Injectable()
export class CatalogImportService {
  constructor(private readonly prisma: PrismaService) {}

  async run(storeId: string, dto: CatalogImportDto) {
    const store = await this.prisma.store.findFirst({
      where: { id: storeId, deletedAt: null },
      select: {
        city: { select: { currency: true } },
        menuSections: { select: { id: true, name: true } },
        products: {
          where: { deletedAt: null },
          select: {
            id: true,
            name: true,
            description: true,
            imageUrl: true,
            basePrice: true,
            stock: true,
            isAvailable: true,
            menuSectionId: true,
            sortOrder: true,
            _count: { select: { variants: true } },
          },
        },
      },
    });
    if (!store) throw AppException.notFound('No encontramos ese negocio.');

    const plan = planImport(dto.rows, {
      sections: store.menuSections,
      products: store.products.map(({ _count, ...p }) => ({ ...p, hasVariants: _count.variants > 0 })),
    });
    const currency = store.city.currency;
    const summary = {
      ...importSummary(plan),
      rows: plan.rows.map(({ price, ...row }) => ({
        ...row,
        ...(price && {
          price: { from: price.from === null ? null : money(price.from, currency), to: money(price.to, currency) },
        }),
      })),
    };
    if (dto.dryRun) return { ...summary, dryRun: true };
    if (summary.failed > 0) {
      throw new AppException(
        ErrorCode.VALIDATION_ERROR,
        HttpStatus.BAD_REQUEST,
        'Hay filas con errores. Corrígelas en el archivo y vuelve a importar.',
        { rows: summary.rows.filter((r) => r.action === 'error') },
      );
    }

    const firstSortOrder = Math.max(-1, ...store.products.map((p) => p.sortOrder)) + 1;
    await this.prisma.$transaction(
      async (tx) => {
        const created = new Map<string, string>();
        for (const [i, name] of plan.sectionsToCreate.entries()) {
          const section = await tx.menuSection.create({
            data: { storeId, name, sortOrder: store.menuSections.length + i },
            select: { id: true },
          });
          created.set(name, section.id);
        }
        const sectionId = (ref: SectionRef | null | undefined) =>
          ref === undefined ? undefined : ref === null ? null : 'id' in ref ? ref.id : created.get(ref.newName);
        const data = ({ section, ...changes }: ProductChanges) => ({ ...changes, menuSectionId: sectionId(section) });

        await tx.product.createMany({
          data: plan.creates.map((p, i) => ({
            ...data(p),
            name: p.name,
            basePrice: p.basePrice,
            storeId,
            sortOrder: firstSortOrder + i,
          })),
        });
        for (const { id, changes } of plan.updates) {
          await tx.product.update({ where: { id }, data: data(changes) });
        }
      },
      // Hasta 500 filas en una sola transacción: todo entra o nada.
      { timeout: 30_000 },
    );
    return { ...summary, dryRun: false };
  }
}
