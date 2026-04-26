import { Prisma, VaultItemType } from "@prisma/client";
import { HTTP_STATUS } from "../../constants/http-status";
import { MESSAGES } from "../../constants/messages";
import { env } from "../../constants/env";
import { HttpError } from "../../shared/http-error";
import { prisma } from "../../shared/prisma";
import {
  abortMultipartUpload,
  buildVaultObjectKey,
  completeMultipartUpload,
  createMultipartUpload,
  deleteObject,
  getObjectBytes,
  putObjectBytes,
  presignGetUrl,
  presignPutUrl,
  statObject,
  uploadMultipartPart,
} from "../../shared/storage/s3";
import type {
  CreateVaultItemInput,
  FinalizeUploadInput,
  InitiateUploadInput,
  ListVaultItemsInput,
  UpdateVaultItemInput,
} from "./vault.schema";

export interface VaultItemDto {
  id: string;
  type: VaultItemType;
  title: string;
  cipherBlob: string;
  cipherIv: string;
  fileSize: string | null;
  fileMime: string | null;
  uploadStatus: string | null;
  createdAt: string;
  updatedAt: string;
}

function toDto(item: {
  id: string;
  type: VaultItemType;
  title: string;
  cipherBlob: Uint8Array | Buffer;
  cipherIv: Uint8Array | Buffer;
  fileSize: bigint | null;
  fileMime: string | null;
  uploadStatus: string | null;
  createdAt: Date;
  updatedAt: Date;
}): VaultItemDto {
  return {
    id: item.id,
    type: item.type,
    title: item.title,
    cipherBlob: Buffer.from(item.cipherBlob).toString("base64"),
    cipherIv: Buffer.from(item.cipherIv).toString("base64"),
    fileSize: item.fileSize !== null ? item.fileSize.toString() : null,
    fileMime: item.fileMime,
    uploadStatus: item.uploadStatus,
    createdAt: item.createdAt.toISOString(),
    updatedAt: item.updatedAt.toISOString(),
  };
}

export async function listVaultItems(userId: string, input: ListVaultItemsInput) {
  const where: Prisma.VaultItemWhereInput = { userId };
  if (input.type) where.type = input.type;
  const items = await prisma.vaultItem.findMany({
    where,
    take: input.limit + 1,
    ...(input.cursor ? { cursor: { id: input.cursor }, skip: 1 } : {}),
    orderBy: [{ updatedAt: "desc" }, { id: "desc" }],
  });
  const hasMore = items.length > input.limit;
  const trimmed = hasMore ? items.slice(0, input.limit) : items;
  return {
    items: trimmed.map(toDto),
    nextCursor: hasMore ? trimmed[trimmed.length - 1].id : null,
  };
}

export async function getVaultItem(userId: string, id: string): Promise<VaultItemDto> {
  const item = await prisma.vaultItem.findFirst({ where: { id, userId } });
  if (!item) throw new HttpError(HTTP_STATUS.NOT_FOUND, MESSAGES.VAULT_ITEM_NOT_FOUND);
  return toDto(item);
}

export async function createVaultItem(userId: string, input: CreateVaultItemInput): Promise<VaultItemDto> {
  if (input.type === "file" || input.type === "image") {
    throw new HttpError(HTTP_STATUS.BAD_REQUEST, "Use the upload endpoint for file/image types");
  }
  const item = await prisma.vaultItem.create({
    data: {
      userId,
      type: input.type,
      title: input.title,
      cipherBlob: Buffer.from(input.cipherBlob, "base64"),
      cipherIv: Buffer.from(input.cipherIv, "base64"),
    },
  });
  return toDto(item);
}

export async function updateVaultItem(
  userId: string,
  id: string,
  input: UpdateVaultItemInput,
): Promise<VaultItemDto> {
  const data: Prisma.VaultItemUpdateInput = {};
  if (input.title !== undefined) data.title = input.title;
  if (input.cipherBlob !== undefined) data.cipherBlob = Buffer.from(input.cipherBlob, "base64");
  if (input.cipherIv !== undefined) data.cipherIv = Buffer.from(input.cipherIv, "base64");
  const result = await prisma.vaultItem.updateMany({
    where: { id, userId },
    data,
  });
  if (result.count === 0) throw new HttpError(HTTP_STATUS.NOT_FOUND, MESSAGES.VAULT_ITEM_NOT_FOUND);
  return getVaultItem(userId, id);
}

export async function deleteVaultItem(userId: string, id: string): Promise<void> {
  const item = await prisma.vaultItem.findFirst({ where: { id, userId } });
  if (!item) throw new HttpError(HTTP_STATUS.NOT_FOUND, MESSAGES.VAULT_ITEM_NOT_FOUND);

  if (item.multipartUploadId && item.fileObjectKey && item.uploadStatus !== "ready") {
    await abortMultipartUpload(item.fileObjectKey, item.multipartUploadId).catch(() => {});
  }

  await prisma.$transaction(async (tx) => {
    if (item.fileSize) {
      await tx.user.update({
        where: { id: userId },
        data: { bytesUsed: { decrement: item.fileSize } },
      });
    }
    await tx.vaultItem.delete({ where: { id: item.id } });
  });

  if (item.fileObjectKey) {
    try {
      await deleteObject(item.fileObjectKey);
    } catch {
      // Object may already be gone — quota was already decremented for the user.
    }
  }
}

