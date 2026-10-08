-- AlterTable
ALTER TABLE "Order" ADD COLUMN     "acceptedAt" TIMESTAMP(3),
ADD COLUMN     "readyAt" TIMESTAMP(3);

-- CreateIndex
CREATE INDEX "Order_storeId_createdAt_idx" ON "Order"("storeId", "createdAt");

-- CreateIndex
CREATE INDEX "OrderItem_orderId_idx" ON "OrderItem"("orderId");

-- CreateIndex
CREATE INDEX "OrderItem_productId_idx" ON "OrderItem"("productId");


-- Backfill: los pedidos que ya existían toman las horas de su historial.
UPDATE "Order" o
SET "acceptedAt" = h."at"
FROM (
  SELECT "orderId", MIN("createdAt") AS "at"
  FROM "OrderStatusHistory"
  WHERE "toStatus" = 'CONFIRMED'
  GROUP BY "orderId"
) h
WHERE h."orderId" = o."id";

UPDATE "Order" o
SET "readyAt" = h."at"
FROM (
  SELECT "orderId", MIN("createdAt") AS "at"
  FROM "OrderStatusHistory"
  WHERE "toStatus" = 'READY'
  GROUP BY "orderId"
) h
WHERE h."orderId" = o."id";
