import { PrismaPg } from "@prisma/adapter-pg";
import { PrismaClient } from "@prisma/client";

declare global {
  var prisma: PrismaClient | undefined;
}

const adapter = new PrismaPg({
  connectionString: process.env.POSTGRES_URL ?? "postgresql://keepit:keepit@localhost:5432/keepit?schema=public",
});

export const prisma =
  global.prisma ??
  new PrismaClient({
    adapter,
    log: ["query", "warn", "error"],
  });

if (process.env.NODE_ENV !== "production") {
  global.prisma = prisma;
}
