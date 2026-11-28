ALTER TABLE "platform_settings"
  ADD COLUMN IF NOT EXISTS "staleOrderAlertIntervalMins" INTEGER NOT NULL DEFAULT 5;
