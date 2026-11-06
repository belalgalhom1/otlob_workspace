-- CreateTable
CREATE TABLE "order_outbox" (
    "id" TEXT NOT NULL,
    "orderId" TEXT NOT NULL,
    "revision" INTEGER NOT NULL,
    "eventType" TEXT NOT NULL,
    "payload" JSONB NOT NULL,
    "createdAt" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "processedAt" TIMESTAMPTZ(3),

    CONSTRAINT "order_outbox_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE INDEX "order_outbox_processedAt_createdAt_idx" ON "order_outbox"("processedAt", "createdAt");

-- CreateIndex
CREATE INDEX "order_outbox_orderId_revision_idx" ON "order_outbox"("orderId", "revision");
