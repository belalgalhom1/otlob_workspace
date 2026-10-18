require('dotenv').config();
const { PrismaClient } = require('@prisma/client');
const { Pool } = require('pg');
const { PrismaPg } = require('@prisma/adapter-pg');

const pool = new Pool({ connectionString: process.env.DATABASE_URL });
const prisma = new PrismaClient({ adapter: new PrismaPg(pool) });

(async () => {
  const zones = await prisma.$queryRaw`
    SELECT id, name, "isActive",
      ST_IsValid(boundary) AS valid,
      ST_SRID(boundary) AS srid,
      ST_GeometryType(boundary) AS gtype,
      round(ST_Area(boundary::geography)) AS area_m2,
      ST_XMin(boundary) AS xmin, ST_XMax(boundary) AS xmax,
      ST_YMin(boundary) AS ymin, ST_YMax(boundary) AS ymax
    FROM zones ORDER BY name
  `;
  console.log('=== ZONES ===');
  console.log(JSON.stringify(zones, null, 2));

  const shifts = await prisma.$queryRaw`
    SELECT s.id, s."zoneId", z.name AS zone_name, s.status, s."shiftDate",
      ST_X(d."lastLocation"::geometry) AS drv_lng,
      ST_Y(d."lastLocation"::geometry) AS drv_lat,
      CASE WHEN d."lastLocation" IS NULL THEN NULL
           ELSE ST_Contains(z.boundary, d."lastLocation"::geometry) END AS drv_in_shift_zone
    FROM driver_shifts s
    JOIN drivers d ON d.id = s."driverId"
    LEFT JOIN zones z ON z.id = s."zoneId"
    ORDER BY s."shiftDate" DESC
    LIMIT 15
  `;
  console.log('=== RECENT SHIFTS (driver lastLocation vs shift zone) ===');
  console.log(JSON.stringify(shifts, null, 2));

  await prisma.$disconnect();
  await pool.end();
})().catch((e) => { console.error(e); process.exit(1); });
