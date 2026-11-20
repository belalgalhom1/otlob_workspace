-- Weekly Driver Ranking System & Delivery Incident Accountability

DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'DriverRankingRunStatus') THEN
    CREATE TYPE "DriverRankingRunStatus" AS ENUM ('RUNNING', 'COMPLETED', 'FAILED');
  END IF;

  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'DriverRankingTriggerSource') THEN
    CREATE TYPE "DriverRankingTriggerSource" AS ENUM ('SCHEDULED', 'MANUAL');
  END IF;

  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'DriverRankChangeReason') THEN
    CREATE TYPE "DriverRankChangeReason" AS ENUM ('WEEKLY_EVALUATION', 'INACTIVE_DRIVER', 'ADMIN_OVERRIDE');
  END IF;

  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'DeliveryIncidentType') THEN
    CREATE TYPE "DeliveryIncidentType" AS ENUM ('ORDER_CANCELLED', 'DRIVER_REASSIGNED', 'DRIVER_UNASSIGNED', 'DELIVERY_FAILURE');
  END IF;

  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'DeliveryIncidentResponsibility') THEN
    CREATE TYPE "DeliveryIncidentResponsibility" AS ENUM ('DRIVER_AT_FAULT', 'CUSTOMER', 'VENDOR', 'EXTERNAL_OR_SYSTEM', 'UNDER_REVIEW');
  END IF;
END $$;

-- Schedule controls in platform_settings
ALTER TABLE "platform_settings"
  ADD COLUMN IF NOT EXISTS "driverRankingAutoEvalEnabled" BOOLEAN NOT NULL DEFAULT true,
  ADD COLUMN IF NOT EXISTS "driverRankingEvalTime" TEXT NOT NULL DEFAULT '00:05';

-- Excused shift tracking in driver_shifts
ALTER TABLE "driver_shifts"
  ADD COLUMN IF NOT EXISTS "isExcused" BOOLEAN NOT NULL DEFAULT false,
  ADD COLUMN IF NOT EXISTS "excuseReason" TEXT,
  ADD COLUMN IF NOT EXISTS "excusedByUserId" TEXT,
  ADD COLUMN IF NOT EXISTS "excusedAt" TIMESTAMPTZ(3);

-- Weekly ranking evaluation runs
CREATE TABLE IF NOT EXISTS "driver_ranking_evaluation_runs" (
  "id" TEXT NOT NULL,
  "periodKey" TEXT NOT NULL,
  "status" "DriverRankingRunStatus" NOT NULL DEFAULT 'RUNNING',
  "triggerSource" "DriverRankingTriggerSource" NOT NULL DEFAULT 'SCHEDULED',
  "triggeredByUserId" TEXT,
  "scheduledFor" TIMESTAMPTZ(3) NOT NULL,
  "executedAt" TIMESTAMPTZ(3),
  "periodStart" TIMESTAMPTZ(3) NOT NULL,
  "periodEnd" TIMESTAMPTZ(3) NOT NULL,
  "totalDrivers" INTEGER NOT NULL DEFAULT 0,
  "promotedCount" INTEGER NOT NULL DEFAULT 0,
  "demotedCount" INTEGER NOT NULL DEFAULT 0,
  "unchangedCount" INTEGER NOT NULL DEFAULT 0,
  "inactiveCount" INTEGER NOT NULL DEFAULT 0,
  "errorMessage" TEXT,
  "createdAt" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "updatedAt" TIMESTAMPTZ(3) NOT NULL,

  CONSTRAINT "driver_ranking_evaluation_runs_pkey" PRIMARY KEY ("id")
);

CREATE UNIQUE INDEX IF NOT EXISTS "driver_ranking_evaluation_runs_periodKey_key"
  ON "driver_ranking_evaluation_runs"("periodKey");
CREATE INDEX IF NOT EXISTS "driver_ranking_evaluation_runs_status_createdAt_idx"
  ON "driver_ranking_evaluation_runs"("status", "createdAt");

-- Immutable driver rank history log
CREATE TABLE IF NOT EXISTS "driver_rank_history" (
  "id" TEXT NOT NULL,
  "driverId" TEXT NOT NULL,
  "runId" TEXT,
  "evaluatedAt" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "periodStart" TIMESTAMPTZ(3),
  "periodEnd" TIMESTAMPTZ(3),
  "performancePercentage" DOUBLE PRECISION,
  "metricsSnapshot" JSONB,
  "previousTier" "DriverTier" NOT NULL,
  "newTier" "DriverTier" NOT NULL,
  "changeReason" "DriverRankChangeReason" NOT NULL,
  "adminUserId" TEXT,
  "overrideReason" TEXT,
  "createdAt" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

  CONSTRAINT "driver_rank_history_pkey" PRIMARY KEY ("id")
);

