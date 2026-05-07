import { z } from "zod";

export const vaultItemTypeSchema = z.enum(["password", "note", "key", "file", "image"]);
export type VaultItemTypeInput = z.infer<typeof vaultItemTypeSchema>;

const csvEnum = <T extends z.ZodTypeAny>(schema: T) =>
  z
    .union([z.string(), z.array(z.string())])
    .optional()
    .transform((v) => {
      if (!v) return undefined;
      const arr = Array.isArray(v) ? v : v.split(",");
      return arr.map((s) => s.trim()).filter(Boolean);
    })
    .pipe(z.array(schema).optional());

export const listVaultItemsSchema = z.object({
  // legacy single-type filter (kept for back-compat)
  type: vaultItemTypeSchema.optional(),
  // multi-type filter, e.g. ?types=password,note
  types: csvEnum(vaultItemTypeSchema),
  // case-insensitive title search
  q: z.string().trim().min(1).max(200).optional(),
  // ISO timestamps
  since: z.coerce.date().optional(),
  until: z.coerce.date().optional(),
  // sort order
  sort: z.enum(["updated_desc", "updated_asc", "created_desc", "created_asc", "title_asc", "title_desc"]).default("updated_desc"),
  cursor: z.string().cuid().optional(),
  limit: z.coerce.number().int().min(1).max(100).default(50),
  // Folder filter. A cuid filters to that folder; the literal "none" filters
  // to items with no folder (uncategorized). Undefined returns all items.
  folderId: z.union([z.string().cuid(), z.literal("none")]).optional(),
});
export type ListVaultItemsInput = z.infer<typeof listVaultItemsSchema>;

export const batchIdsSchema = z.object({
  ids: z.array(z.string().cuid()).min(1).max(200),
});
export type BatchIdsInput = z.infer<typeof batchIdsSchema>;

export const statsRangeSchema = z.object({
  bucket: z.enum(["day", "week", "month"]).default("day"),
  since: z.coerce.date().optional(),
  until: z.coerce.date().optional(),
});
export type StatsRangeInput = z.infer<typeof statsRangeSchema>;

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
  // null clears the folder link; undefined leaves it untouched.
  folderId: z.string().cuid().nullable().optional(),
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

export const uploadChunkParamsSchema = z.object({
  itemId: z.string().cuid(),
  partNumber: z.coerce.number().int().min(1).max(10000),
});
export type UploadChunkParamsInput = z.infer<typeof uploadChunkParamsSchema>;
