import { VaultItemType } from "@prisma/client";
import { HTTP_STATUS } from "../../constants/http-status";
import { MESSAGES } from "../../constants/messages";
import { HttpError } from "../../shared/http-error";
import { prisma } from "../../shared/prisma";
import { getObjectBytes } from "../../shared/storage/s3";
import type {
  CreateBundleInput,
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
  bundleId: string | null;
  bundleName: string | null;
  // Read receipts. firstOpenedAt + lastOpenedAt are owner-visible signals;
  // openCount lets the UI show "opened 3 times" without joining a log table.
  firstOpenedAt: string | null;
  lastOpenedAt: string | null;
  openCount: number;
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
  bundleId: string | null;
  firstOpenedAt: Date | null;
  lastOpenedAt: Date | null;
  openCount: number;
  owner: { name: string; email: string };
  recipient: { email: string };
  bundle: { id: string; name: string } | null;
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
    bundleId: s.bundleId,
    bundleName: s.bundle?.name ?? null,
    firstOpenedAt: s.firstOpenedAt ? s.firstOpenedAt.toISOString() : null,
    lastOpenedAt: s.lastOpenedAt ? s.lastOpenedAt.toISOString() : null,
    openCount: s.openCount,
  };
}

const SHARE_INCLUDE = {
  owner: { select: { name: true, email: true } },
  recipient: { select: { email: true } },
  bundle: { select: { id: true, name: true } },
} as const;

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

  // For file/image shares, verify the owner actually owns the referenced
  // source item and that it has a ready encrypted body. The recipient will
  // pull the body via /shares/:id/content; we don't copy bytes here.
  let sourceItemId: string | null = null;
  if (input.type === "file" || input.type === "image") {
    if (!input.sourceItemId) {
      throw new HttpError(
        HTTP_STATUS.BAD_REQUEST,
        "sourceItemId is required for file/image shares.",
      );
    }
    const srcItem = await prisma.vaultItem.findFirst({
      where: { id: input.sourceItemId, userId: ownerId },
      select: { id: true, type: true, fileObjectKey: true, uploadStatus: true },
    });
    if (!srcItem || !srcItem.fileObjectKey || srcItem.uploadStatus !== "ready") {
      throw new HttpError(HTTP_STATUS.NOT_FOUND, MESSAGES.VAULT_ITEM_NOT_FOUND);
    }
    if (srcItem.type !== input.type) {
      throw new HttpError(
        HTTP_STATUS.BAD_REQUEST,
        "Share type must match the source item type.",
      );
    }
    sourceItemId = srcItem.id;
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
      sourceItemId,
      expiresAt,
    },
    include: SHARE_INCLUDE,
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
    include: SHARE_INCLUDE,
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
    include: SHARE_INCLUDE,
    take: 200,
  });
  return rows.map(toDto);
}

/**
 * Streams the encrypted body of a shared file/image to the recipient.
 *
 * Authorization: caller must be the share's recipient, the share must not be
 * revoked or expired, and the source vault item must still exist with a ready
 * upload. The body is the *owner's* encrypted ciphertext — the recipient's
 * client decrypts it with the per-file DEK that rides inside the (separately
 * encrypted) share payload, so the server never sees plaintext or the DEK.
 */
