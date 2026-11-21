-- Replace legacy VAN & TRUCK vehicle types with service-specific Ride and Custom Delivery vehicle types:
--   RIDE:            MOTORCYCLE, CAR (Private Car), MINIBUS, TUK_TUK
--   CUSTOM_DELIVERY: MOTORCYCLE, MOTOR_TRICYCLE (Tricycle), QUARTER_TRUCK, HALF_TRUCK
--   STANDARD:        MOTORCYCLE, BICYCLE (preserved)

-- 1. Swap PostgreSQL enum "VehicleType" safely with deterministic legacy row mapping
--    (VAN -> QUARTER_TRUCK, TRUCK -> HALF_TRUCK)
DO $$
BEGIN
  IF EXISTS (
    SELECT 1
    FROM pg_enum e
    JOIN pg_type t ON t.oid = e.enumtypid
    WHERE t.typname = 'VehicleType'
      AND e.enumlabel IN ('VAN', 'TRUCK')
  ) OR NOT EXISTS (
    SELECT 1
    FROM pg_enum e
    JOIN pg_type t ON t.oid = e.enumtypid
    WHERE t.typname = 'VehicleType'
      AND e.enumlabel = 'MINIBUS'
  ) THEN
    CREATE TYPE "VehicleType_new" AS ENUM (
      'BICYCLE',
      'MOTORCYCLE',
      'CAR',
      'MINIBUS',
      'TUK_TUK',
      'MOTOR_TRICYCLE',
      'QUARTER_TRUCK',
      'HALF_TRUCK'
    );

    ALTER TABLE "drivers" ALTER COLUMN "vehicleType" DROP DEFAULT;

    ALTER TABLE "drivers"
      ALTER COLUMN "vehicleType" TYPE "VehicleType_new"
      USING (
        CASE "vehicleType"::text
          WHEN 'VAN' THEN 'QUARTER_TRUCK'
          WHEN 'TRUCK' THEN 'HALF_TRUCK'
          ELSE "vehicleType"::text
        END::"VehicleType_new"
      );

    ALTER TABLE "drivers"
      ALTER COLUMN "vehicleType" SET DEFAULT 'MOTORCYCLE'::"VehicleType_new";

    ALTER TABLE "orders"
      ALTER COLUMN "requestedVehicleType" TYPE "VehicleType_new"
      USING (
        CASE
          WHEN "requestedVehicleType" IS NULL THEN NULL
          WHEN "requestedVehicleType"::text = 'VAN' THEN 'QUARTER_TRUCK'::"VehicleType_new"
          WHEN "requestedVehicleType"::text = 'TRUCK' THEN 'HALF_TRUCK'::"VehicleType_new"
          ELSE "requestedVehicleType"::text::"VehicleType_new"
        END
      );

    DROP TYPE "VehicleType";
    ALTER TYPE "VehicleType_new" RENAME TO "VehicleType";
  END IF;
END $$;

