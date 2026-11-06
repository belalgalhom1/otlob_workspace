-- Drop old order_outbox if exists
DROP TABLE IF EXISTS "order_outbox";

-- CreateTable
CREATE TABLE "outbox" (
    "id" TEXT NOT NULL,
    "aggregateType" TEXT NOT NULL,
    "aggregateId" TEXT NOT NULL,
    "version" INTEGER NOT NULL DEFAULT 0,
    "eventType" TEXT NOT NULL,
    "jobName" TEXT NOT NULL,
    "dedupeKey" TEXT,
    "queueName" TEXT,
    "payload" JSONB NOT NULL,
    "createdAt" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "processedAt" TIMESTAMPTZ(3),

    CONSTRAINT "outbox_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE INDEX "outbox_processedAt_createdAt_idx" ON "outbox"("processedAt", "createdAt");

-- CreateIndex
CREATE INDEX "outbox_aggregateType_aggregateId_version_idx" ON "outbox"("aggregateType", "aggregateId", "version");
