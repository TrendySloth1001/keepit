import { HTTP_STATUS } from "../../constants/http-status";
import { MESSAGES } from "../../constants/messages";
import { HttpError } from "../../shared/http-error";
import { prisma } from "../../shared/prisma";
import type {
  ConsentPrivacyPolicyInput,
  UpdatePrivacyPolicyInput,
} from "./privacy-policy.schema";

const DEFAULT_POLICY_VERSION = "2026-04-26.1";
const DEFAULT_POLICY_TITLE = "KeepIt Privacy Policy & Data Protection Terms";
const DEFAULT_POLICY_CONTENT = `# KeepIt Privacy Policy\n\nLast Updated: 2026-04-26\n\n## 1. Zero-Knowledge Security\nKeepIt is designed as a zero-knowledge vault. Your sensitive vault content is encrypted on your device before upload.\n\n## 2. Master Password Responsibility\nYour master password (or equivalent derived key) is never sent to our servers.\nIf you forget or lose your master password, your encrypted vault data cannot be recovered by KeepIt.\n\n## 3. No Access to Vault Plaintext\nWe do not have the technical capability to read your vault plaintext, including saved credentials, notes, keys, and encrypted files.\n\n## 4. Account Data We Process\nFor account/session operation we may process limited profile and operational metadata (such as email, name, avatar, quota usage, and session records).\n\n## 5. Consent Requirement\nBy accepting this policy, you acknowledge and agree that:\n- You are solely responsible for keeping your master password safe.\n- Loss of master password means permanent loss of access to your encrypted vault.\n- KeepIt cannot decrypt or recover your vault contents.\n\n## 6. Policy Updates\nWe may update this policy over time. Continued usage requires acceptance of the latest version.`;

export interface PrivacyPolicyDto {
  version: string;
  title: string;
  content: string;
  updatedAt: string;
}

function toDto(policy: {
  version: string;
  title: string;
  content: string;
  updatedAt: Date;
}): PrivacyPolicyDto {
  return {
    version: policy.version,
    title: policy.title,
    content: policy.content,
    updatedAt: policy.updatedAt.toISOString(),
  };
}

export async function getActivePrivacyPolicy() {
  const existing = await prisma.privacyPolicy.findUnique({ where: { id: "active" } });
  if (existing) return existing;

  return prisma.privacyPolicy.create({
    data: {
      id: "active",
      version: DEFAULT_POLICY_VERSION,
      title: DEFAULT_POLICY_TITLE,
      content: DEFAULT_POLICY_CONTENT,
    },
  });
}

export async function getActivePrivacyPolicyDto(): Promise<PrivacyPolicyDto> {
  const policy = await getActivePrivacyPolicy();
  return toDto(policy);
}

export async function updateActivePrivacyPolicy(input: UpdatePrivacyPolicyInput): Promise<PrivacyPolicyDto> {
  const current = await getActivePrivacyPolicy();
  const updated = await prisma.privacyPolicy.update({
    where: { id: current.id },
    data: {
      version: input.version,
      title: input.title,
      content: input.content,
    },
  });
  return toDto(updated);
}

export async function acceptActivePrivacyPolicy(
  userId: string,
  input: ConsentPrivacyPolicyInput,
): Promise<{ policyAcceptedVersion: string; policyAcceptedAt: string }> {
  const policy = await getActivePrivacyPolicy();
  if (input.version != policy.version) {
    throw new HttpError(
      HTTP_STATUS.CONFLICT,
      MESSAGES.PRIVACY_POLICY_VERSION_MISMATCH,
    );
  }

  const updated = await prisma.user.update({
    where: { id: userId },
    data: {
      policyAcceptedVersion: policy.version,
      policyAcceptedAt: new Date(),
    },
    select: {
      policyAcceptedVersion: true,
      policyAcceptedAt: true,
    },
  });

  if (!updated.policyAcceptedVersion || !updated.policyAcceptedAt) {
    throw new HttpError(
      HTTP_STATUS.INTERNAL_SERVER_ERROR,
      MESSAGES.PRIVACY_POLICY_CONSENT_REQUIRED,
    );
  }

  return {
    policyAcceptedVersion: updated.policyAcceptedVersion,
    policyAcceptedAt: updated.policyAcceptedAt.toISOString(),
  };
}

export function hasAcceptedCurrentPolicy(user: {
  policyAcceptedVersion: string | null;
}, currentVersion: string): boolean {
  return user.policyAcceptedVersion === currentVersion;
}
