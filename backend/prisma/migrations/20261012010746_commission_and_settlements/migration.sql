-- AlterTable
ALTER TABLE "Order" ADD COLUMN     "commissionRateBps" INTEGER;

-- AlterTable
ALTER TABLE "Store" ADD COLUMN     "commissionRateBps" INTEGER;

-- CreateTable
CREATE TABLE "PlatformSettings" (
    "id" INTEGER NOT NULL DEFAULT 1,
    "commissionRateBps" INTEGER NOT NULL,
    "updatedById" TEXT,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "PlatformSettings_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "StoreSettlement" (
    "id" TEXT NOT NULL,
    "storeId" TEXT NOT NULL,
    "weekStart" DATE NOT NULL,
    "deliveredCount" INTEGER NOT NULL,
    "sales" INTEGER NOT NULL,
    "commission" INTEGER NOT NULL,
    "collectedByStore" INTEGER NOT NULL,
    "balance" INTEGER NOT NULL,
    "currency" TEXT NOT NULL,
    "paidById" TEXT,
    "paidAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "StoreSettlement_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE INDEX "StoreSettlement_weekStart_idx" ON "StoreSettlement"("weekStart");

-- CreateIndex
CREATE UNIQUE INDEX "StoreSettlement_storeId_weekStart_key" ON "StoreSettlement"("storeId", "weekStart");

-- CreateIndex
CREATE INDEX "Order_deliveredAt_idx" ON "Order"("deliveredAt");

-- AddForeignKey
ALTER TABLE "PlatformSettings" ADD CONSTRAINT "PlatformSettings_updatedById_fkey" FOREIGN KEY ("updatedById") REFERENCES "User"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "StoreSettlement" ADD CONSTRAINT "StoreSettlement_storeId_fkey" FOREIGN KEY ("storeId") REFERENCES "Store"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "StoreSettlement" ADD CONSTRAINT "StoreSettlement_paidById_fkey" FOREIGN KEY ("paidById") REFERENCES "User"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- Comisión por defecto: 10 % del subtotal de productos (el admin la cambia en el panel).
INSERT INTO "PlatformSettings" ("id", "commissionRateBps", "updatedAt") VALUES (1, 1000, CURRENT_TIMESTAMP);

ALTER TABLE "PlatformSettings" ADD CONSTRAINT "PlatformSettings_singleton" CHECK ("id" = 1);
ALTER TABLE "PlatformSettings" ADD CONSTRAINT "PlatformSettings_commissionRateBps_range" CHECK ("commissionRateBps" BETWEEN 0 AND 10000);
ALTER TABLE "Store" ADD CONSTRAINT "Store_commissionRateBps_range" CHECK ("commissionRateBps" BETWEEN 0 AND 10000);

-- Los pedidos que ya existían quedan con la comisión por defecto.
UPDATE "Order" SET "commissionRateBps" = 1000 WHERE "commissionRateBps" IS NULL;
