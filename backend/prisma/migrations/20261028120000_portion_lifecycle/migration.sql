-- Per-portion vendor production state.
--
-- Several vendors can share a single delivery group, so production cannot be
-- tracked on the order (the aggregate) or on the delivery group (shared). These
-- timestamps keep "preparing" and "ready" scoped to exactly one vendor's
-- portion of the order.

ALTER TABLE "order_vendor_fulfillments"
    ADD COLUMN "preparingAt" TIMESTAMPTZ(3),
    ADD COLUMN "readyAt" TIMESTAMPTZ(3);
