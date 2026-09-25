-- AlterTable
ALTER TABLE "Coupon" ADD COLUMN     "firstOrderOnly" BOOLEAN NOT NULL DEFAULT false;

-- Códigos públicos de pedido legibles y crecientes: "#2481", "#2482"…
CREATE SEQUENCE "order_code_seq" START WITH 2481;
