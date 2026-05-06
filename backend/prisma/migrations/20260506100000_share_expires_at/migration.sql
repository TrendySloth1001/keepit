-- Add optional expiry to shares so the recipient (and the owner's "sent" list)
-- can auto-drop a share after its time-to-live elapses. NULL means no expiry.
ALTER TABLE "VaultShare" ADD COLUMN "expiresAt" TIMESTAMP(3);

-- Drop and recreate the secondary indexes so the planner can use expiresAt
-- alongside the existing scan keys.
DROP INDEX IF EXISTS "VaultShare_recipientId_revokedAt_createdAt_idx";
DROP INDEX IF EXISTS "VaultShare_ownerId_createdAt_idx";

CREATE INDEX "VaultShare_recipientId_revokedAt_expiresAt_createdAt_idx"
  ON "VaultShare" ("recipientId", "revokedAt", "expiresAt", "createdAt" DESC);

CREATE INDEX "VaultShare_ownerId_expiresAt_createdAt_idx"
  ON "VaultShare" ("ownerId", "expiresAt", "createdAt" DESC);
