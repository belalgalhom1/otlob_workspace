ALTER TABLE "driver_manager_wallet_transactions"
  ADD COLUMN IF NOT EXISTS "receiptUrl" TEXT,
  ADD COLUMN IF NOT EXISTS "processedById" TEXT;

DO $$ BEGIN
  ALTER TABLE "driver_manager_wallet_transactions"
    ADD CONSTRAINT "driver_manager_wallet_transactions_processedById_fkey"
    FOREIGN KEY ("processedById") REFERENCES "users"("id")
    ON DELETE SET NULL ON UPDATE CASCADE;
EXCEPTION
  WHEN duplicate_object THEN NULL;
END $$;
