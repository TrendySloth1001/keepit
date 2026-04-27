import { z } from "zod";

export const updatePrivacyPolicySchema = z.object({
  version: z.string().min(1).max(64),
  title: z.string().min(1).max(200),
  content: z.string().min(64).max(100_000),
});

export type UpdatePrivacyPolicyInput = z.infer<typeof updatePrivacyPolicySchema>;

export const consentPrivacyPolicySchema = z.object({
  version: z.string().min(1).max(64),
  accepted: z.literal(true),
});

export type ConsentPrivacyPolicyInput = z.infer<typeof consentPrivacyPolicySchema>;
