-- Unified multi-branch / multi-vendor fulfillment & delivery-group schema.
-- Drops redundant legacy top-level vendor/driver fields from orders and aligns
-- status enums, per-branch wallet ledger constraints, per-target reviews, and
-- geospatial/assist indexes with prisma/schema.prisma.

-- 1. Enums
CREATE TYPE "ReviewTargetType" AS ENUM ('VENDOR_FULFILLMENT', 'DELIVERY_GROUP');

ALTER TYPE "DeliveryGroupStatus" ADD VALUE IF NOT EXISTS 'PREPARING' BEFORE 'LOOKING_FOR_DRIVER';

-- 2. Platform settings
ALTER TABLE "platform_settings"
  ADD COLUMN IF NOT EXISTS "dispatchHandoffDedupeTtlSecs" INTEGER NOT NULL DEFAULT 300;

-- 3. Orders: drop legacy single-vendor / single-driver columns, FKs, and indexes
ALTER TABLE "orders"
  DROP CONSTRAINT IF EXISTS "orders_driverId_fkey",
  DROP CONSTRAINT IF EXISTS "orders_driverShiftId_fkey",
  DROP CONSTRAINT IF EXISTS "orders_assistDriverId_fkey",
  DROP CONSTRAINT IF EXISTS "orders_assistDriverShiftId_fkey",
  DROP CONSTRAINT IF EXISTS "orders_vendorId_fkey",
  DROP CONSTRAINT IF EXISTS "orders_vendorBranchId_fkey";

DROP INDEX IF EXISTS "orders_vendorId_status_idx";
DROP INDEX IF EXISTS "orders_driverId_idx";
DROP INDEX IF EXISTS "orders_vendorId_createdAt_idx";
DROP INDEX IF EXISTS "orders_driverId_createdAt_idx";

ALTER TABLE "orders"
  DROP COLUMN IF EXISTS "vendorId",
  DROP COLUMN IF EXISTS "vendorBranchId",
  DROP COLUMN IF EXISTS "driverId",
  DROP COLUMN IF EXISTS "driverShiftId",
  DROP COLUMN IF EXISTS "assistDriverId",
  DROP COLUMN IF EXISTS "assistDriverShiftId",
  DROP COLUMN IF EXISTS "assistFee",
  DROP COLUMN IF EXISTS "assistCustomerApproved",
  DROP COLUMN IF EXISTS "assistApprovedAt",
  DROP COLUMN IF EXISTS "estimatedPrepTime",
  DROP COLUMN IF EXISTS "acceptedAt",
  DROP COLUMN IF EXISTS "preparedAt",
  DROP COLUMN IF EXISTS "driverAssignedAt",
  DROP COLUMN IF EXISTS "pickedUpAt",
  DROP COLUMN IF EXISTS "pickupImageUrl",
  DROP COLUMN IF EXISTS "deliveryImageUrl",
  DROP COLUMN IF EXISTS "isStacked";

CREATE INDEX IF NOT EXISTS "orders_pickupLocation_idx" ON "orders" USING GIST ("pickupLocation");

-- 4. Vendor fulfillments
ALTER TABLE "order_vendor_fulfillments"
  ADD COLUMN IF NOT EXISTS "isContracted" BOOLEAN NOT NULL DEFAULT false,
  ADD COLUMN IF NOT EXISTS "estimatedPrepTime" INTEGER;

CREATE INDEX IF NOT EXISTS "order_vendor_fulfillments_vendorBranchId_status_idx"
  ON "order_vendor_fulfillments"("vendorBranchId", "status");

-- 5. Delivery groups
ALTER TABLE "order_delivery_groups"
  ADD COLUMN IF NOT EXISTS "isPaymentCollector" BOOLEAN NOT NULL DEFAULT false;

-- 6. Order status events
ALTER TABLE "order_status_events"
  ADD COLUMN IF NOT EXISTS "fulfillmentId" TEXT,
  ADD COLUMN IF NOT EXISTS "deliveryGroupId" TEXT;

-- 7. Driver assist requests: scoped strictly to a delivery group + open partial unique index
ALTER TABLE "driver_assist_requests"
  DROP CONSTRAINT IF EXISTS "driver_assist_requests_deliveryGroupId_fkey";

ALTER TABLE "driver_assist_requests"
  ALTER COLUMN "deliveryGroupId" SET NOT NULL;

ALTER TABLE "driver_assist_requests"
  ADD CONSTRAINT "driver_assist_requests_deliveryGroupId_fkey"
  FOREIGN KEY ("deliveryGroupId") REFERENCES "order_delivery_groups"("id") ON DELETE CASCADE ON UPDATE CASCADE;

CREATE UNIQUE INDEX IF NOT EXISTS "driver_assist_requests_open_uidx"
  ON "driver_assist_requests"("driverId", "deliveryGroupId")
  WHERE "status" IN ('PENDING', 'APPROVED');

-- 8. Order dispatches: deliveryGroupId is mandatory
ALTER TABLE "order_dispatches"
  ALTER COLUMN "deliveryGroupId" SET NOT NULL;

-- 9. Wallet ledger uniqueness scoped per fulfillment / delivery group
DROP INDEX IF EXISTS "vendor_wallet_transactions_orderId_type_vendorId_key";
ALTER TABLE "vendor_wallet_transactions"
  ADD COLUMN IF NOT EXISTS "fulfillmentId" TEXT;
