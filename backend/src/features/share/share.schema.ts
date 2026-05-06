import { z } from "zod";

// 32MB ceiling on the base64 cipherBlob is enough to inline a ~16MB encrypted
// file (base64 inflates ~37%) once W3.1 ships file/image sharing. Express body
// limit must match.
const base64 = z
  .string()
  .min(1)
  .max(32_000_000)
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
