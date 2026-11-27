-- Move workingHours, isScheduleActive, and is24Hours from vendors to vendor_branches,
-- backfilling every existing branch from its parent vendor before dropping vendor columns.

ALTER TABLE "vendor_branches"
ADD COLUMN "workingHours" JSONB,
ADD COLUMN "isScheduleActive" BOOLEAN NOT NULL DEFAULT true,
ADD COLUMN "is24Hours" BOOLEAN NOT NULL DEFAULT false;

UPDATE "vendor_branches" vb
SET
  "workingHours" = v."workingHours",
  "isScheduleActive" = v."isScheduleActive",
  "is24Hours" = v."is24Hours"
FROM "vendors" v
WHERE vb."vendorId" = v.id;

ALTER TABLE "vendors"
DROP COLUMN "workingHours",
DROP COLUMN "isScheduleActive",
DROP COLUMN "is24Hours";