export async function getSharedCiphertext(
  userId: string,
  shareId: string,
): Promise<Uint8Array> {
  const now = new Date();
  const share = await prisma.vaultShare.findUnique({
    where: { id: shareId },
    select: {
      recipientId: true,
      revokedAt: true,
      expiresAt: true,
      sourceItemId: true,
      type: true,
    },
  });
  if (!share || share.recipientId !== userId) {
    throw new HttpError(HTTP_STATUS.NOT_FOUND, "Share not found.");
  }
  if (share.revokedAt !== null) {
    throw new HttpError(HTTP_STATUS.NOT_FOUND, "Share not found.");
  }
  if (share.expiresAt !== null && share.expiresAt <= now) {
    throw new HttpError(HTTP_STATUS.NOT_FOUND, "Share not found.");
  }
  if (share.type !== "file" && share.type !== "image") {
    throw new HttpError(
      HTTP_STATUS.BAD_REQUEST,
      "This share has no file body.",
    );
  }
  if (!share.sourceItemId) {
    // Legacy share that inlined the body in cipherBlob — recipient already
    // has everything in the share payload itself.
    throw new HttpError(
      HTTP_STATUS.BAD_REQUEST,
      "This share's file body is inlined in the payload — no separate body to fetch.",
    );
  }
  const item = await prisma.vaultItem.findUnique({
    where: { id: share.sourceItemId },
    select: { fileObjectKey: true, uploadStatus: true },
  });
  if (!item || !item.fileObjectKey || item.uploadStatus !== "ready") {
    throw new HttpError(HTTP_STATUS.NOT_FOUND, MESSAGES.VAULT_ITEM_NOT_FOUND);
  }
  const bytes = await getObjectBytes(item.fileObjectKey);
  if (!bytes) {
    throw new HttpError(HTTP_STATUS.NOT_FOUND, MESSAGES.UPLOAD_NOT_FOUND);
  }
  // Auto-bump receipts on the file content fetch — this is the recipient's
  // "open" for file/image shares (non-file shares hit POST /:id/opened).
  // Best-effort: a failed update should never cause a successful download to
  // surface as an error, so we swallow.
  await markShareOpenedInternal(shareId).catch(() => {});
  return bytes;
}

/// Increments openCount and lastOpenedAt; sets firstOpenedAt on the first call.
/// Internal — callers must already have authenticated the recipient.
async function markShareOpenedInternal(shareId: string) {
  const now = new Date();
  // Always bump lastOpenedAt + openCount.
  await prisma.vaultShare.update({
    where: { id: shareId },
    data: {
      lastOpenedAt: now,
      openCount: { increment: 1 },
    },
  });
  // Backfill firstOpenedAt only if it's still null. Two queries vs raw SQL is
  // fine on a per-open path that already does I/O for the body.
  await prisma.vaultShare.updateMany({
    where: { id: shareId, firstOpenedAt: null },
    data: { firstOpenedAt: now },
  });
}

/// Recipient marks a non-file share as opened (after successful local decrypt).
/// File shares are auto-marked inside getSharedCiphertext.
export async function markShareOpened(userId: string, shareId: string) {
  const now = new Date();
  const share = await prisma.vaultShare.findUnique({
    where: { id: shareId },
    select: {
      recipientId: true,
      revokedAt: true,
      expiresAt: true,
    },
  });
  if (!share || share.recipientId !== userId) {
    throw new HttpError(HTTP_STATUS.NOT_FOUND, "Share not found.");
  }
  if (share.revokedAt !== null) {
    throw new HttpError(HTTP_STATUS.NOT_FOUND, "Share not found.");
  }
  if (share.expiresAt !== null && share.expiresAt <= now) {
    throw new HttpError(HTTP_STATUS.NOT_FOUND, "Share not found.");
  }
  await markShareOpenedInternal(shareId);
}

/**
 * Creates a folder-share bundle: one VaultShareBundle row + N VaultShare
 * children, all in a single transaction so a partial failure can never leak
 * dangling bundle rows or half-shared folders.
 */
