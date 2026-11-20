-- Add cancellation actor & reason attribution fields to orders
ALTER TABLE "orders"
  ADD COLUMN IF NOT EXISTS "cancelledByUserId" TEXT,
  ADD COLUMN IF NOT EXISTS "cancelledByRole" "Role",
  ADD COLUMN IF NOT EXISTS "cancelledByName" TEXT,
  ADD COLUMN IF NOT EXISTS "cancelledByNameAr" TEXT,
  ADD COLUMN IF NOT EXISTS "cancelledByAvatar" TEXT,
  ADD COLUMN IF NOT EXISTS "cancelReason" TEXT,
  ADD COLUMN IF NOT EXISTS "cancelledAt" TIMESTAMPTZ(3);

-- Add idempotency eventKey & actor identity fields to order_status_events
ALTER TABLE "order_status_events"
  ADD COLUMN IF NOT EXISTS "eventKey" TEXT,
  ADD COLUMN IF NOT EXISTS "actorUserId" TEXT,
  ADD COLUMN IF NOT EXISTS "actorRole" "Role",
  ADD COLUMN IF NOT EXISTS "actorName" TEXT,
  ADD COLUMN IF NOT EXISTS "actorNameAr" TEXT,
  ADD COLUMN IF NOT EXISTS "actorAvatar" TEXT,
  ADD COLUMN IF NOT EXISTS "actorVendorId" TEXT;

-- Add driver-facing adjustment note & flag to driver_wallet_transactions
ALTER TABLE "driver_wallet_transactions"
  ADD COLUMN IF NOT EXISTS "note" TEXT,
  ADD COLUMN IF NOT EXISTS "isManualAdjustment" BOOLEAN NOT NULL DEFAULT false;

-- Foreign keys (guarded cleanly)
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint WHERE conname = 'orders_cancelledByUserId_fkey'
  ) THEN
    ALTER TABLE "orders"
      ADD CONSTRAINT "orders_cancelledByUserId_fkey"
      FOREIGN KEY ("cancelledByUserId") REFERENCES "users"("id") ON DELETE SET NULL ON UPDATE CASCADE;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint WHERE conname = 'order_status_events_actorUserId_fkey'
  ) THEN
    ALTER TABLE "order_status_events"
      ADD CONSTRAINT "order_status_events_actorUserId_fkey"
      FOREIGN KEY ("actorUserId") REFERENCES "users"("id") ON DELETE SET NULL ON UPDATE CASCADE;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint WHERE conname = 'order_status_events_actorVendorId_fkey'
  ) THEN
    ALTER TABLE "order_status_events"
      ADD CONSTRAINT "order_status_events_actorVendorId_fkey"
      FOREIGN KEY ("actorVendorId") REFERENCES "vendors"("id") ON DELETE SET NULL ON UPDATE CASCADE;
  END IF;
END $$;

-- 1. Remove exact duplicate historical order_status_events rows (preserving earliest createdAt)
DELETE FROM "order_status_events" AS dup
USING (
  SELECT "id",
         ROW_NUMBER() OVER (
           PARTITION BY
             "orderId",
             COALESCE("fulfillmentId", ''),
             COALESCE("deliveryGroupId", ''),
             "status",
             COALESCE("note", ''),
             COALESCE("createdBy", '')
           ORDER BY "createdAt" ASC, "id" ASC
         ) AS row_num
  FROM "order_status_events"
) AS ranked
WHERE dup."id" = ranked."id" AND ranked.row_num > 1;

-- 2. Backfill historical actor fields on order_status_events when createdBy maps to an existing user
UPDATE "order_status_events" AS e
SET
  "actorUserId" = u."id",
  "actorRole" = u."role",
  "actorName" = COALESCE(d."name", u."name"),
  "actorAvatar" = COALESCE(d."avatar", u."avatar")
FROM "users" AS u
LEFT JOIN "drivers" AS d ON d."userId" = u."id"
WHERE e."createdBy" = u."id"
  AND e."actorUserId" IS NULL;

-- Attach vendor context for vendor-member events linked to a fulfillment
UPDATE "order_status_events" AS e
SET
  "actorVendorId" = v."id",
  "actorName" = v."storeName",
  "actorNameAr" = v."storeNameAr",
  "actorAvatar" = COALESCE(v."logo", e."actorAvatar")
FROM "order_vendor_fulfillments" AS f
JOIN "vendors" AS v ON v."id" = f."vendorId"
WHERE e."fulfillmentId" = f."id"
  AND (e."actorRole" = 'VENDOR_MEMBER' OR e."actorRole" IS NULL)
  AND e."createdBy" IS DISTINCT FROM 'system';

-- Also recover actor from decidedByUserId on legacy "All vendors rejected their portions" system events
UPDATE "order_status_events" AS e
SET
  "actorUserId" = u."id",
  "actorRole" = u."role",
  "actorVendorId" = v."id",
  "actorName" = CASE WHEN u."role" = 'VENDOR_MEMBER' THEN v."storeName" ELSE u."name" END,
  "actorNameAr" = CASE WHEN u."role" = 'VENDOR_MEMBER' THEN v."storeNameAr" ELSE NULL END,
  "actorAvatar" = CASE WHEN u."role" = 'VENDOR_MEMBER' THEN COALESCE(v."logo", u."avatar") ELSE u."avatar" END
