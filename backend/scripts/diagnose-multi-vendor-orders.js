/* eslint-disable */
// READ-ONLY diagnostic for multi-vendor orders.
//
// Usage (from the backend folder, on the server that has DATABASE_URL):
//   node scripts/diagnose-multi-vendor-orders.js            -> last 5 orders with vendorId = NULL
//   node scripts/diagnose-multi-vendor-orders.js ORD-12345  -> one order by orderNumber
//
// It only runs SELECT queries. It prints, per order, how many vendor portions
// (fulfillments) and items exist and how items are linked to portions, which
// tells us whether a "1 vendor / no items" order is a data problem (creation)
// or a display problem (projection / apps).
require('dotenv').config();
const { Client } = require('pg');

(async () => {
  const url = String(process.env.DATABASE_URL || '').replace(/\?schema=[^&]*/, '');
  if (!url) throw new Error('DATABASE_URL is not set');
  const db = new Client({ connectionString: url });
  await db.connect();

  const orderNumber = process.argv[2];
  const { rows: orders } = orderNumber
    ? await db.query(
        `SELECT id, "orderNumber", "vendorId", type, status, "createdAt"
           FROM orders WHERE "orderNumber" = $1`,
        [orderNumber],
      )
    : await db.query(
        `SELECT id, "orderNumber", "vendorId", type, status, "createdAt"
           FROM orders WHERE "vendorId" IS NULL AND type = 'STANDARD'
          ORDER BY "createdAt" DESC LIMIT 5`,
      );

  if (orders.length === 0) console.log('No matching orders.');

  for (const o of orders) {
    const { rows: ff } = await db.query(
      `SELECT f.id, f."vendorId", v."storeName", f."vendorBranchId", f.status,
              (SELECT count(*)::int FROM order_items i WHERE i."fulfillmentId" = f.id) AS items,
              (SELECT count(*)::int FROM order_items i WHERE i."fulfillmentId" = f.id AND i."rejectedAt" IS NULL) AS live_items
         FROM order_vendor_fulfillments f
         LEFT JOIN vendors v ON v.id = f."vendorId"
        WHERE f."orderId" = $1 ORDER BY f."createdAt"`,
      [o.id],
    );
    const { rows: [counts] } = await db.query(
      `SELECT count(*)::int AS total,
              count(*) FILTER (WHERE "fulfillmentId" IS NULL)::int AS without_portion,
              count(*) FILTER (WHERE "rejectedAt" IS NOT NULL)::int AS rejected
         FROM order_items WHERE "orderId" = $1`,
      [o.id],
    );
    const { rows: groups } = await db.query(
      `SELECT g.sequence, g.status,
              (SELECT count(*)::int FROM order_delivery_group_items gi WHERE gi."deliveryGroupId" = g.id) AS stops
         FROM order_delivery_groups g WHERE g."orderId" = $1 ORDER BY g.sequence`,
      [o.id],
    );

    console.log('\n==========================================================');
    console.log(`Order ${o.orderNumber}  status=${o.status}  vendorId=${o.vendorId}  created=${o.createdAt.toISOString()}`);
    console.log(`Items: total=${counts.total} withoutPortion=${counts.without_portion} rejected=${counts.rejected}`);
    console.log(`Vendor portions (${ff.length}):`);
    console.table(ff.map((f) => ({ store: f.storeName, status: f.status, branch: f.vendorBranchId, items: f.items, liveItems: f.live_items })));
    console.log(`Delivery groups (${groups.length}):`);
    console.table(groups);
  }

  await db.end();
})().catch((e) => {
  console.error(e);
  process.exit(1);
});
