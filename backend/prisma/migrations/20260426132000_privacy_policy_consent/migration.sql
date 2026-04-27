-- AlterTable
ALTER TABLE "User" ADD COLUMN "policyAcceptedVersion" TEXT;
ALTER TABLE "User" ADD COLUMN "policyAcceptedAt" TIMESTAMP(3);

-- CreateTable
CREATE TABLE "PrivacyPolicy" (
    "id" TEXT NOT NULL DEFAULT 'active',
    "version" TEXT NOT NULL,
    "title" TEXT NOT NULL,
    "content" TEXT NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "PrivacyPolicy_pkey" PRIMARY KEY ("id")
);
