-- AlterTable
ALTER TABLE "Payment" ADD COLUMN     "collectedAmount" INTEGER,
ADD COLUMN     "collectedAt" TIMESTAMP(3),
ADD COLUMN     "collectedById" TEXT,
ADD COLUMN     "collectedMethod" "PaymentMethodType";
