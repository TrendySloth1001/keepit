import { z } from "zod";

// File/image shares now reference the owner's existing encrypted body in
// object storage instead of inlining it as base64 — so the share blob carries
// only metadata + per-file DEK. 256 KB is generously above what we need for
// any structured payload (passwords, notes, keys, file metadata).
const base64 = z
  .string()
  .min(1)
  .max(256_000)
  .regex(/^[A-Za-z0-9+/=_-]+$/, "Invalid base64 payload");

export const createShareSchema = z.object({
  recipientEmail: z.string().email().max(254),
  type: z.enum(["password", "note", "key", "file", "image"]),
  title: z.string().min(1).max(200),
  cipherBlob: base64,
  cipherIv: base64,
  // X25519 sealed-box wrap of the per-share DEK, base64.
  wrappedKey: base64,
  permission: z.enum(["view", "edit"]).default("view"),
  // Optional auto-expiry window in days; null/undefined means "no expiry".
  expiresInDays: z.number().int().min(1).max(365).optional(),
  // Required for file/image shares: the owner's vault item whose encrypted
  // body should be made available to the recipient via /shares/:id/content.
  // Ignored for non-file types.
  sourceItemId: z.string().min(1).max(64).optional(),
});
export type CreateShareInput = z.infer<typeof createShareSchema>;

export const lookupRecipientSchema = z.object({
  email: z.string().email().max(254),
});
export type LookupRecipientInput = z.infer<typeof lookupRecipientSchema>;

export const publishKeypairSchema = z.object({
  publicKey: base64,
  privateCipher: base64,
  privateIv: base64,
});
export type PublishKeypairInput = z.infer<typeof publishKeypairSchema>;

// Folder-share bundle: one recipient, N pre-sealed envelopes (each like the
// payload of POST /shares but without recipientEmail/expiresInDays — those
// are bundle-level). 50 items per bundle is a generous ceiling that comfortably
// fits the 36mb express.json limit even with file metadata blobs.
const bundleItemSchema = z.object({
  type: z.enum(["password", "note", "key", "file", "image"]),
  title: z.string().min(1).max(200),
  cipherBlob: base64,
  cipherIv: base64,
  wrappedKey: base64,
  sourceItemId: z.string().min(1).max(64).optional(),
});

export const createBundleSchema = z.object({
  recipientEmail: z.string().email().max(254),
  name: z.string().trim().min(1).max(80),
  permission: z.enum(["view", "edit"]).default("view"),
  expiresInDays: z.number().int().min(1).max(365).optional(),
  // Optional source folder pointer (owner-side, for the owner's own UI).
  sourceFolderId: z.string().min(1).max(64).optional(),
  items: z.array(bundleItemSchema).min(1).max(50),
});
export type CreateBundleInput = z.infer<typeof createBundleSchema>;