export async function initiateUpload(userId: string, input: InitiateUploadInput) {
  if (input.fileSize > env.MAX_UPLOAD_BYTES) {
    throw new HttpError(HTTP_STATUS.PAYLOAD_TOO_LARGE, MESSAGES.UPLOAD_TOO_LARGE);
  }

  // Reserve quota atomically: conditional UPDATE only succeeds if capacity remains.
  const item = await prisma.$transaction(async (tx) => {
    const updated = await tx.$executeRaw`
      UPDATE "User"
      SET "bytesUsed" = "bytesUsed" + ${BigInt(input.fileSize)}
      WHERE "id" = ${userId} AND "bytesUsed" + ${BigInt(input.fileSize)} <= "quotaBytes"
    `;
    if (updated === 0) {
      throw new HttpError(HTTP_STATUS.PAYLOAD_TOO_LARGE, MESSAGES.QUOTA_EXCEEDED);
    }
    return tx.vaultItem.create({
      data: {
        userId,
        type: input.type,
        title: input.title,
        cipherBlob: Buffer.from(input.cipherBlob, "base64"),
        cipherIv: Buffer.from(input.cipherIv, "base64"),
        fileSize: BigInt(input.fileSize),
        fileMime: input.fileMime,
        uploadStatus: "pending",
      },
    });
  });

  const objectKey = buildVaultObjectKey(userId, item.id);
  const multipartUploadId = await createMultipartUpload(objectKey, "application/octet-stream");

  await prisma.vaultItem.update({
    where: { id: item.id },
    data: { fileObjectKey: objectKey, multipartUploadId, uploadStatus: "uploading" },
  });

  return {
    itemId: item.id,
    objectKey,
    chunkSize: 5 * 1024 * 1024,
  };
}

export async function uploadChunkForItem(
  userId: string,
  itemId: string,
  partNumber: number,
  chunk: Uint8Array,
): Promise<void> {
  const item = await prisma.vaultItem.findFirst({ where: { id: itemId, userId } });
  if (!item || !item.fileObjectKey || !item.fileSize || !item.multipartUploadId) {
    throw new HttpError(HTTP_STATUS.NOT_FOUND, MESSAGES.VAULT_ITEM_NOT_FOUND);
  }
  if (item.uploadStatus === "ready") {
    throw new HttpError(HTTP_STATUS.CONFLICT, "Item is already uploaded");
  }
  if (chunk.byteLength === 0) {
    throw new HttpError(HTTP_STATUS.BAD_REQUEST, "Chunk body is required");
  }

  const eTag = await uploadMultipartPart(item.fileObjectKey, item.multipartUploadId, partNumber, chunk);

  await prisma.vaultUploadPart.upsert({
    where: { itemId_partNumber: { itemId: item.id, partNumber } },
    update: { eTag, sizeBytes: BigInt(chunk.byteLength) },
    create: {
      itemId: item.id,
      partNumber,
      eTag,
      sizeBytes: BigInt(chunk.byteLength),
    },
  });
}

export async function uploadCiphertextForItem(
  userId: string,
  itemId: string,
  ciphertext: Uint8Array,
): Promise<void> {
  const item = await prisma.vaultItem.findFirst({ where: { id: itemId, userId } });
  if (!item || !item.fileObjectKey || !item.fileSize) {
    throw new HttpError(HTTP_STATUS.NOT_FOUND, MESSAGES.VAULT_ITEM_NOT_FOUND);
  }
  if (item.uploadStatus === "ready") {
    throw new HttpError(HTTP_STATUS.CONFLICT, "Item is already uploaded");
  }
  if (BigInt(ciphertext.byteLength) !== item.fileSize) {
    throw new HttpError(HTTP_STATUS.UNPROCESSABLE_ENTITY, MESSAGES.UPLOAD_SIZE_MISMATCH);
  }

  await putObjectBytes(item.fileObjectKey, ciphertext, "application/octet-stream");
}

