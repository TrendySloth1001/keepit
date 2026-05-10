-- Phase 2: collaborative shared folders. Members can post items; only the
-- creator may edit/delete their own item; activity log visible to all.

-- 1. CollabFolder: the folder itself.
CREATE TABLE "CollabFolder" (
  "id"        TEXT NOT NULL,
  "ownerId"   TEXT NOT NULL,
  "name"      TEXT NOT NULL,
  "iconKey"   TEXT,
  "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "updatedAt" TIMESTAMP(3) NOT NULL,
  CONSTRAINT "CollabFolder_pkey" PRIMARY KEY ("id")
);
ALTER TABLE "CollabFolder"
  ADD CONSTRAINT "CollabFolder_ownerId_fkey"
  FOREIGN KEY ("ownerId") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE;
CREATE INDEX "CollabFolder_ownerId_createdAt_idx"
  ON "CollabFolder"("ownerId", "createdAt" DESC);

-- 2. CollabMember: who is in the folder. Owner is auto-inserted at create.
CREATE TABLE "CollabMember" (
  "id"        TEXT NOT NULL,
  "folderId"  TEXT NOT NULL,
  "userId"    TEXT NOT NULL,
  "role"      TEXT NOT NULL DEFAULT 'member',
  "joinedAt"  TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT "CollabMember_pkey" PRIMARY KEY ("id")
);
ALTER TABLE "CollabMember"
  ADD CONSTRAINT "CollabMember_folderId_fkey"
  FOREIGN KEY ("folderId") REFERENCES "CollabFolder"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "CollabMember"
  ADD CONSTRAINT "CollabMember_userId_fkey"
  FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE;
CREATE UNIQUE INDEX "CollabMember_folderId_userId_key"
  ON "CollabMember"("folderId", "userId");
CREATE INDEX "CollabMember_userId_idx" ON "CollabMember"("userId");
CREATE INDEX "CollabMember_folderId_idx" ON "CollabMember"("folderId");

-- 3. CollabItem: an item posted into the folder.
CREATE TABLE "CollabItem" (
  "id"          TEXT NOT NULL,
  "folderId"    TEXT NOT NULL,
  "creatorId"   TEXT NOT NULL,
  "type"        "VaultItemType" NOT NULL,
  "title"       TEXT NOT NULL,
  "cipherBlob"  BYTEA NOT NULL,
  "cipherIv"    BYTEA NOT NULL,
  "createdAt"   TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "updatedAt"   TIMESTAMP(3) NOT NULL,
  CONSTRAINT "CollabItem_pkey" PRIMARY KEY ("id")
);
ALTER TABLE "CollabItem"
  ADD CONSTRAINT "CollabItem_folderId_fkey"
  FOREIGN KEY ("folderId") REFERENCES "CollabFolder"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "CollabItem"
  ADD CONSTRAINT "CollabItem_creatorId_fkey"
  FOREIGN KEY ("creatorId") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE;
CREATE INDEX "CollabItem_folderId_createdAt_idx"
  ON "CollabItem"("folderId", "createdAt" DESC);
CREATE INDEX "CollabItem_creatorId_idx" ON "CollabItem"("creatorId");

-- 4. CollabItemKey: per-member sealed copy of the item DEK.
CREATE TABLE "CollabItemKey" (
  "id"          TEXT NOT NULL,
  "itemId"      TEXT NOT NULL,
  "memberId"    TEXT NOT NULL,
  "userId"      TEXT NOT NULL,
  "wrappedKey"  BYTEA NOT NULL,
  CONSTRAINT "CollabItemKey_pkey" PRIMARY KEY ("id")
);
ALTER TABLE "CollabItemKey"
  ADD CONSTRAINT "CollabItemKey_itemId_fkey"
  FOREIGN KEY ("itemId") REFERENCES "CollabItem"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "CollabItemKey"
  ADD CONSTRAINT "CollabItemKey_memberId_fkey"
  FOREIGN KEY ("memberId") REFERENCES "CollabMember"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "CollabItemKey"
  ADD CONSTRAINT "CollabItemKey_userId_fkey"
  FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE;
CREATE UNIQUE INDEX "CollabItemKey_itemId_userId_key"
  ON "CollabItemKey"("itemId", "userId");
CREATE INDEX "CollabItemKey_userId_idx" ON "CollabItemKey"("userId");
CREATE INDEX "CollabItemKey_itemId_idx" ON "CollabItemKey"("itemId");

-- 5. CollabActivity: append-only audit log.
CREATE TABLE "CollabActivity" (
  "id"           TEXT NOT NULL,
  "folderId"     TEXT NOT NULL,
  "actorId"      TEXT NOT NULL,
  "action"       TEXT NOT NULL,
  "targetItemId" TEXT,
  "detail"       TEXT,
  "createdAt"    TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT "CollabActivity_pkey" PRIMARY KEY ("id")
);
ALTER TABLE "CollabActivity"
  ADD CONSTRAINT "CollabActivity_folderId_fkey"
  FOREIGN KEY ("folderId") REFERENCES "CollabFolder"("id") ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE "CollabActivity"
  ADD CONSTRAINT "CollabActivity_actorId_fkey"
  FOREIGN KEY ("actorId") REFERENCES "User"("id") ON DELETE CASCADE ON UPDATE CASCADE;
CREATE INDEX "CollabActivity_folderId_createdAt_idx"
  ON "CollabActivity"("folderId", "createdAt" DESC);
