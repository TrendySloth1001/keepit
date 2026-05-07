import { HTTP_STATUS } from "../../constants/http-status";
import { HttpError } from "../../shared/http-error";
import { prisma } from "../../shared/prisma";
import type { CreateFolderInput, UpdateFolderInput } from "./folder.schema";

export interface FolderDto {
  id: string;
  name: string;
  iconKey: string | null;
  itemCount: number;
  createdAt: string;
  updatedAt: string;
}

interface FolderRow {
  id: string;
  name: string;
  iconKey: string | null;
  createdAt: Date;
  updatedAt: Date;
  _count: { items: number };
}

function toDto(f: FolderRow): FolderDto {
  return {
    id: f.id,
    name: f.name,
    iconKey: f.iconKey,
    itemCount: f._count.items,
    createdAt: f.createdAt.toISOString(),
    updatedAt: f.updatedAt.toISOString(),
  };
}

export async function listFolders(userId: string): Promise<FolderDto[]> {
  const rows = await prisma.vaultFolder.findMany({
    where: { userId },
    orderBy: { createdAt: "desc" },
    include: { _count: { select: { items: true } } },
    take: 200,
  });
  return rows.map(toDto);
}

export async function createFolder(
  userId: string,
  input: CreateFolderInput,
): Promise<FolderDto> {
  const created = await prisma.vaultFolder.create({
    data: {
      userId,
      name: input.name,
      iconKey: input.iconKey ?? null,
    },
    include: { _count: { select: { items: true } } },
  });
  return toDto(created);
}

export async function updateFolder(
  userId: string,
  id: string,
  input: UpdateFolderInput,
): Promise<FolderDto> {
  // Ownership-scoped update: updateMany so we never leak existence of someone
  // else's folder via 200 vs 404 timing.
  const data: { name?: string; iconKey?: string | null } = {};
  if (input.name !== undefined) data.name = input.name;
  if (input.iconKey !== undefined) data.iconKey = input.iconKey;
  const result = await prisma.vaultFolder.updateMany({
    where: { id, userId },
    data,
  });
  if (result.count === 0) {
    throw new HttpError(HTTP_STATUS.NOT_FOUND, "Folder not found.");
  }
  const fresh = await prisma.vaultFolder.findUniqueOrThrow({
    where: { id },
    include: { _count: { select: { items: true } } },
  });
  return toDto(fresh);
}

/// Deletes a folder. Items inside are NOT deleted — the FK is SET NULL so
/// they fall back to "uncategorized" automatically.
export async function deleteFolder(userId: string, id: string): Promise<void> {
  const result = await prisma.vaultFolder.deleteMany({ where: { id, userId } });
  if (result.count === 0) {
    throw new HttpError(HTTP_STATUS.NOT_FOUND, "Folder not found.");
  }
}
