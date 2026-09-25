-- AlterTable
ALTER TABLE "Address" ADD COLUMN     "clientId" TEXT NOT NULL;

-- CreateIndex
CREATE UNIQUE INDEX "Address_userId_clientId_key" ON "Address"("userId", "clientId");

