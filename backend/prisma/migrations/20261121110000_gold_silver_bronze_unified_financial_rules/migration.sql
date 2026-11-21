-- Unified Gold / Silver / Bronze Financial Rules Across Standard Orders, Rides & Custom Delivery

-- 1. Platform Settings: Remove legacy per-km tier bonuses (Silver is default baseline;
-- Gold is a fixed per-order addition to total delivery cost; Bronze uses fixed deductions)
ALTER TABLE "platform_settings"
  DROP COLUMN IF EXISTS "bronzeTierBonusPerKm",
  DROP COLUMN IF EXISTS "silverTierBonusPerKm",
  DROP COLUMN IF EXISTS "goldTierBonusPerKm",
  ADD COLUMN IF NOT EXISTS "goldTierBonusPerOrder" DOUBLE PRECISION NOT NULL DEFAULT 0,
  ADD COLUMN IF NOT EXISTS "bronzeTierDeductionAmount" DOUBLE PRECISION NOT NULL DEFAULT 0,
  ADD COLUMN IF NOT EXISTS "bronzeSupervisorDeductionAmount" DOUBLE PRECISION NOT NULL DEFAULT 0;

-- 2. Orders: immutable surcharge & settlement snapshot columns
ALTER TABLE "orders"
  ADD COLUMN IF NOT EXISTS "goldSurchargeAmount" INTEGER NOT NULL DEFAULT 0,
  ADD COLUMN IF NOT EXISTS "settledGoldBonusAmount" INTEGER NOT NULL DEFAULT 0,
  ADD COLUMN IF NOT EXISTS "settledGoldPlatformRetainedAmount" INTEGER NOT NULL DEFAULT 0,
  ADD COLUMN IF NOT EXISTS "settledBronzeDriverDeduction" INTEGER NOT NULL DEFAULT 0,
  ADD COLUMN IF NOT EXISTS "settledBronzeSupervisorDeduction" INTEGER NOT NULL DEFAULT 0,
  ADD COLUMN IF NOT EXISTS "settledBronzeDriverDeductionRate" DOUBLE PRECISION,
  ADD COLUMN IF NOT EXISTS "settledBronzeSupervisorDeductionRate" DOUBLE PRECISION;

-- 3. Order Delivery Groups: immutable tier, surcharge & settlement snapshot columns
ALTER TABLE "order_delivery_groups"
  ADD COLUMN IF NOT EXISTS "goldSurchargeAmount" INTEGER NOT NULL DEFAULT 0,
  ADD COLUMN IF NOT EXISTS "primaryDriverTierSnapshot" "DriverTier",
  ADD COLUMN IF NOT EXISTS "settledGoldBonusAmount" INTEGER NOT NULL DEFAULT 0,
  ADD COLUMN IF NOT EXISTS "settledGoldPlatformRetainedAmount" INTEGER NOT NULL DEFAULT 0,
  ADD COLUMN IF NOT EXISTS "settledBronzeDriverDeduction" INTEGER NOT NULL DEFAULT 0,
  ADD COLUMN IF NOT EXISTS "settledBronzeSupervisorDeduction" INTEGER NOT NULL DEFAULT 0,
  ADD COLUMN IF NOT EXISTS "settledPrimaryManagerId" TEXT;
