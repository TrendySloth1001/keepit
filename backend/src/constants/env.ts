import { z } from "zod";

const envSchema = z.object({
  NODE_ENV: z.enum(["development", "production", "test"]).default("development"),
  PORT: z.coerce.number().int().positive().default(3009),
  DATABASE_URL: z.string().min(1),
});

export const env = envSchema.parse(process.env);
