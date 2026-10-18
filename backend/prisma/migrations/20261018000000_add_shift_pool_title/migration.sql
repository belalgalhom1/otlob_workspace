-- AlterTable
ALTER TABLE "shift_pools" ADD COLUMN "title" TEXT;
ALTER TABLE "shift_pools" ADD COLUMN "titleAr" TEXT;
ALTER TABLE "shift_pools" ADD COLUMN "batchId" TEXT;

-- CreateIndex
CREATE INDEX "shift_pools_batchId_idx" ON "shift_pools"("batchId");
