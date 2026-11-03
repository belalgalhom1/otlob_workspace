-- Enforce the Order.revision invariant at the database boundary.
--
-- Contract: a revision identifies exactly one persisted state of an order.
-- Every transaction that writes Order.status must also advance revision by at
-- least one (application code bumps it explicitly so it can hand the persisted
-- value to the event it publishes). This trigger is the safety net for any
-- path that forgets:
--
--   * a status change that leaves revision untouched is auto-incremented, so
--     two distinct transitions can never share a revision;
--   * a decreasing revision is rejected outright, because it would make an
--     already-published event identity collide with a future one.
--
-- Explicit increments (status change + revision bump) are left untouched, as
-- are revision-only bumps used to publish one event per delivery group of the
-- same status transition.
CREATE OR REPLACE FUNCTION "orders_enforce_revision"()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW."revision" < OLD."revision" THEN
    RAISE EXCEPTION
      'orders.revision cannot decrease (order %, % -> %)',
      OLD."id", OLD."revision", NEW."revision"
      USING ERRCODE = 'check_violation';
  END IF;

  IF NEW."status" IS DISTINCT FROM OLD."status"
     AND NEW."revision" = OLD."revision" THEN
    NEW."revision" := OLD."revision" + 1;
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS "orders_enforce_revision" ON "orders";

CREATE TRIGGER "orders_enforce_revision"
  BEFORE UPDATE OF "status", "revision" ON "orders"
  FOR EACH ROW
  EXECUTE FUNCTION "orders_enforce_revision"();
