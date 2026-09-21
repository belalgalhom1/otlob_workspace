-- Remove customer fee approval feature
ALTER TABLE "PlatformSetting"
DROP COLUMN "requireCustomerApproval",
DROP COLUMN "customerApprovalTimeoutMins",
DROP COLUMN "customerApprovalTimeoutSecs";

-- Remove the now-dead order status (never produced by any transition)
ALTER TYPE "OrderStatus" DROP VALUE 'PENDING_CUSTOMER_APPROVAL';