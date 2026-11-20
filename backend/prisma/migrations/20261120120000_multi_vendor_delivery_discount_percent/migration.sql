-- Add multi-vendor delivery bundle discount percentage and remove fixed extraVendorDeliveryFee
ALTER TABLE "platform_settings"
  ADD COLUMN IF NOT EXISTS "multiVendorDeliveryDiscountPercent" INTEGER NOT NULL DEFAULT 20;

ALTER TABLE "platform_settings"
  DROP COLUMN IF EXISTS "extraVendorDeliveryFee";
