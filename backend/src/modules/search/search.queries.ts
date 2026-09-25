import { PrismaService } from '../../database/prisma.service';
import { Prisma } from '../../generated/prisma/client';

// SQL crudo de búsqueda. `immutable_unaccent` y los índices GIN de trigramas
// se crean en la migración inicial.

/** Escapa `%`, `_` y `\` para usar el texto del usuario dentro de un LIKE. */
export function escapeLike(text: string): string {
  return text.replace(/[\\%_]/g, (char) => `\\${char}`);
}

const normalized = (column: Prisma.Sql) => Prisma.sql`immutable_unaccent(lower(${column}))`;

/**
 * Coincidencia por subcadena sin tildes ("aji" → "Ají de gallina") o por
 * similitud de trigramas para errores de tipeo ("polo" → "pollo").
 * Primero las coincidencias exactas, después por similitud.
 */
function matchClause(name: Prisma.Sql, description: Prisma.Sql, query: string) {
  const pattern = `%${escapeLike(query)}%`;
  const needle = Prisma.sql`immutable_unaccent(lower(${query}))`;
  const likeName = Prisma.sql`${normalized(name)} LIKE immutable_unaccent(lower(${pattern}))`;
  const likeDescription = Prisma.sql`${normalized(Prisma.sql`coalesce(${description}, '')`)} LIKE immutable_unaccent(lower(${pattern}))`;
  const similarity = Prisma.sql`word_similarity(${needle}, ${normalized(name)})`;
  return {
    where: Prisma.sql`(${likeName} OR ${likeDescription} OR ${similarity} > 0.45)`,
    rank: Prisma.sql`(CASE WHEN ${likeName} THEN 2 WHEN ${likeDescription} THEN 1 ELSE 0 END) DESC, ${similarity} DESC`,
  };
}

export async function searchProductIds(prisma: PrismaService, cityId: string, query: string, limit: number) {
  const match = matchClause(Prisma.sql`p."name"`, Prisma.sql`p."description"`, query);
  const rows = await prisma.$queryRaw<{ id: string }[]>`
    SELECT p."id"
    FROM "Product" p
    JOIN "Store" s ON s."id" = p."storeId"
    WHERE p."deletedAt" IS NULL AND p."isAvailable"
      AND s."isActive" AND s."deletedAt" IS NULL AND s."cityId" = ${cityId}
      AND ${match.where}
    ORDER BY ${match.rank}, p."name"
    LIMIT ${limit}`;
  return rows.map((r) => r.id);
}

export async function searchStoreIds(prisma: PrismaService, cityId: string, query: string, limit: number) {
  const match = matchClause(Prisma.sql`s."name"`, Prisma.sql`s."description"`, query);
  const rows = await prisma.$queryRaw<{ id: string }[]>`
    SELECT s."id"
    FROM "Store" s
    WHERE s."isActive" AND s."deletedAt" IS NULL AND s."cityId" = ${cityId}
      AND ${match.where}
    ORDER BY ${match.rank}, s."name"
    LIMIT ${limit}`;
  return rows.map((r) => r.id);
}

/** "Lo más pedido": términos curados con cuántos negocios los venden hoy. */
export async function popularSearchCounts(prisma: PrismaService, cityId: string) {
  return prisma.$queryRaw<{ term: string; storeCount: number }[]>`
    SELECT t."term", COUNT(DISTINCT s."id")::int AS "storeCount"
    FROM "PopularSearch" t
    LEFT JOIN "Product" p
      ON p."deletedAt" IS NULL AND p."isAvailable"
      AND ${normalized(Prisma.sql`p."name"`)} LIKE '%' || ${normalized(Prisma.sql`t."term"`)} || '%'
    LEFT JOIN "Store" s
      ON s."id" = p."storeId" AND s."isActive" AND s."deletedAt" IS NULL AND s."cityId" = t."cityId"
    WHERE t."cityId" = ${cityId}
    GROUP BY t."id", t."term", t."sortOrder"
    ORDER BY t."sortOrder", t."term"`;
}
