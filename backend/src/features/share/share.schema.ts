import { z } from "zod";

const base64 = z
  .string()
  .min(1)
  .max(2_000_000)
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
