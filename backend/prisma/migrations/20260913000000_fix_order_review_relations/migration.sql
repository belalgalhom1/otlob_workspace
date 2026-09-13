-- AlterTable (FK reference changes for order_reviews)
-- customerId and driverId previously pointed at Customer.userId / Driver.userId,
-- but reviews code stores Customer.id / Driver.id (consistent with the rest of the schema).
ALTER TABLE "order_reviews" DROP CONSTRAINT "order_reviews_customerId_fkey";
ALTER TABLE "order_reviews" ADD CONSTRAINT "order_reviews_customerId_fkey" FOREIGN KEY ("customerId") REFERENCES "customers"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

ALTER TABLE "order_reviews" DROP CONSTRAINT "order_reviews_driverId_fkey";
ALTER TABLE "order_reviews" ADD CONSTRAINT "order_reviews_driverId_fkey" FOREIGN KEY ("driverId") REFERENCES "drivers"("id") ON DELETE SET NULL ON UPDATE CASCADE;