CREATE UNIQUE INDEX IF NOT EXISTS "driver_rank_history_runId_driverId_key"
  ON "driver_rank_history"("runId", "driverId");
CREATE INDEX IF NOT EXISTS "driver_rank_history_driverId_evaluatedAt_idx"
  ON "driver_rank_history"("driverId", "evaluatedAt");

-- Structured cancellation / reassignment responsibility ledger
CREATE TABLE IF NOT EXISTS "driver_delivery_incidents" (
  "id" TEXT NOT NULL,
  "orderId" TEXT NOT NULL,
  "deliveryGroupId" TEXT NOT NULL,
  "driverId" TEXT NOT NULL,
  "incidentType" "DeliveryIncidentType" NOT NULL,
  "responsibility" "DeliveryIncidentResponsibility" NOT NULL,
  "reason" TEXT,
  "reportedByUserId" TEXT,
  "reviewedByUserId" TEXT,
  "reviewedAt" TIMESTAMPTZ(3),
  "reviewNote" TEXT,
  "occurredAt" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "createdAt" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "updatedAt" TIMESTAMPTZ(3) NOT NULL,

  CONSTRAINT "driver_delivery_incidents_pkey" PRIMARY KEY ("id")
);

CREATE INDEX IF NOT EXISTS "driver_delivery_incidents_driverId_occurredAt_idx"
  ON "driver_delivery_incidents"("driverId", "occurredAt");
CREATE INDEX IF NOT EXISTS "driver_delivery_incidents_responsibility_occurredAt_idx"
  ON "driver_delivery_incidents"("responsibility", "occurredAt");

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint WHERE conname = 'driver_rank_history_driverId_fkey'
  ) THEN
    ALTER TABLE "driver_rank_history"
      ADD CONSTRAINT "driver_rank_history_driverId_fkey"
      FOREIGN KEY ("driverId") REFERENCES "drivers"("id") ON DELETE CASCADE ON UPDATE CASCADE;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint WHERE conname = 'driver_rank_history_runId_fkey'
  ) THEN
    ALTER TABLE "driver_rank_history"
      ADD CONSTRAINT "driver_rank_history_runId_fkey"
      FOREIGN KEY ("runId") REFERENCES "driver_ranking_evaluation_runs"("id") ON DELETE CASCADE ON UPDATE CASCADE;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint WHERE conname = 'driver_delivery_incidents_orderId_fkey'
  ) THEN
    ALTER TABLE "driver_delivery_incidents"
      ADD CONSTRAINT "driver_delivery_incidents_orderId_fkey"
      FOREIGN KEY ("orderId") REFERENCES "orders"("id") ON DELETE CASCADE ON UPDATE CASCADE;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint WHERE conname = 'driver_delivery_incidents_deliveryGroupId_fkey'
  ) THEN
    ALTER TABLE "driver_delivery_incidents"
      ADD CONSTRAINT "driver_delivery_incidents_deliveryGroupId_fkey"
      FOREIGN KEY ("deliveryGroupId") REFERENCES "order_delivery_groups"("id") ON DELETE CASCADE ON UPDATE CASCADE;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint WHERE conname = 'driver_delivery_incidents_driverId_fkey'
  ) THEN
    ALTER TABLE "driver_delivery_incidents"
      ADD CONSTRAINT "driver_delivery_incidents_driverId_fkey"
      FOREIGN KEY ("driverId") REFERENCES "drivers"("id") ON DELETE CASCADE ON UPDATE CASCADE;
  END IF;
END $$;

-- Composite indexes for weekly ranking batch queries
CREATE INDEX IF NOT EXISTS "order_delivery_groups_primaryDriverId_status_deliveredAt_idx"
  ON "order_delivery_groups"("primaryDriverId", "status", "deliveredAt");
CREATE INDEX IF NOT EXISTS "driver_shifts_driverId_startTime_idx"
  ON "driver_shifts"("driverId", "startTime");
CREATE INDEX IF NOT EXISTS "order_dispatches_driverId_createdAt_idx"
  ON "order_dispatches"("driverId", "createdAt");
