-- Concurrent addItem requests could both miss the manual merge lookup and
-- insert duplicate cart lines (double-charged at checkout). These partial
-- unique indexes make the merge atomic; the service catches P2002 and merges.
-- COALESCE on customPrice because NULLs never conflict in Postgres while the
-- merge lookup treats NULL = NULL.
CREATE UNIQUE INDEX "cart_items_product_merge_uidx"
  ON "cart_items"("cartId", "productId", COALESCE("optionHash", ''), "selectedUnit", COALESCE("customPrice", -1))
  WHERE "productId" IS NOT NULL;

CREATE UNIQUE INDEX "cart_items_custom_merge_uidx"
  ON "cart_items"("cartId", "customName", COALESCE("customPrice", -1))
  WHERE "productId" IS NULL;

-- Concurrent top-up submits could both pass the PENDING pre-check and create
-- two PENDING rows, crediting the wallet twice on approval.
CREATE UNIQUE INDEX "wallet_top_up_requests_pending_uidx"
  ON "wallet_top_up_requests"("driverId")
  WHERE "status" = 'PENDING';
