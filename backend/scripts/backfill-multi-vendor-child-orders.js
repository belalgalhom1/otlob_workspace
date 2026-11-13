/* eslint-disable */
// BACKFILL child orders for multi-vendor parents created before the
// parent/child redesign. See earlier commit for context.
require('dotenv').config();
const { Client } = require('pg');
const { randomUUID } = require('crypto');

const apply = process.argv.includes('--apply');
const orderNumber = process.argv.find(
  (a) => a !== '--apply' && a.startsWith('ORD-'),
);

const childStatus = (f, groupStatus) => {
  if (f.status === 'REJECTED' || f.status === 'CANCELLED') return 'CANCELLED';
  if (f.deliveredAt) return 'DELIVERED';
  if (f.pickedUpAt || f.status === 'PICKED_UP') return 'PICKED_UP';
  if (f.readyAt || f.status === 'READY_FOR_PICKUP') return 'READY_FOR_PICKUP';
  if (f.preparingAt || f.status === 'PREPARING') return 'PREPARING';
  if (f.status === 'ACCEPTED') {
    switch (groupStatus) {
      case 'DELIVERED': return 'DELIVERED';
      case 'PICKED_UP':
      case 'PARTIALLY_PICKED_UP': return 'PICKED_UP';
      case 'READY_FOR_PICKUP': return 'READY_FOR_PICKUP';
      case 'DRIVER_ASSIGNED': return 'DRIVER_ASSIGNED';
      case 'PENDING_PAYMENT': return 'PENDING_PAYMENT';
      default: return 'ACCEPTED';
    }
  }
  return 'PENDING';
};