CREATE INDEX IF NOT EXISTS "vendor_wallet_transactions_fulfillmentId_idx"
  ON "vendor_wallet_transactions"("fulfillmentId");
CREATE UNIQUE INDEX IF NOT EXISTS "vendor_wallet_transactions_fulfillmentId_type_key"
  ON "vendor_wallet_transactions"("fulfillmentId", "type");
ALTER TABLE "vendor_wallet_transactions"
  ADD CONSTRAINT "vendor_wallet_transactions_fulfillmentId_fkey"
  FOREIGN KEY ("fulfillmentId") REFERENCES "order_vendor_fulfillments"("id") ON DELETE SET NULL ON UPDATE CASCADE;

DROP INDEX IF EXISTS "driver_wallet_transactions_orderId_type_driverId_key";
ALTER TABLE "driver_wallet_transactions"
  ADD COLUMN IF NOT EXISTS "deliveryGroupId" TEXT;
CREATE INDEX IF NOT EXISTS "driver_wallet_transactions_deliveryGroupId_idx"
  ON "driver_wallet_transactions"("deliveryGroupId");
CREATE UNIQUE INDEX IF NOT EXISTS "driver_wallet_transactions_deliveryGroupId_type_driverId_key"
  ON "driver_wallet_transactions"("deliveryGroupId", "type", "driverId");
ALTER TABLE "driver_wallet_transactions"
  ADD CONSTRAINT "driver_wallet_transactions_deliveryGroupId_fkey"
  FOREIGN KEY ("deliveryGroupId") REFERENCES "order_delivery_groups"("id") ON DELETE SET NULL ON UPDATE CASCADE;

DROP INDEX IF EXISTS "driver_manager_wallet_transactions_orderId_type_managerId_key";
ALTER TABLE "driver_manager_wallet_transactions"
  ADD COLUMN IF NOT EXISTS "deliveryGroupId" TEXT;
CREATE INDEX IF NOT EXISTS "driver_manager_wallet_transactions_deliveryGroupId_idx"
  ON "driver_manager_wallet_transactions"("deliveryGroupId");
CREATE UNIQUE INDEX IF NOT EXISTS "driver_manager_wallet_transactions_deliveryGroupId_type_man_key"
  ON "driver_manager_wallet_transactions"("deliveryGroupId", "type", "managerId");
ALTER TABLE "driver_manager_wallet_transactions"
  ADD CONSTRAINT "driver_manager_wallet_transactions_deliveryGroupId_fkey"
  FOREIGN KEY ("deliveryGroupId") REFERENCES "order_delivery_groups"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- 10. Per-target OrderReview schema + XOR CHECK invariant
ALTER TABLE "order_reviews"
  DROP CONSTRAINT IF EXISTS "order_reviews_orderId_fkey";

DROP INDEX IF EXISTS "order_reviews_orderId_key";

ALTER TABLE "order_reviews"
  DROP COLUMN IF EXISTS "vendorRating",
  DROP COLUMN IF EXISTS "driverRating";

ALTER TABLE "order_reviews"
  ADD COLUMN IF NOT EXISTS "targetType" "ReviewTargetType" NOT NULL,
  ADD COLUMN IF NOT EXISTS "fulfillmentId" TEXT,
  ADD COLUMN IF NOT EXISTS "deliveryGroupId" TEXT,
  ADD COLUMN IF NOT EXISTS "rating" DOUBLE PRECISION NOT NULL,
  ADD COLUMN IF NOT EXISTS "updatedAt" TIMESTAMPTZ(3) NOT NULL;

CREATE INDEX IF NOT EXISTS "order_reviews_orderId_idx"
  ON "order_reviews"("orderId");
CREATE UNIQUE INDEX IF NOT EXISTS "order_reviews_orderId_fulfillmentId_key"
  ON "order_reviews"("orderId", "fulfillmentId");
CREATE UNIQUE INDEX IF NOT EXISTS "order_reviews_orderId_deliveryGroupId_key"
  ON "order_reviews"("orderId", "deliveryGroupId");

ALTER TABLE "order_reviews"
  ADD CONSTRAINT "order_reviews_orderId_fkey"
  FOREIGN KEY ("orderId") REFERENCES "orders"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "order_reviews"
  ADD CONSTRAINT "order_reviews_fulfillmentId_fkey"
  FOREIGN KEY ("fulfillmentId") REFERENCES "order_vendor_fulfillments"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "order_reviews"
  ADD CONSTRAINT "order_reviews_deliveryGroupId_fkey"
  FOREIGN KEY ("deliveryGroupId") REFERENCES "order_delivery_groups"("id") ON DELETE CASCADE ON UPDATE CASCADE;

ALTER TABLE "order_reviews"
  ADD CONSTRAINT "order_reviews_target_check"
  CHECK (
    ("targetType" = 'VENDOR_FULFILLMENT' AND "fulfillmentId" IS NOT NULL AND "deliveryGroupId" IS NULL)
    OR
    ("targetType" = 'DELIVERY_GROUP' AND "deliveryGroupId" IS NOT NULL AND "fulfillmentId" IS NULL)
  );
