-- Hot-path range scans that previously ran unindexed.
CREATE INDEX "shift_pools_startTime_idx" ON "shift_pools"("startTime");
CREATE INDEX "driver_shifts_status_endTime_idx" ON "driver_shifts"("status", "endTime");
CREATE INDEX "driver_shifts_status_warningSent_startTime_idx" ON "driver_shifts"("status", "warningSent", "startTime");
CREATE INDEX "driver_shifts_status_startTime_idx" ON "driver_shifts"("status", "startTime");
CREATE INDEX "wallet_top_up_requests_status_idx" ON "wallet_top_up_requests"("status");
CREATE INDEX "support_tickets_status_lastStatusUpdateAt_idx" ON "support_tickets"("status", "lastStatusUpdateAt");

-- Case-insensitive substring search (Prisma `contains … insensitive` lowers to
-- ILIKE '%…%') currently seq-scans vendors/drivers. Trigram GIN makes it indexed.
CREATE EXTENSION IF NOT EXISTS "pg_trgm";
CREATE INDEX "vendors_storeName_trgm_idx" ON "vendors" USING gin ("storeName" gin_trgm_ops);
CREATE INDEX "vendors_storeNameAr_trgm_idx" ON "vendors" USING gin ("storeNameAr" gin_trgm_ops);
CREATE INDEX "drivers_name_trgm_idx" ON "drivers" USING gin ("name" gin_trgm_ops);
