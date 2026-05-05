import { z } from "zod";

export const googleSignInSchema = z.object({
  idToken: z.string().min(1),
});

export type GoogleSignInInput = z.infer<typeof googleSignInSchema>;

export const masterInitSchema = z.object({
  salt: z.string().min(16).max(256),
  verifier: z.string().min(16).max(512),
  params: z.object({
    algo: z.literal("argon2id"),
    iterations: z.number().int().positive(),
    memoryKiB: z.number().int().positive(),
    parallelism: z.number().int().positive(),
    keyLength: z.number().int().positive(),
    version: z.number().int().nonnegative(),
  }),
});

export type MasterInitInput = z.infer<typeof masterInitSchema>;

export const masterVerifySchema = z.object({
  verifier: z.string().min(16).max(512),
});

export type MasterVerifyInput = z.infer<typeof masterVerifySchema>;

const base64 = z.string().regex(/^[A-Za-z0-9+/=_-]+$/);

export const masterRotateSchema = z.object({
  currentVerifier: z.string().min(16).max(512),
  newSalt: z.string().min(16).max(256),
  newVerifier: z.string().min(16).max(512),
  newParams: z.object({
    algo: z.literal("argon2id"),
    iterations: z.number().int().positive(),
    memoryKiB: z.number().int().positive(),
    parallelism: z.number().int().positive(),
    keyLength: z.number().int().positive(),
    version: z.number().int().nonnegative(),
  }),
  items: z
    .array(
      z.object({
        id: z.string().min(1),
        cipherBlob: base64,
        cipherIv: base64,
      }),
    )
    .max(10000),
  keypair: z
    .object({
      privateCipher: base64,
      privateIv: base64,
    })
    .optional(),
});

export type MasterRotateInput = z.infer<typeof masterRotateSchema>;
