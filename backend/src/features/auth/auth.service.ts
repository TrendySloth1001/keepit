import argon2 from "argon2";
import { HTTP_STATUS } from "../../constants/http-status";
import { MESSAGES } from "../../constants/messages";
import { env } from "../../constants/env";
import { HttpError } from "../../shared/http-error";
import { prisma } from "../../shared/prisma";
import { hashJti, issueSessionToken } from "../../shared/auth/jwt";
import { verifyGoogleIdToken } from "../../shared/auth/google";
import {
  getActivePrivacyPolicy,
} from "../privacy-policy/privacy-policy.service";
import type {
  GoogleSignInInput,
  MasterInitInput,
  MasterVerifyInput,
} from "./auth.schema";

export interface SignInResult {
  token: string;
  expiresAt: Date;
  user: {
    id: string;
    email: string;
    name: string;
    avatarUrl: string | null;
    masterInitialized: boolean;
    masterSalt: string | null;
    masterParams: unknown;
    quotaBytes: string;
    bytesUsed: string;
    policyAcceptedVersion: string | null;
    policyAcceptedAt: string | null;
    currentPolicyVersion: string;
    policyAcceptedCurrent: boolean;
  };
}

function mapUserResponse(
  user: {
    id: string;
    email: string;
    name: string;
    avatarUrl: string | null;
    masterVerifier: string | null;
    masterSalt: string | null;
    masterParams: unknown;
    quotaBytes: bigint;
    bytesUsed: bigint;
  },
  currentPolicyVersion: string,
  policyAcceptedVersion: string | null,
  policyAcceptedAt: Date | null,
): SignInResult["user"] {
  return {
    id: user.id,
    email: user.email,
    name: user.name,
    avatarUrl: user.avatarUrl,
    masterInitialized: user.masterVerifier !== null,
    masterSalt: user.masterSalt,
    masterParams: user.masterParams,
    quotaBytes: user.quotaBytes.toString(),
    bytesUsed: user.bytesUsed.toString(),
    policyAcceptedVersion,
    policyAcceptedAt: policyAcceptedAt?.toISOString() ?? null,
    currentPolicyVersion,
    policyAcceptedCurrent: policyAcceptedVersion === currentPolicyVersion,
  };
}

export async function signInWithGoogle(input: GoogleSignInInput, userAgent?: string): Promise<SignInResult> {
  let payload;
  try {
    payload = await verifyGoogleIdToken(input.idToken);
  } catch {
    throw new HttpError(HTTP_STATUS.UNAUTHORIZED, MESSAGES.INVALID_GOOGLE_TOKEN);
  }

  const user = await prisma.user.upsert({
    where: { googleSub: payload.sub! },
    create: {
      googleSub: payload.sub!,
      email: payload.email!,
      name: payload.name ?? payload.email!.split("@")[0],
      avatarUrl: payload.picture ?? null,
      quotaBytes: BigInt(env.USER_QUOTA_BYTES),
    },
    update: {
      email: payload.email!,
      name: payload.name ?? undefined,
      avatarUrl: payload.picture ?? null,
    },
  });

  const issued = issueSessionToken(user.id);
  const policy = await getActivePrivacyPolicy();
  await prisma.session.create({
    data: {
      userId: user.id,
      jtiHash: issued.jtiHash,
      userAgent: userAgent ?? null,
      expiresAt: issued.expiresAt,
    },
  });

  return {
    token: issued.token,
    expiresAt: issued.expiresAt,
    user: {
      ...mapUserResponse(user, policy.version, null, null),
    },
  };
}

export async function signOut(userId: string, jti: string): Promise<void> {
  await prisma.session.updateMany({
    where: { userId, jtiHash: hashJti(jti), revokedAt: null },
    data: { revokedAt: new Date() },
  });
}

export async function initMasterPassword(userId: string, input: MasterInitInput): Promise<void> {
  const user = await prisma.user.findUnique({ where: { id: userId } });
  if (!user) throw new HttpError(HTTP_STATUS.NOT_FOUND, MESSAGES.USER_NOT_FOUND);
  if (user.masterVerifier) {
    throw new HttpError(HTTP_STATUS.CONFLICT, MESSAGES.MASTER_ALREADY_INITIALIZED);
  }
  const verifierHash = await argon2.hash(input.verifier, { type: argon2.argon2id });
  await prisma.user.update({
    where: { id: userId },
    data: {
      masterSalt: input.salt,
      masterVerifier: verifierHash,
      masterParams: input.params,
    },
  });
}

export async function verifyMasterPassword(userId: string, input: MasterVerifyInput): Promise<void> {
  const user = await prisma.user.findUnique({ where: { id: userId } });
  if (!user) throw new HttpError(HTTP_STATUS.NOT_FOUND, MESSAGES.USER_NOT_FOUND);
  if (!user.masterVerifier) {
    throw new HttpError(HTTP_STATUS.BAD_REQUEST, MESSAGES.MASTER_NOT_INITIALIZED);
  }
  const ok = await argon2.verify(user.masterVerifier, input.verifier);
  if (!ok) {
    throw new HttpError(HTTP_STATUS.UNAUTHORIZED, MESSAGES.MASTER_VERIFY_FAILED);
  }
}

export async function getCurrentUser(userId: string): Promise<SignInResult["user"]> {
  const [user, policy] = await Promise.all([
    prisma.user.findUnique({ where: { id: userId } }),
    getActivePrivacyPolicy(),
  ]);
  if (!user) {
    throw new HttpError(HTTP_STATUS.NOT_FOUND, MESSAGES.USER_NOT_FOUND);
  }

  const policyAcceptedVersion = (user as { policyAcceptedVersion?: string | null }).policyAcceptedVersion ?? null;
  const policyAcceptedAt = (user as { policyAcceptedAt?: Date | null }).policyAcceptedAt ?? null;

  return mapUserResponse(user, policy.version, policyAcceptedVersion, policyAcceptedAt);
}
