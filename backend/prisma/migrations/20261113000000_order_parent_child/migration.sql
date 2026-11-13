-- Parent/child orders for multi-vendor checkout.
--
-- A customer checkout creates ONE parent order (the aggregate the customer,
-- super admin and driver see) plus one child order per vendor. The child order
-- is the vendor's own order row: it carries the vendor's items, subtotal and
-- status, and points back at the parent order.
ALTER TABLE "orders"
  ADD COLUMN "parentOrderId" TEXT,
  ADD COLUMN "sourceFulfillmentId" TEXT;

CREATE INDEX "orders_parentOrderId_idx" ON "orders"("parentOrderId");

ALTER TABLE "orders"
  ADD CONSTRAINT "orders_parentOrderId_fkey"
  FOREIGN KEY ("parentOrderId") REFERENCES "orders"("id")
  ON DELETE CASCADE ON UPDATE CASCADE;
