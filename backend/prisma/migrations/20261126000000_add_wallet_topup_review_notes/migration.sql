-- AlterTable
ALTER TABLE "wallet_top_up_requests"
  ADD COLUMN IF NOT EXISTS "notes" TEXT,
  ADD COLUMN IF NOT EXISTS "reviewedAt" TIMESTAMPTZ(3);
