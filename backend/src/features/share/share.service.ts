import { VaultItemType } from "@prisma/client";
import { HTTP_STATUS } from "../../constants/http-status";
import { HttpError } from "../../shared/http-error";
import { prisma } from "../../shared/prisma";
import type {
  CreateShareInput,
  LookupRecipientInput,
  PublishKeypairInput,
} from "./share.schema";

export interface ShareDto {
  id: string;
  ownerId: string;
  ownerName: string;
  ownerEmail: string;
  recipientId: string;
  recipientEmail: string;
  type: VaultItemType;
  title: string;
  cipherBlob: string;
  cipherIv: string;
  wrappedKey: string;
  permission: string;
  createdAt: string;
  expiresAt: string | null;
}

interface ShareRow {
  id: string;
  ownerId: string;
  recipientId: string;
  type: VaultItemType;
  title: string;
  cipherBlob: Uint8Array | Buffer;
  cipherIv: Uint8Array | Buffer;
  wrappedKey: Uint8Array | Buffer;
  permission: string;
  createdAt: Date;
  expiresAt: Date | null;
  owner: { name: string; email: string };
  recipient: { email: string };
}

function toDto(s: ShareRow): ShareDto {
  return {
    id: s.id,
    ownerId: s.ownerId,
    ownerName: s.owner.name,
    ownerEmail: s.owner.email,
    recipientId: s.recipientId,
    recipientEmail: s.recipient.email,
    type: s.type,
    title: s.title,
    cipherBlob: Buffer.from(s.cipherBlob).toString("base64"),
    cipherIv: Buffer.from(s.cipherIv).toString("base64"),
    wrappedKey: Buffer.from(s.wrappedKey).toString("base64"),
    permission: s.permission,
    createdAt: s.createdAt.toISOString(),
    expiresAt: s.expiresAt ? s.expiresAt.toISOString() : null,
  };
}

export async function lookupRecipient(input: LookupRecipientInput) {
  const recipient = await prisma.user.findUnique({
    where: { email: input.email.toLowerCase() },
    select: { id: true, email: true, name: true, sharingPublicKey: true },
  });
  if (!recipient) {
    throw new HttpError(
      HTTP_STATUS.NOT_FOUND,
      "No KeepIt account is registered with that email."
    );
  }
  if (!recipient.sharingPublicKey) {
    throw new HttpError(
      HTTP_STATUS.CONFLICT,
      "That user has not finished setting up sharing yet. Ask them to open the app once."
    );
  }
  return recipient;
}

export async function publishKeypair(
  userId: string,
  input: PublishKeypairInput,
) {
  await prisma.user.update({
    where: { id: userId },
    data: {
      sharingPublicKey: input.publicKey,
      sharingPrivateCipher: input.privateCipher,
      sharingPrivateIv: input.privateIv,
    },
  });
}

export async function getMyKeypair(userId: string) {
  const user = await prisma.user.findUniqueOrThrow({
    where: { id: userId },
    select: {
      sharingPublicKey: true,
      sharingPrivateCipher: true,
      sharingPrivateIv: true,
    },
  });
  return {
    publicKey: user.sharingPublicKey,
    privateCipher: user.sharingPrivateCipher,
    privateIv: user.sharingPrivateIv,
  };
}

export async function createShare(ownerId: string, input: CreateShareInput) {
  const recipient = await prisma.user.findUnique({
    where: { email: input.recipientEmail.toLowerCase() },
    select: { id: true, sharingPublicKey: true },
  });
  if (!recipient) {
    throw new HttpError(
      HTTP_STATUS.NOT_FOUND,
      "No KeepIt account is registered with that email."
    );
  }
  if (recipient.id === ownerId) {
    throw new HttpError(
      HTTP_STATUS.BAD_REQUEST,
      "You cannot share an item with yourself.",
    );
  }
  if (!recipient.sharingPublicKey) {
    throw new HttpError(
      HTTP_STATUS.CONFLICT,
      "That user is not ready to receive shares yet.",
    );
  }

  const expiresAt = input.expiresInDays
    ? new Date(Date.now() + input.expiresInDays * 24 * 60 * 60 * 1000)
    : null;

  const created = await prisma.vaultShare.create({
    data: {
      ownerId,
      recipientId: recipient.id,
      type: input.type,
      title: input.title,
      cipherBlob: Buffer.from(input.cipherBlob, "base64"),
      cipherIv: Buffer.from(input.cipherIv, "base64"),
      wrappedKey: Buffer.from(input.wrappedKey, "base64"),
      permission: input.permission,
      expiresAt,
    },
    include: {
      owner: { select: { name: true, email: true } },
      recipient: { select: { email: true } },
    },
  });
  return toDto(created);
}

/// Lists shares received by the requesting user. Filters out revoked AND
/// expired rows in a single SQL pass — no follow-up query, no N+1, and the
/// (recipientId, revokedAt, expiresAt, createdAt DESC) index covers the scan.
export async function listReceivedShares(userId: string) {
  const now = new Date();
  const rows = await prisma.vaultShare.findMany({
    where: {
      recipientId: userId,
      revokedAt: null,
      OR: [{ expiresAt: null }, { expiresAt: { gt: now } }],
    },
    orderBy: { createdAt: "desc" },
    include: {
      owner: { select: { name: true, email: true } },
      recipient: { select: { email: true } },
    },
    take: 200,
  });
  return rows.map(toDto);
}

export async function listSentShares(userId: string) {
  const now = new Date();
  const rows = await prisma.vaultShare.findMany({
    where: {
      ownerId: userId,
      revokedAt: null,
      OR: [{ expiresAt: null }, { expiresAt: { gt: now } }],
    },
    orderBy: { createdAt: "desc" },
    include: {
      owner: { select: { name: true, email: true } },
      recipient: { select: { email: true } },
    },
    take: 200,
  });
  return rows.map(toDto);
}

export async function revokeShare(userId: string, id: string) {
  // Owner OR recipient may revoke (recipient revoking == removing from their
  // inbox). Either way, scope by userId membership so we never leak existence
  // of someone else's share.
  const share = await prisma.vaultShare.findUnique({
    where: { id },
    select: { ownerId: true, recipientId: true },
  });
  if (!share) {
    throw new HttpError(HTTP_STATUS.NOT_FOUND, "Share not found.");
  }
  if (share.ownerId !== userId && share.recipientId !== userId) {
    throw new HttpError(HTTP_STATUS.NOT_FOUND, "Share not found.");
  }
  await prisma.vaultShare.update({
    where: { id },
    data: { revokedAt: new Date() },
  });
}