export async function finalizeUpload(userId: string, input: FinalizeUploadInput): Promise<VaultItemDto> {
  const item = await prisma.vaultItem.findFirst({ where: { id: input.itemId, userId } });
  if (!item || !item.fileObjectKey || !item.fileSize) {
    throw new HttpError(HTTP_STATUS.NOT_FOUND, MESSAGES.VAULT_ITEM_NOT_FOUND);
  }
  if (item.uploadStatus === "ready") {
    return toDto(item);
  }

  if (item.multipartUploadId) {
    const parts = await prisma.vaultUploadPart.findMany({
      where: { itemId: item.id },
      orderBy: { partNumber: "asc" },
    });

    if (parts.length === 0) {
      throw new HttpError(HTTP_STATUS.NOT_FOUND, MESSAGES.UPLOAD_NOT_FOUND);
    }

    const total = parts.reduce((acc, p) => acc + p.sizeBytes, BigInt(0));
    if (total !== item.fileSize) {
      throw new HttpError(HTTP_STATUS.UNPROCESSABLE_ENTITY, MESSAGES.UPLOAD_SIZE_MISMATCH);
    }

    await completeMultipartUpload(
      item.fileObjectKey,
      item.multipartUploadId,
      parts.map((p) => ({ partNumber: p.partNumber, eTag: p.eTag })),
    );
  }

  const stat = await statObject(item.fileObjectKey);
  if (!stat) {
    // Roll back the quota reservation: the client never uploaded the bytes.
    await prisma.$transaction([
      prisma.user.update({ where: { id: userId }, data: { bytesUsed: { decrement: item.fileSize } } }),
      prisma.vaultItem.delete({ where: { id: item.id } }),
    ]);
    throw new HttpError(HTTP_STATUS.NOT_FOUND, MESSAGES.UPLOAD_NOT_FOUND);
  }
  if (BigInt(stat.size) !== item.fileSize) {
    await deleteObject(item.fileObjectKey).catch(() => {});
    await prisma.$transaction([
      prisma.user.update({ where: { id: userId }, data: { bytesUsed: { decrement: item.fileSize } } }),
      prisma.vaultItem.delete({ where: { id: item.id } }),
    ]);
    throw new HttpError(HTTP_STATUS.UNPROCESSABLE_ENTITY, MESSAGES.UPLOAD_SIZE_MISMATCH);
  }
  const ready = await prisma.vaultItem.update({
    where: { id: item.id },
    data: { uploadStatus: "ready", multipartUploadId: null },
  });
  await prisma.vaultUploadPart.deleteMany({ where: { itemId: item.id } });
  return toDto(ready);
}

export async function getDownloadUrl(userId: string, id: string): Promise<{ url: string; expiresInSeconds: number }> {
  const item = await prisma.vaultItem.findFirst({ where: { id, userId } });
  if (!item || !item.fileObjectKey || item.uploadStatus !== "ready") {
    throw new HttpError(HTTP_STATUS.NOT_FOUND, MESSAGES.VAULT_ITEM_NOT_FOUND);
  }
  const url = await presignGetUrl(item.fileObjectKey, 300);
  return { url, expiresInSeconds: 300 };
}

export async function downloadCiphertextForItem(userId: string, id: string): Promise<Uint8Array> {
  const item = await prisma.vaultItem.findFirst({ where: { id, userId } });
  if (!item || !item.fileObjectKey || item.uploadStatus !== "ready") {
    throw new HttpError(HTTP_STATUS.NOT_FOUND, MESSAGES.VAULT_ITEM_NOT_FOUND);
  }

  const bytes = await getObjectBytes(item.fileObjectKey);
  if (!bytes) {
    throw new HttpError(HTTP_STATUS.NOT_FOUND, MESSAGES.UPLOAD_NOT_FOUND);
  }

  return bytes;
}

export async function getStorageStats(userId: string) {
  const [user, byType] = await Promise.all([
    prisma.user.findUnique({
      where: { id: userId },
      select: { bytesUsed: true, quotaBytes: true },
    }),
    prisma.vaultItem.groupBy({
      by: ["type"],
      where: { userId },
      _sum: { fileSize: true },
      _count: { _all: true },
    }),
  ]);
  if (!user) throw new HttpError(HTTP_STATUS.NOT_FOUND, MESSAGES.USER_NOT_FOUND);
  return {
    bytesUsed: user.bytesUsed.toString(),
    quotaBytes: user.quotaBytes.toString(),
    breakdown: byType.map((row) => ({
      type: row.type,
      bytes: (row._sum.fileSize ?? BigInt(0)).toString(),
      count: row._count._all,
    })),
  };
}

export async function abortUpload(userId: string, itemId: string): Promise<void> {
  const item = await prisma.vaultItem.findFirst({ where: { id: itemId, userId } });
  if (!item || !item.fileObjectKey || !item.fileSize) {
    throw new HttpError(HTTP_STATUS.NOT_FOUND, MESSAGES.VAULT_ITEM_NOT_FOUND);
  }

  if (item.multipartUploadId) {
    await abortMultipartUpload(item.fileObjectKey, item.multipartUploadId).catch(() => {});
  }

  await prisma.$transaction([
    prisma.vaultUploadPart.deleteMany({ where: { itemId: item.id } }),
    prisma.user.update({ where: { id: userId }, data: { bytesUsed: { decrement: item.fileSize } } }),
    prisma.vaultItem.delete({ where: { id: item.id } }),
  ]);
}
