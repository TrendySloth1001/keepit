-- AlterTable
ALTER TABLE "VaultItem" ADD COLUMN "multipartUploadId" TEXT;

-- CreateTable
CREATE TABLE "VaultUploadPart" (
    "id" TEXT NOT NULL,
    "itemId" TEXT NOT NULL,
    "partNumber" INTEGER NOT NULL,
    "sizeBytes" BIGINT NOT NULL,
    "eTag" TEXT NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "VaultUploadPart_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "VaultUploadPart_itemId_partNumber_key" ON "VaultUploadPart"("itemId", "partNumber");

-- CreateIndex
CREATE INDEX "VaultUploadPart_itemId_idx" ON "VaultUploadPart"("itemId");

-- AddForeignKey
ALTER TABLE "VaultUploadPart" ADD CONSTRAINT "VaultUploadPart_itemId_fkey" FOREIGN KEY ("itemId") REFERENCES "VaultItem"("id") ON DELETE CASCADE ON UPDATE CASCADE;
