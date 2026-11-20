-- Add driverRankingGoldThreshold and driverRankingSilverThreshold to platform_settings
ALTER TABLE "platform_settings"
  ADD COLUMN IF NOT EXISTS "driverRankingGoldThreshold" INTEGER NOT NULL DEFAULT 95,
  ADD COLUMN IF NOT EXISTS "driverRankingSilverThreshold" INTEGER NOT NULL DEFAULT 85;
