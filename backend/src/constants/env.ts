import { z } from "zod";

const envSchema = z.object({
  NODE_ENV: z.enum(["development", "production", "test"]).default("development"),
  PORT: z.coerce.number().int().positive().default(3009),
  POSTGRES_URL: z.string().min(1),
  MINIO_ENDPOINT: z.string().url().default("http://localhost:9000"),
  MINIO_PUBLIC_ENDPOINT: z.string().url().optional(),
  MINIO_BUCKET: z.string().min(1).default("keepit"),
  MINIO_ACCESS_KEY: z.string().min(1).default("keepitadmin"),
  MINIO_SECRET_KEY: z.string().min(1).default("keepitsecret"),
  MINIO_REGION: z.string().min(1).default("us-east-1"),
  MINIO_USE_SSL: z.coerce.boolean().default(false),
  GOOGLE_CLIENT_IDS: z.string().min(1).default("REPLACE_ME.apps.googleusercontent.com"),
  JWT_SECRET: z.string().min(32).default("dev-only-change-me-please-32+chars-min!!"),
  JWT_TTL_SECONDS: z.coerce.number().int().positive().default(60 * 60 * 24 * 30),
  PRIVACY_POLICY_ADMIN_KEY: z.string().min(16).default("replace-with-strong-policy-admin-key"),
  USER_QUOTA_BYTES: z.coerce.number().int().positive().default(262_144_000),
  // Per-file ciphertext upload cap. Hard ceiling — clients must reject before
  // initiating.
  MAX_UPLOAD_BYTES: z.coerce
    .number()
    .int()
    .min(10 * 1024 * 1024)
    .max(100 * 1024 * 1024)
    .default(15 * 1024 * 1024),
  // Sliding-window upload rate limit per user (uploads initiated per hour).
  UPLOAD_RATE_LIMIT_PER_HOUR: z.coerce.number().int().positive().default(30),
  // Sliding-window upload byte budget per user (total bytes per hour).
  UPLOAD_BYTES_PER_HOUR: z.coerce
    .number()
    .int()
    .positive()
    .default(150 * 1024 * 1024),
});

export const env = envSchema.parse(process.env);
