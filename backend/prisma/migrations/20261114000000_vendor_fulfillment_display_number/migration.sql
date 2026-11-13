-- Stable per-vendor display number for each order portion.
--
-- A multi-vendor order keeps ONE parent `orders` row; the vendor-facing number
-- therefore lives on the portion (`order_vendor_fulfillments`) as
-- `<parentOrderNumber>-V<n>`, where n is the portion's position on the order.
ALTER TABLE "order_vendor_fulfillments"
  ADD COLUMN "displayNumber" TEXT;

-- Backfill existing portions deterministically in creation order.
UPDATE "order_vendor_fulfillments" AS f
SET "displayNumber" = o."orderNumber" || '-V' || ranked.rn
FROM "orders" AS o,
  (
    SELECT
      id,
      ROW_NUMBER() OVER (
        PARTITION BY "orderId"
        ORDER BY "createdAt" ASC, id ASC
      ) AS rn
    FROM "order_vendor_fulfillments"
  ) AS ranked
WHERE f.id = ranked.id
  AND o.id = f."orderId";

ALTER TABLE "order_vendor_fulfillments"
  ALTER COLUMN "displayNumber" SET NOT NULL;

CREATE UNIQUE INDEX "order_vendor_fulfillments_displayNumber_key"
  ON "order_vendor_fulfillments"("displayNumber");