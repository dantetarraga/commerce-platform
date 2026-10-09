-- AlterTable
ALTER TABLE "Device" ADD COLUMN     "app" TEXT NOT NULL DEFAULT 'customer';

-- CreateIndex
CREATE INDEX "Device_userId_app_idx" ON "Device"("userId", "app");

