-- AlterTable
ALTER TABLE "platform_settings" ADD COLUMN "driverSettlementOrderThreshold" INTEGER NOT NULL DEFAULT 10;

-- AlterTable
ALTER TABLE "drivers" ADD COLUMN "ordersSinceSettlement" INTEGER NOT NULL DEFAULT 0;