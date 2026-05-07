-- Phase 1: vault folders + read-only folder-share bundles + share read receipts.

-- 1. VaultFolder: per-user organization. Plaintext name (mirrors VaultItem.title).
CREATE TABLE "VaultFolder" (
  "id"        TEXT NOT NULL,
  "userId"    TEXT NOT NULL,
  "name"      TEXT NOT NULL,
  "iconKey"   TEXT,
  "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "updatedAt" TIMESTAMP(3) NOT NULL,
  CONSTRAINT "VaultFolder_pkey" PRIMARY KEY ("id")
);
ALTER TABLE "VaultFolder"
  ADD CONSTRAINT "VaultFolder_userId_fkey"
  FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE;
CREATE INDEX "VaultFolder_userId_createdAt_idx"
  ON "VaultFolder"("userId", "createdAt" DESC);

-- 2. VaultItem.folderId: SET NULL on folder delete (folders are pure org).
ALTER TABLE "VaultItem" ADD COLUMN "folderId" TEXT;
ALTER TABLE "VaultItem"
  ADD CONSTRAINT "VaultItem_folderId_fkey"
  FOREIGN KEY ("folderId") REFERENCES "VaultFolder"("id") ON DELETE SET NULL ON UPDATE CASCADE;
CREATE INDEX "VaultItem_userId_folderId_updatedAt_idx"
  ON "VaultItem"("userId", "folderId", "updatedAt" DESC);

-- 3. VaultShareBundle: groups N share rows under one folder snapshot.
CREATE TABLE "VaultShareBundle" (
  "id"             TEXT NOT NULL,
  "ownerId"        TEXT NOT NULL,
  "recipientId"    TEXT NOT NULL,
  "name"           TEXT NOT NULL,
  "sourceFolderId" TEXT,
  "createdAt"      TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "expiresAt"      TIMESTAMP(3),
  "revokedAt"      TIMESTAMP(3),
  CONSTRAINT "VaultShareBundle_pkey" PRIMARY KEY ("id")
);
ALTER TABLE "VaultShareBundle"
  ADD CONSTRAINT "VaultShareBundle_ownerId_fkey"
  FOREIGN KEY ("ownerId") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "VaultShareBundle"
  ADD CONSTRAINT "VaultShareBundle_recipientId_fkey"
  FOREIGN KEY ("recipientId") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE;
CREATE INDEX "VaultShareBundle_ownerId_createdAt_idx"
  ON "VaultShareBundle"("ownerId", "createdAt" DESC);
CREATE INDEX "VaultShareBundle_recipientId_revokedAt_expiresAt_createdAt_idx"
  ON "VaultShareBundle"("recipientId", "revokedAt", "expiresAt", "createdAt" DESC);

-- 4. VaultShare: bundle FK + read-receipt columns.
ALTER TABLE "VaultShare" ADD COLUMN "bundleId" TEXT;
ALTER TABLE "VaultShare" ADD COLUMN "firstOpenedAt" TIMESTAMP(3);
ALTER TABLE "VaultShare" ADD COLUMN "lastOpenedAt"  TIMESTAMP(3);
ALTER TABLE "VaultShare" ADD COLUMN "openCount"     INTEGER NOT NULL DEFAULT 0;
ALTER TABLE "VaultShare"
  ADD CONSTRAINT "VaultShare_bundleId_fkey"
  FOREIGN KEY ("bundleId") REFERENCES "VaultShareBundle"("id") ON DELETE SET NULL ON UPDATE CASCADE;
CREATE INDEX "VaultShare_bundleId_idx" ON "VaultShare"("bundleId");
