-- Partial unique indexes so soft-deleted users' credentials can be re-registered.
-- Drops the old full unique constraints (which blocked re-registration) and
-- replaces them with partial indexes that only enforce uniqueness among
-- non-deleted users.

ALTER TABLE "users" DROP CONSTRAINT IF EXISTS "User_email_key";
ALTER TABLE "users" DROP CONSTRAINT IF EXISTS "User_phone_key";

CREATE UNIQUE INDEX IF NOT EXISTS "users_email_active_unique"
  ON "users" ("email")
  WHERE "deletedAt" IS NULL;

CREATE UNIQUE INDEX IF NOT EXISTS "users_phone_active_unique"
  ON "users" ("phone")
  WHERE "deletedAt" IS NULL;
