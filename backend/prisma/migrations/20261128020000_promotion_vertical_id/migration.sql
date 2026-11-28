-- AlterTable
ALTER TABLE "promotions" ADD COLUMN "verticalId" TEXT;

-- CreateIndex
CREATE INDEX "promotions_verticalId_isActive_sortOrder_idx" ON "promotions"("verticalId", "isActive", "sortOrder");

-- AddForeignKey
ALTER TABLE "promotions" ADD CONSTRAINT "promotions_verticalId_fkey" FOREIGN KEY ("verticalId") REFERENCES "vendor_verticals"("id") ON DELETE SET NULL ON UPDATE CASCADE;
