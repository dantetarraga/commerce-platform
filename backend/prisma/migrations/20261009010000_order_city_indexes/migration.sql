-- CreateIndex
CREATE INDEX "Order_cityId_status_idx" ON "Order"("cityId", "status");

-- CreateIndex
CREATE INDEX "Order_cityId_createdAt_idx" ON "Order"("cityId", "createdAt");