FROM LATERAL (
  SELECT f."decidedByUserId", f."vendorId"
  FROM "order_vendor_fulfillments" AS f
  WHERE f."orderId" = e."orderId"
    AND f."status" = 'REJECTED'
    AND f."decidedByUserId" IS NOT NULL
  ORDER BY f."decidedAt" DESC NULLS LAST
  LIMIT 1
) AS lf
JOIN "users" AS u ON u."id" = lf."decidedByUserId"
JOIN "vendors" AS v ON v."id" = lf."vendorId"
WHERE e."status" = 'CANCELLED'
  AND e."createdBy" = 'system'
  AND e."actorUserId" IS NULL;

-- Make historical fulfillment portion & pickup event notes identify their store instead of opaque UUIDs/generic text
UPDATE "order_status_events" AS e
SET "note" = v."storeName" || CASE
  WHEN vb."name" IS NOT NULL AND vb."name" <> '' THEN ' (' || vb."name" || ')'
  ELSE ''
END || ': ' || SUBSTRING(e."note" FROM POSITION(': ' IN e."note") + 2)
FROM "order_vendor_fulfillments" AS f
JOIN "vendors" AS v ON v."id" = f."vendorId"
LEFT JOIN "vendor_branches" AS vb ON vb."id" = f."vendorBranchId"
WHERE e."fulfillmentId" = f."id"
  AND e."note" ~ '^Delivery [0-9]+: vendor portion (ready for pickup|started preparing)$';

UPDATE "order_status_events" AS e
SET "note" = 'Driver picked up from ' || v."storeName" || CASE
  WHEN vb."name" IS NOT NULL AND vb."name" <> '' THEN ' (' || vb."name" || ')'
  ELSE ''
END
FROM "order_vendor_fulfillments" AS f
JOIN "vendors" AS v ON v."id" = f."vendorId"
LEFT JOIN "vendor_branches" AS vb ON vb."id" = f."vendorBranchId"
WHERE e."fulfillmentId" = f."id"
  AND e."note" = 'Driver picked up fulfillment stop ' || f."id";

-- 3. Backfill historical cancellation actor metadata onto orders
UPDATE "orders" AS o
SET
  "cancelledByUserId" = ce."actorUserId",
  "cancelledByRole" = ce."actorRole",
  "cancelledByName" = ce."actorName",
  "cancelledByNameAr" = ce."actorNameAr",
  "cancelledByAvatar" = ce."actorAvatar",
  "cancelReason" = CASE
    WHEN ce."note" IS NULL THEN NULL
    WHEN lower(btrim(ce."note")) IN ('cancelled by user', 'canceled by user', 'cancelled by admin', 'canceled by admin', 'cancelled by vendor', 'canceled by vendor') THEN NULL
    ELSE ce."note"
  END,
  "cancelledAt" = ce."createdAt"
FROM LATERAL (
  SELECT e."actorUserId", e."actorRole", e."actorName", e."actorNameAr", e."actorAvatar", e."note", e."createdAt"
  FROM "order_status_events" AS e
  WHERE e."orderId" = o."id"
    AND e."status" = 'CANCELLED'
  ORDER BY e."createdAt" DESC
  LIMIT 1
) AS ce
WHERE o."status" = 'CANCELLED'
  AND o."cancelledByUserId" IS NULL
  AND o."cancelledAt" IS NULL;

-- 4. Backfill manual adjustment flag & driver-facing notes on historical driver_wallet_transactions
UPDATE "driver_wallet_transactions"
SET
  "isManualAdjustment" = true,
  "note" = CASE
    WHEN "description" IS NULL THEN NULL
    WHEN lower(btrim("description")) IN (
      '',
      'manual admin transaction',
      'manual admin adjustment',
      'manual driver manager transaction'
    ) THEN NULL
    ELSE btrim("description")
  END
WHERE "idempotencyKey" LIKE 'admin:driver:%';

-- Also mark remaining historical non-topup, non-order ADJUSTMENT rows as manual adjustments
UPDATE "driver_wallet_transactions"
SET
  "isManualAdjustment" = true,
  "note" = CASE
    WHEN "description" IS NULL THEN NULL
    WHEN lower(btrim("description")) IN (
      '',
      'manual admin transaction',
      'manual admin adjustment',
      'manual driver manager transaction'
    ) THEN NULL
    ELSE btrim("description")
  END
WHERE "isManualAdjustment" = false
  AND "type" = 'ADJUSTMENT'
  AND "orderId" IS NULL
  AND ("idempotencyKey" IS NULL OR "idempotencyKey" NOT LIKE 'topup:%');

-- Create unique index & lookup indexes matching schema.prisma
CREATE INDEX IF NOT EXISTS "order_status_events_actorUserId_idx" ON "order_status_events"("actorUserId");
CREATE UNIQUE INDEX IF NOT EXISTS "order_status_events_orderId_eventKey_key" ON "order_status_events"("orderId", "eventKey");
CREATE INDEX IF NOT EXISTS "driver_wallet_transactions_driverId_isManualAdjustment_createdAt_idx" ON "driver_wallet_transactions"("driverId", "isManualAdjustment", "createdAt");
