-- Per-portion vendor pickup proof and confirmation.
--
-- Several vendors share a single delivery group or batched ride. Each vendor portion
-- must be verified and picked up sequentially with its own proof photo, timestamp,
-- and assigned driver.

ALTER TABLE "order_vendor_fulfillments"
    ADD COLUMN IF NOT EXISTS "pickupImageUrl" TEXT,
    ADD COLUMN IF NOT EXISTS "pickedUpAt" TIMESTAMPTZ(3),
    ADD COLUMN IF NOT EXISTS "pickedUpByDriverId" TEXT;