-- 2. Add new per-vehicle platform settings columns
ALTER TABLE "platform_settings"
  ADD COLUMN IF NOT EXISTS "pricePerKmMinibus" INTEGER NOT NULL DEFAULT 8,
  ADD COLUMN IF NOT EXISTS "pricePerKmTukTuk" INTEGER NOT NULL DEFAULT 4,
  ADD COLUMN IF NOT EXISTS "pricePerKmQuarterTruck" INTEGER NOT NULL DEFAULT 8,
  ADD COLUMN IF NOT EXISTS "pricePerKmHalfTruck" INTEGER NOT NULL DEFAULT 12,
  ADD COLUMN IF NOT EXISTS "minDeliveryFeeMinibus" INTEGER NOT NULL DEFAULT 15,
  ADD COLUMN IF NOT EXISTS "maxDeliveryFeeMinibus" INTEGER NOT NULL DEFAULT 0,
  ADD COLUMN IF NOT EXISTS "minDeliveryFeeTukTuk" INTEGER NOT NULL DEFAULT 15,
  ADD COLUMN IF NOT EXISTS "maxDeliveryFeeTukTuk" INTEGER NOT NULL DEFAULT 0,
  ADD COLUMN IF NOT EXISTS "minDeliveryFeeQuarterTruck" INTEGER NOT NULL DEFAULT 15,
  ADD COLUMN IF NOT EXISTS "maxDeliveryFeeQuarterTruck" INTEGER NOT NULL DEFAULT 0,
  ADD COLUMN IF NOT EXISTS "minDeliveryFeeHalfTruck" INTEGER NOT NULL DEFAULT 15,
  ADD COLUMN IF NOT EXISTS "maxDeliveryFeeHalfTruck" INTEGER NOT NULL DEFAULT 0,
  ADD COLUMN IF NOT EXISTS "allowMinibus" BOOLEAN NOT NULL DEFAULT true,
  ADD COLUMN IF NOT EXISTS "allowTukTuk" BOOLEAN NOT NULL DEFAULT true,
  ADD COLUMN IF NOT EXISTS "allowQuarterTruck" BOOLEAN NOT NULL DEFAULT true,
  ADD COLUMN IF NOT EXISTS "allowHalfTruck" BOOLEAN NOT NULL DEFAULT true,
  ADD COLUMN IF NOT EXISTS "minibusIconUrl" TEXT,
  ADD COLUMN IF NOT EXISTS "tukTukIconUrl" TEXT,
  ADD COLUMN IF NOT EXISTS "quarterTruckIconUrl" TEXT,
  ADD COLUMN IF NOT EXISTS "halfTruckIconUrl" TEXT;

-- 3. Preserve existing VAN / TRUCK settings into QUARTER_TRUCK / HALF_TRUCK before dropping legacy columns
DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'platform_settings' AND column_name = 'pricePerKmVan'
  ) THEN
    UPDATE "platform_settings"
    SET
      "pricePerKmQuarterTruck" = COALESCE("pricePerKmVan", "pricePerKmQuarterTruck"),
      "minDeliveryFeeQuarterTruck" = COALESCE("minDeliveryFeeVan", "minDeliveryFeeQuarterTruck"),
      "maxDeliveryFeeQuarterTruck" = COALESCE("maxDeliveryFeeVan", "maxDeliveryFeeQuarterTruck"),
      "allowQuarterTruck" = COALESCE("allowVan", "allowQuarterTruck"),
      "quarterTruckIconUrl" = COALESCE("quarterTruckIconUrl", "vanIconUrl");
  END IF;

  IF EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'platform_settings' AND column_name = 'pricePerKmTruck'
  ) THEN
    UPDATE "platform_settings"
    SET
      "pricePerKmHalfTruck" = COALESCE("pricePerKmTruck", "pricePerKmHalfTruck"),
      "minDeliveryFeeHalfTruck" = COALESCE("minDeliveryFeeTruck", "minDeliveryFeeHalfTruck"),
      "maxDeliveryFeeHalfTruck" = COALESCE("maxDeliveryFeeTruck", "maxDeliveryFeeHalfTruck"),
      "allowHalfTruck" = COALESCE("allowTruck", "allowHalfTruck"),
      "halfTruckIconUrl" = COALESCE("halfTruckIconUrl", "truckIconUrl");
  END IF;
END $$;

-- 4. Remove legacy VAN / TRUCK columns from platform_settings
ALTER TABLE "platform_settings"
  DROP COLUMN IF EXISTS "pricePerKmVan",
  DROP COLUMN IF EXISTS "pricePerKmTruck",
  DROP COLUMN IF EXISTS "minDeliveryFeeVan",
  DROP COLUMN IF EXISTS "maxDeliveryFeeVan",
  DROP COLUMN IF EXISTS "minDeliveryFeeTruck",
  DROP COLUMN IF EXISTS "maxDeliveryFeeTruck",
  DROP COLUMN IF EXISTS "allowVan",
  DROP COLUMN IF EXISTS "allowTruck",
  DROP COLUMN IF EXISTS "vanIconUrl",
  DROP COLUMN IF EXISTS "truckIconUrl";
