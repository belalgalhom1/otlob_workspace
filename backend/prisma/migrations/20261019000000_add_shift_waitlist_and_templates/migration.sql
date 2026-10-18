-- CreateTable
CREATE TABLE "shift_pool_waitlist" (
    "id" TEXT NOT NULL,
    "shiftPoolId" TEXT NOT NULL,
    "driverId" TEXT NOT NULL,
    "createdAt" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "shift_pool_waitlist_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "shift_templates" (
    "id" TEXT NOT NULL,
    "name" TEXT NOT NULL,
    "nameAr" TEXT,
    "title" TEXT,
    "titleAr" TEXT,
    "startTime" TEXT NOT NULL,
    "endTime" TEXT NOT NULL,
    "maxDrivers" INTEGER NOT NULL DEFAULT 1,
    "zoneId" TEXT,
    "createdAt" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMPTZ(3) NOT NULL,

    CONSTRAINT "shift_templates_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "shift_pool_waitlist_shiftPoolId_driverId_key" ON "shift_pool_waitlist"("shiftPoolId", "driverId");

-- CreateIndex
CREATE INDEX "shift_pool_waitlist_shiftPoolId_createdAt_idx" ON "shift_pool_waitlist"("shiftPoolId", "createdAt");

-- CreateIndex
CREATE INDEX "shift_templates_zoneId_idx" ON "shift_templates"("zoneId");

-- AddForeignKey
ALTER TABLE "shift_pool_waitlist" ADD CONSTRAINT "shift_pool_waitlist_shiftPoolId_fkey" FOREIGN KEY ("shiftPoolId") REFERENCES "shift_pools"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "shift_pool_waitlist" ADD CONSTRAINT "shift_pool_waitlist_driverId_fkey" FOREIGN KEY ("driverId") REFERENCES "drivers"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "shift_templates" ADD CONSTRAINT "shift_templates_zoneId_fkey" FOREIGN KEY ("zoneId") REFERENCES "zones"("id") ON DELETE SET NULL ON UPDATE CASCADE;
