-- Multi-vendor explicit lifecycle states and intermediate pickup stage.
--
-- Adds PARTIALLY_PICKED_UP to OrderStatus and DeliveryGroupStatus to distinguish
-- multi-stop batch routes actively collecting goods from stores.
-- Adds PREPARING, READY_FOR_PICKUP, PICKED_UP to OrderVendorFulfillmentStatus for
-- explicit per-branch state machines.

ALTER TYPE "OrderStatus" ADD VALUE IF NOT EXISTS 'PARTIALLY_PICKED_UP' BEFORE 'PICKED_UP';
ALTER TYPE "DeliveryGroupStatus" ADD VALUE IF NOT EXISTS 'PARTIALLY_PICKED_UP' BEFORE 'PICKED_UP';
ALTER TYPE "OrderVendorFulfillmentStatus" ADD VALUE IF NOT EXISTS 'PREPARING' BEFORE 'REJECTED';
ALTER TYPE "OrderVendorFulfillmentStatus" ADD VALUE IF NOT EXISTS 'READY_FOR_PICKUP' BEFORE 'REJECTED';
ALTER TYPE "OrderVendorFulfillmentStatus" ADD VALUE IF NOT EXISTS 'PICKED_UP' BEFORE 'REJECTED';
