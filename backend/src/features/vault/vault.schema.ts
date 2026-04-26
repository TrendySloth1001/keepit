import { z } from "zod";

export const vaultItemTypeSchema = z.enum(["password", "note", "key", "file", "image"]);
export type VaultItemTypeInput = z.infer<typeof vaultItemTypeSchema>;

export const listVaultItemsSchema = z.object({
  type: vaultItemTypeSchema.optional(),
  cursor: z.string().cuid().optional(),
  limit: z.coerce.number().int().min(1).max(100).default(50),
});
export type ListVaultItemsInput = z.infer<typeof listVaultItemsSchema>;

const base64Bytes = z.string().regex(/^[A-Za-z0-9+/=]+$/);

export const createVaultItemSchema = z.object({
  type: vaultItemTypeSchema,
  title: z.string().min(1).max(200),
  cipherBlob: base64Bytes,
  cipherIv: base64Bytes,
});
export type CreateVaultItemInput = z.infer<typeof createVaultItemSchema>;

export const updateVaultItemSchema = z.object({
  title: z.string().min(1).max(200).optional(),
  cipherBlob: base64Bytes.optional(),
  cipherIv: base64Bytes.optional(),
});
export type UpdateVaultItemInput = z.infer<typeof updateVaultItemSchema>;

export const initiateUploadSchema = z.object({
  type: z.enum(["file", "image"]),
  title: z.string().min(1).max(200),
  cipherBlob: base64Bytes,
  cipherIv: base64Bytes,
  fileSize: z.number().int().positive(),
  fileMime: z.string().min(1).max(200),
});
export type InitiateUploadInput = z.infer<typeof initiateUploadSchema>;

export const finalizeUploadSchema = z.object({
  itemId: z.string().cuid(),
});
export type FinalizeUploadInput = z.infer<typeof finalizeUploadSchema>;
