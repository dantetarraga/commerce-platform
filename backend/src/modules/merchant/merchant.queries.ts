import { PrismaService } from '../../database/prisma.service';
import { escapeLike } from '../search/search.queries';

/**
 * Ids de los productos del negocio cuyo nombre contiene [query] sin importar
 * tildes ni mayúsculas ("aji" → "Ají de gallina"). Usa el índice de trigramas
 * sobre `immutable_unaccent(lower(name))` de la migración inicial.
 */
export async function matchingProductIds(prisma: PrismaService, storeId: string, query: string): Promise<Set<string>> {
  const pattern = `%${escapeLike(query)}%`;
  const rows = await prisma.$queryRaw<{ id: string }[]>`
    SELECT p."id"
    FROM "Product" p
    WHERE p."storeId" = ${storeId} AND p."deletedAt" IS NULL
      AND immutable_unaccent(lower(p."name")) LIKE immutable_unaccent(lower(${pattern}))`;
  return new Set(rows.map((r) => r.id));
}
