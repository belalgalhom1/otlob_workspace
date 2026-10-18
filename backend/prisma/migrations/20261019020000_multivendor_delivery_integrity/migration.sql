-- AlterTable
ALTER TABLE "order_delivery_groups" ADD COLUMN "pickupImageUrl" TEXT,
ADD COLUMN "deliveryImageUrl" TEXT;

-- DropIndex
DROP INDEX "order_delivery_group_items_fulfillmentId_idx";

-- Data repair: a portion must ride in exactly one delivery. If a portion was
-- ever attached to two groups (the bug this migration guards against), keep the
-- earliest attachment and detach the rest so the unique index below can build.
DELETE FROM "order_delivery_group_items" a
USING "order_delivery_group_items" b
WHERE a."fulfillmentId" = b."fulfillmentId"
  AND a."deliveryGroupId" <> b."deliveryGroupId"
  AND b."sequence" < a."sequence";

-- CreateIndex
CREATE UNIQUE INDEX "order_delivery_group_items_fulfillmentId_key" ON "order_delivery_group_items"("fulfillmentId");
