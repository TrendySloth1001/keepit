-- File/image shares now reference an owner-side VaultItem so the encrypted
-- body can be streamed via /shares/:id/content instead of inlined as base64.
ALTER TABLE "VaultShare" ADD COLUMN "sourceItemId" TEXT;