(async () => {
  const url = String(process.env.DATABASE_URL || '').replace(/\?schema=[^&]*/, '');
  if (!url) throw new Error('DATABASE_URL is not set');
  const db = new Client({ connectionString: url });
  await db.connect();

  const { rows: parents } = orderNumber
    ? await db.query(
        `SELECT o.id, o."orderNumber", o."createdAt"
           FROM orders o
          WHERE o."orderNumber" = $1
            AND o."parentOrderId" IS NULL AND o."vendorId" IS NULL`,
        [orderNumber],
      )
    : await db.query(
        `SELECT o.id, o."orderNumber", o."createdAt"
           FROM orders o
          WHERE o."parentOrderId" IS NULL
            AND o."vendorId" IS NULL
            AND o.type = 'STANDARD'
            AND EXISTS (SELECT 1 FROM order_vendor_fulfillments f WHERE f."orderId" = o.id)
            AND NOT EXISTS (SELECT 1 FROM orders c WHERE c."parentOrderId" = o.id)
          ORDER BY o."createdAt"`,
      );

  if (parents.length === 0) {
    console.log('No parent orders need backfilling.');
    await db.end();
    return;
  }

  const report = [];

  for (const parent of parents) {
    const { rows: fulfillments } = await db.query(
      `SELECT f.id, f."vendorId", f."vendorBranchId", f.status, f.subtotal,
              f."decidedAt", f."preparingAt", f."readyAt", f."pickedUpAt",
              f."deliveredAt"
         FROM order_vendor_fulfillments f
        WHERE f."orderId" = $1
        ORDER BY f."createdAt"`,
      [parent.id],
    );

    for (const f of fulfillments) {
      const { rows: existing } = await db.query(
        `SELECT 1 FROM orders
          WHERE "parentOrderId" = $1
            AND "vendorId" = $2
            AND "vendorBranchId" IS NOT DISTINCT FROM $3
          LIMIT 1`,
        [parent.id, f.vendorId, f.vendorBranchId],
      );
      if (existing.length > 0) {
        report.push({ parent: parent.orderNumber, vendorId: f.vendorId, action: 'skip (child exists)' });
        continue;
      }

      const { rows: groups } = await db.query(
        `SELECT g.status
           FROM order_delivery_group_items gi
           JOIN order_delivery_groups g ON g.id = gi."deliveryGroupId"
          WHERE gi."fulfillmentId" = $1
          ORDER BY g.sequence
          LIMIT 1`,
        [f.id],
      );
      const status = childStatus(f, groups[0]?.status);
      const { rows: items } = await db.query(
        `SELECT id FROM order_items WHERE "fulfillmentId" = $1`,
        [f.id],
      );

      report.push({
        parent: parent.orderNumber,
        vendorId: f.vendorId,
        branchId: f.vendorBranchId,
        status,
        subtotal: f.subtotal,
        items: items.length,
        action: apply ? 'create' : 'would create',
      });
      if (!apply) continue;

      const childId = randomUUID();
      await db.query('BEGIN');
      try {
        await db.query(
          `INSERT INTO orders (
             id, "parentOrderId", "sourceFulfillmentId", type, "customerId",
             "vendorId", "vendorBranchId", "zoneId", status, "paymentMethod",
             "paymentStatus", "deliveryAddress", "deliveryLocation",
             subtotal, "deliveryFee", "driverBonusFee", "serviceFee", tax,
             discount, "coinsUsed", "coinsEarned", "grandTotal", "upfrontAmount",
             "specialRequest", "acceptedAt", "preparedAt", "pickedUpAt",
             "actualDeliveryTime", "createdAt", "updatedAt"
           )
           SELECT $1, o.id, $2, 'STANDARD'::"OrderType", o."customerId",
                  $3, $4, o."zoneId", $5::"OrderStatus", o."paymentMethod",
                  o."paymentStatus", o."deliveryAddress", o."deliveryLocation",
                  $6, 0, 0, 0, 0, 0, 0, 0, $6, 0,
                  o."specialRequest", $7, $8, $9, $10, o."createdAt", NOW()
             FROM orders o
            WHERE o.id = $11`,
          [
            childId,
            f.id,
            f.vendorId,
            f.vendorBranchId,
            status,
            f.subtotal,
            f.decidedAt,
            f.readyAt ?? f.preparingAt,
            f.pickedUpAt,
            f.deliveredAt,
            parent.id,
          ],
        );

        const { rows: oldItems } = await db.query(
          `SELECT * FROM order_items WHERE "fulfillmentId" = $1`,
          [f.id],
        );
        for (const item of oldItems) {
          const childItemId = randomUUID();
          await db.query(
            `INSERT INTO order_items (
               id, "orderId", "fulfillmentId", "productId", "variantId",
               "productName", "variantName", "unitPrice", quantity,
               "selectedUnit", "baseUnitPrice", "totalPrice", "specialRequest",
               "rejectedAt"
             ) VALUES ($1,$2,NULL,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13)`,
            [
              childItemId,
              childId,
              item.productId,
              item.variantId,
              item.productName,
              item.variantName,
              item.unitPrice,
              item.quantity,
              item.selectedUnit,
              item.baseUnitPrice,
              item.totalPrice,
              item.specialRequest,
              item.rejectedAt,
            ],
          );
          const { rows: options } = await db.query(
            `SELECT "optionId", "optionName", "groupName", "priceAdded"
               FROM order_item_options WHERE "orderItemId" = $1`,
            [item.id],
          );
          for (const option of options) {
            await db.query(
              `INSERT INTO order_item_options (
                 id, "orderItemId", "optionId", "optionName", "groupName", "priceAdded"
               ) VALUES ($1,$2,$3,$4,$5,$6)`,
              [
                randomUUID(),
                childItemId,
                option.optionId,
                option.optionName,
                option.groupName,
                option.priceAdded,
              ],
            );
          }
        }

        await db.query(
          `INSERT INTO order_status_events (id, "orderId", status, note, "createdAt")
           VALUES ($1, $2, $3::"OrderStatus",
                   'Backfilled child order from multi-vendor parent', NOW())`,
          [randomUUID(), childId, status],
        );
        await db.query('COMMIT');
      } catch (error) {
        await db.query('ROLLBACK');
        throw error;
      }
    }
  }

  console.table(report);
  if (!apply) {
    console.log('\nDry run only. Re-run with --apply to create the child orders above.');
  }
  await db.end();
})().catch((e) => {
  console.error(e);
  process.exit(1);
});
