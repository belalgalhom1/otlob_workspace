-- AlterTable
ALTER TABLE "platform_settings"
  ADD COLUMN IF NOT EXISTS "batchedDeliveryCommissionRate" INTEGER DEFAULT 40,
  ADD COLUMN IF NOT EXISTS "batchedDriverManagerCommissionRate" INTEGER DEFAULT 10,
  ADD COLUMN IF NOT EXISTS "multiVendorDeliveryCommissionRate" INTEGER DEFAULT 20,
  ADD COLUMN IF NOT EXISTS "multiVendorDriverManagerCommissionRate" INTEGER DEFAULT 10,
  ADD COLUMN IF NOT EXISTS "multiVendorDriverPercentage" INTEGER DEFAULT 70;
