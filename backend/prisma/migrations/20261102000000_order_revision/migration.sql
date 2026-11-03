-- Per-order monotonic revision used to order realtime order events.
-- Every status transition increments it inside the same transaction that
-- writes the status, so clients can reorder out-of-arrival socket events and
-- detect gaps. Backfilled to 0 for existing orders (they keep working; the
-- counter simply advances from the next transition onwards).
ALTER TABLE "orders" ADD COLUMN IF NOT EXISTS "revision" INTEGER NOT NULL DEFAULT 0;

-- Configurable TTL for dispatch-handoff dedupe markers (previously hard-coded
-- to 300s). Platform settings are a single row keyed by "default".
ALTER TABLE "platform_settings" ADD COLUMN IF NOT EXISTS "dispatchHandoffDedupeTtlSecs" INTEGER NOT NULL DEFAULT 300;