export async function createBundle(
  ownerId: string,
  input: CreateBundleInput,
): Promise<{ bundleId: string; shares: ShareDto[] }> {
  const recipient = await prisma.user.findUnique({
    where: { email: input.recipientEmail.toLowerCase() },
    select: { id: true, sharingPublicKey: true },
  });
  if (!recipient) {
    throw new HttpError(
      HTTP_STATUS.NOT_FOUND,
      "No KeepIt account is registered with that email.",
    );
  }
  if (recipient.id === ownerId) {
    throw new HttpError(
      HTTP_STATUS.BAD_REQUEST,
      "You cannot share a folder with yourself.",
    );
  }
  if (!recipient.sharingPublicKey) {
    throw new HttpError(
      HTTP_STATUS.CONFLICT,
      "That user is not ready to receive shares yet.",
    );
  }

  // Validate every file/image child references an owner-side ready item.
  // We do this once up front so we don't tear down a partial transaction.
  const fileItemIds = input.items
    .filter((it) => it.type === "file" || it.type === "image")
    .map((it) => it.sourceItemId)
    .filter((id): id is string => !!id);
  if (
    input.items.some(
      (it) =>
        (it.type === "file" || it.type === "image") && !it.sourceItemId,
    )
  ) {
    throw new HttpError(
      HTTP_STATUS.BAD_REQUEST,
      "sourceItemId is required for every file/image entry in a bundle.",
    );
  }
  if (fileItemIds.length > 0) {
    const items = await prisma.vaultItem.findMany({
      where: { id: { in: fileItemIds }, userId: ownerId },
      select: {
        id: true,
        type: true,
        fileObjectKey: true,
        uploadStatus: true,
      },
    });
    const byId = new Map(items.map((i) => [i.id, i] as const));
    for (const child of input.items) {
      if (child.type !== "file" && child.type !== "image") continue;
      const src = byId.get(child.sourceItemId!);
      if (!src || !src.fileObjectKey || src.uploadStatus !== "ready") {
        throw new HttpError(
          HTTP_STATUS.NOT_FOUND,
          MESSAGES.VAULT_ITEM_NOT_FOUND,
        );
      }
      if (src.type !== child.type) {
        throw new HttpError(
          HTTP_STATUS.BAD_REQUEST,
          "Bundle entry type must match its source item type.",
        );
      }
    }
  }

  const expiresAt = input.expiresInDays
    ? new Date(Date.now() + input.expiresInDays * 24 * 60 * 60 * 1000)
    : null;

  const bundleId = await prisma.$transaction(async (tx) => {
    const bundle = await tx.vaultShareBundle.create({
      data: {
        ownerId,
        recipientId: recipient.id,
        name: input.name,
        sourceFolderId: input.sourceFolderId ?? null,
        expiresAt,
      },
      select: { id: true },
    });
    await tx.vaultShare.createMany({
      data: input.items.map((it) => ({
        ownerId,
        recipientId: recipient.id,
        type: it.type,
        title: it.title,
        cipherBlob: Buffer.from(it.cipherBlob, "base64"),
        cipherIv: Buffer.from(it.cipherIv, "base64"),
        wrappedKey: Buffer.from(it.wrappedKey, "base64"),
        permission: input.permission,
        sourceItemId:
          it.type === "file" || it.type === "image"
            ? it.sourceItemId ?? null
            : null,
        bundleId: bundle.id,
        expiresAt,
      })),
    });
    return bundle.id;
  });

  const shares = await prisma.vaultShare.findMany({
    where: { bundleId },
    orderBy: { createdAt: "asc" },
    include: SHARE_INCLUDE,
  });
  return { bundleId, shares: shares.map(toDto) };
}

/// Revokes the bundle and all its child shares in a single transaction so
/// partial revokes never leak a bundle that's "half-alive."
export async function revokeBundle(userId: string, bundleId: string) {
  const bundle = await prisma.vaultShareBundle.findUnique({
    where: { id: bundleId },
    select: { ownerId: true, recipientId: true },
  });
  if (!bundle) {
    throw new HttpError(HTTP_STATUS.NOT_FOUND, "Bundle not found.");
  }
  if (bundle.ownerId !== userId && bundle.recipientId !== userId) {
    throw new HttpError(HTTP_STATUS.NOT_FOUND, "Bundle not found.");
  }
  const now = new Date();
  await prisma.$transaction([
    prisma.vaultShareBundle.update({
      where: { id: bundleId },
      data: { revokedAt: now },
    }),
    prisma.vaultShare.updateMany({
      where: { bundleId, revokedAt: null },
      data: { revokedAt: now },
    }),
  ]);
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
