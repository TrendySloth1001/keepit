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
