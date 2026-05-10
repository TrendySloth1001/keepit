import { HTTP_STATUS } from "../../constants/http-status";
import { HttpError } from "../../shared/http-error";
import { prisma } from "../../shared/prisma";
import type {
  CreateCollabFolderInput,
  EditItemInput,
  InviteMemberInput,
  PostItemInput,
  UpdateCollabFolderInput,
} from "./collab-folder.schema";

// --- DTOs ---

export interface CollabMemberDto {
  userId: string;
  email: string;
  name: string;
  avatarUrl: string | null;
  role: string;
  joinedAt: string;
  // Recipient sharing public key (base64) — clients need it to wrap an
  // item DEK to this member when posting.
  sharingPublicKey: string | null;
}

export interface CollabFolderSummaryDto {
  id: string;
  name: string;
  iconKey: string | null;
  ownerId: string;
  ownerName: string;
  itemCount: number;
  memberCount: number;
  // Whether the requesting user is the owner.
  isOwner: boolean;
  createdAt: string;
  updatedAt: string;
}

export interface CollabItemDto {
  id: string;
  type: string;
  title: string;
  creatorId: string;
  creatorName: string;
  cipherBlob: string;
  cipherIv: string;
  // The wrappedKey for the *requesting user only*. Clients always
  // unwrap with their own private key.
  wrappedKey: string;
  createdAt: string;
  updatedAt: string;
}

export interface CollabActivityDto {
  id: string;
  actorId: string;
  actorName: string;
  action: string;
  targetItemId: string | null;
  detail: string | null;
  createdAt: string;
}

export interface CollabFolderDetailDto extends CollabFolderSummaryDto {
  members: CollabMemberDto[];
  items: CollabItemDto[];
  activity: CollabActivityDto[];
}

// --- helpers ---

function b64(buf: Buffer | Uint8Array): string {
  return Buffer.from(buf).toString("base64");
}

function fromB64(s: string): Uint8Array<ArrayBuffer> {
  // Prisma's Bytes type requires Uint8Array<ArrayBuffer>; both Buffer and
  // Buffer.buffer resolve to ArrayBufferLike under strict mode, which Prisma
  // rejects in createMany(). Copy bytes into a fresh ArrayBuffer-backed
  // Uint8Array to satisfy the typing.
  const buf = Buffer.from(s, "base64");
  const ab = new ArrayBuffer(buf.byteLength);
  const out = new Uint8Array(ab);
  out.set(buf);
  return out;
}

async function ensureMember(
  folderId: string,
  userId: string,
): Promise<{ memberId: string; isOwner: boolean }> {
  const m = await prisma.collabMember.findUnique({
    where: { folderId_userId: { folderId, userId } },
  });
  if (!m) throw new HttpError(HTTP_STATUS.FORBIDDEN, "Not a folder member");
  return { memberId: m.id, isOwner: m.role === "owner" };
}

async function logActivity(
  folderId: string,
  actorId: string,
  action: string,
  targetItemId?: string | null,
  detail?: string | null,
) {
  await prisma.collabActivity.create({
    data: { folderId, actorId, action, targetItemId, detail },
  });
}

// --- folders ---

export async function createCollabFolder(
  userId: string,
  input: CreateCollabFolderInput,
): Promise<CollabFolderSummaryDto> {
  const created = await prisma.collabFolder.create({
    data: {
      ownerId: userId,
      name: input.name,
      iconKey: input.iconKey ?? null,
      members: { create: { userId, role: "owner" } },
    },
    include: {
      owner: { select: { name: true } },
      _count: { select: { items: true, members: true } },
    },
  });
  await logActivity(created.id, userId, "created");
  return {
    id: created.id,
    name: created.name,
    iconKey: created.iconKey,
    ownerId: created.ownerId,
    ownerName: created.owner.name,
    itemCount: created._count.items,
    memberCount: created._count.members,
    isOwner: true,
    createdAt: created.createdAt.toISOString(),
    updatedAt: created.updatedAt.toISOString(),
  };
}

export async function listCollabFolders(
  userId: string,
): Promise<CollabFolderSummaryDto[]> {
  const memberships = await prisma.collabMember.findMany({
    where: { userId },
    include: {
      folder: {
        include: {
          owner: { select: { id: true, name: true } },
          _count: { select: { items: true, members: true } },
        },
      },
    },
    orderBy: { joinedAt: "desc" },
  });
  return memberships.map((m) => ({
    id: m.folder.id,
    name: m.folder.name,
    iconKey: m.folder.iconKey,
    ownerId: m.folder.owner.id,
    ownerName: m.folder.owner.name,
    itemCount: m.folder._count.items,
    memberCount: m.folder._count.members,
    isOwner: m.folder.ownerId === userId,
    createdAt: m.folder.createdAt.toISOString(),
    updatedAt: m.folder.updatedAt.toISOString(),
  }));
}

export async function getCollabFolderDetail(
  userId: string,
  folderId: string,
): Promise<CollabFolderDetailDto> {
  await ensureMember(folderId, userId);
  const folder = await prisma.collabFolder.findUnique({
    where: { id: folderId },
    include: {
      owner: { select: { id: true, name: true } },
      members: {
        include: {
          user: {
            select: {
              id: true,
              email: true,
              name: true,
              avatarUrl: true,
              sharingPublicKey: true,
            },
          },
        },
        orderBy: { joinedAt: "asc" },
      },
      items: {
        include: {
          creator: { select: { id: true, name: true } },
          keys: { where: { userId }, take: 1 },
        },
        orderBy: { createdAt: "desc" },
        take: 500,
      },
      activities: {
        include: { actor: { select: { id: true, name: true } } },
        orderBy: { createdAt: "desc" },
        take: 200,
      },
      _count: { select: { items: true, members: true } },
    },
  });
  if (!folder) throw new HttpError(HTTP_STATUS.NOT_FOUND, "Folder not found");

  return {
    id: folder.id,
    name: folder.name,
    iconKey: folder.iconKey,
    ownerId: folder.owner.id,
    ownerName: folder.owner.name,
    itemCount: folder._count.items,
    memberCount: folder._count.members,
    isOwner: folder.ownerId === userId,
    createdAt: folder.createdAt.toISOString(),
    updatedAt: folder.updatedAt.toISOString(),
    members: folder.members.map((m) => ({
      userId: m.user.id,
      email: m.user.email,
      name: m.user.name,
      avatarUrl: m.user.avatarUrl,
      role: m.role,
      joinedAt: m.joinedAt.toISOString(),
      sharingPublicKey: m.user.sharingPublicKey,
    })),
    // Items the requesting user has a key for. Items posted before the
    // user joined (and not back-rewrapped) won't appear here.
    items: folder.items
      .filter((it) => it.keys.length > 0)
      .map((it) => ({
        id: it.id,
        type: it.type,
        title: it.title,
        creatorId: it.creator.id,
        creatorName: it.creator.name,
        cipherBlob: b64(it.cipherBlob),
        cipherIv: b64(it.cipherIv),
        wrappedKey: b64(it.keys[0]!.wrappedKey),
        createdAt: it.createdAt.toISOString(),
        updatedAt: it.updatedAt.toISOString(),
      })),
    activity: folder.activities.map((a) => ({
      id: a.id,
      actorId: a.actor.id,
      actorName: a.actor.name,
      action: a.action,
      targetItemId: a.targetItemId,
      detail: a.detail,
      createdAt: a.createdAt.toISOString(),
    })),
  };
}

export async function updateCollabFolder(
  userId: string,
  folderId: string,
  input: UpdateCollabFolderInput,
): Promise<CollabFolderSummaryDto> {
  const folder = await prisma.collabFolder.findUnique({
    where: { id: folderId },
    select: { ownerId: true },
  });
  if (!folder) throw new HttpError(HTTP_STATUS.NOT_FOUND, "Folder not found");
  if (folder.ownerId !== userId) {
    throw new HttpError(HTTP_STATUS.FORBIDDEN, "Only the owner can edit");
  }
  const updated = await prisma.collabFolder.update({
    where: { id: folderId },
    data: {
      ...(input.name !== undefined ? { name: input.name } : {}),
      ...(input.iconKey !== undefined ? { iconKey: input.iconKey } : {}),
    },
    include: {
      owner: { select: { name: true } },
      _count: { select: { items: true, members: true } },
    },
  });
  return {
    id: updated.id,
    name: updated.name,
    iconKey: updated.iconKey,
    ownerId: updated.ownerId,
    ownerName: updated.owner.name,
    itemCount: updated._count.items,
    memberCount: updated._count.members,
    isOwner: true,
    createdAt: updated.createdAt.toISOString(),
    updatedAt: updated.updatedAt.toISOString(),
  };
}

export async function deleteCollabFolder(
  userId: string,
  folderId: string,
): Promise<void> {
  const folder = await prisma.collabFolder.findUnique({
    where: { id: folderId },
    select: { ownerId: true },
  });
  if (!folder) throw new HttpError(HTTP_STATUS.NOT_FOUND, "Folder not found");
  if (folder.ownerId !== userId) {
    throw new HttpError(HTTP_STATUS.FORBIDDEN, "Only the owner can delete");
  }
  await prisma.collabFolder.delete({ where: { id: folderId } });
}

// --- members ---

/// Looks up a recipient by email and returns their public sharing key so
/// the caller can rewrap each existing item's DEK before submitting the
/// invite. Returns null if the user has no published sharing key (they
/// must unlock their vault once before they can be invited).
export async function lookupRecipient(
  email: string,
): Promise<{
  userId: string;
  email: string;
  name: string;
  sharingPublicKey: string | null;
}> {
  const u = await prisma.user.findUnique({
    where: { email: email.toLowerCase() },
    select: { id: true, email: true, name: true, sharingPublicKey: true },
  });
  if (!u) throw new HttpError(HTTP_STATUS.NOT_FOUND, "No user with that email");
  return { userId: u.id, email: u.email, name: u.name, sharingPublicKey: u.sharingPublicKey };
}

export async function inviteMember(
  ownerId: string,
  folderId: string,
  input: InviteMemberInput,
): Promise<CollabMemberDto> {
  const folder = await prisma.collabFolder.findUnique({
    where: { id: folderId },
    select: { ownerId: true },
  });
  if (!folder) throw new HttpError(HTTP_STATUS.NOT_FOUND, "Folder not found");
  if (folder.ownerId !== ownerId) {
    throw new HttpError(HTTP_STATUS.FORBIDDEN, "Only the owner can invite");
  }
  const recipient = await prisma.user.findUnique({
    where: { email: input.email.toLowerCase() },
    select: {
      id: true,
      email: true,
      name: true,
      avatarUrl: true,
      sharingPublicKey: true,
    },
  });
  if (!recipient) throw new HttpError(HTTP_STATUS.NOT_FOUND, "No user with that email");
  if (recipient.id === ownerId) {
    throw new HttpError(HTTP_STATUS.BAD_REQUEST, "Owner is already a member");
  }
  if (!recipient.sharingPublicKey) {
    throw new HttpError(
      HTTP_STATUS.BAD_REQUEST,
      "Recipient has not unlocked their vault yet — ask them to sign in once first.",
    );
  }
  const existing = await prisma.collabMember.findUnique({
    where: { folderId_userId: { folderId, userId: recipient.id } },
  });
  if (existing) {
    throw new HttpError(HTTP_STATUS.CONFLICT, "User is already a member");
  }

  // Validate that the supplied itemKeys exactly match the folder's existing
  // items. We don't trust the client to enumerate them.
  const items = await prisma.collabItem.findMany({
    where: { folderId },
    select: { id: true },
  });
  const expected = new Set(items.map((i) => i.id));
  const provided = new Set(input.itemKeys.map((k) => k.itemId));
  for (const id of expected) {
    if (!provided.has(id)) {
      throw new HttpError(
        HTTP_STATUS.BAD_REQUEST,
        `Missing rewrapped key for item ${id}`,
      );
    }
  }
  for (const id of provided) {
    if (!expected.has(id)) {
      throw new HttpError(HTTP_STATUS.BAD_REQUEST, `Unknown item ${id}`);
    }
  }

  const member = await prisma.$transaction(async (tx) => {
    const m = await tx.collabMember.create({
      data: { folderId, userId: recipient.id, role: "member" },
    });
    if (input.itemKeys.length > 0) {
      await tx.collabItemKey.createMany({
        data: input.itemKeys.map((k) => ({
          itemId: k.itemId,
          memberId: m.id,
          userId: recipient.id,
          wrappedKey: fromB64(k.wrappedKey),
        })),
      });
    }
    return m;
  });

  await logActivity(folderId, ownerId, "invited", null, recipient.email);
  await logActivity(folderId, recipient.id, "joined");

  return {
    userId: recipient.id,
    email: recipient.email,
    name: recipient.name,
    avatarUrl: recipient.avatarUrl,
    role: member.role,
    joinedAt: member.joinedAt.toISOString(),
    sharingPublicKey: recipient.sharingPublicKey,
  };
}

export async function removeMember(
  ownerId: string,
  folderId: string,
  userIdToRemove: string,
): Promise<void> {
  const folder = await prisma.collabFolder.findUnique({
    where: { id: folderId },
    select: { ownerId: true },
  });
  if (!folder) throw new HttpError(HTTP_STATUS.NOT_FOUND, "Folder not found");
  if (folder.ownerId !== ownerId) {
    throw new HttpError(HTTP_STATUS.FORBIDDEN, "Only the owner can remove");
  }
  if (userIdToRemove === ownerId) {
    throw new HttpError(HTTP_STATUS.BAD_REQUEST, "Owner cannot leave their own folder");
  }
  await prisma.collabMember.deleteMany({
    where: { folderId, userId: userIdToRemove },
  });
  await logActivity(folderId, ownerId, "removed_member", null, userIdToRemove);
}

// --- items ---

export async function postCollabItem(
  userId: string,
  folderId: string,
  input: PostItemInput,
): Promise<CollabItemDto> {
  await ensureMember(folderId, userId);
  const members = await prisma.collabMember.findMany({
    where: { folderId },
    select: { id: true, userId: true },
  });
  const memberByUser = new Map(members.map((m) => [m.userId, m.id]));
  // Validate that memberKeys exactly match the active member set.
  const provided = new Set(input.memberKeys.map((k) => k.userId));
  for (const m of members) {
    if (!provided.has(m.userId)) {
      throw new HttpError(
        HTTP_STATUS.BAD_REQUEST,
        `Missing wrapped key for member ${m.userId}`,
      );
    }
  }
  for (const u of provided) {
    if (!memberByUser.has(u)) {
      throw new HttpError(HTTP_STATUS.BAD_REQUEST, `Unknown member ${u}`);
    }
  }

  const created = await prisma.$transaction(async (tx) => {
    const it = await tx.collabItem.create({
      data: {
        folderId,
        creatorId: userId,
        type: input.type,
        title: input.title,
        cipherBlob: fromB64(input.cipherBlob),
        cipherIv: fromB64(input.cipherIv),
      },
    });
    await tx.collabItemKey.createMany({
      data: input.memberKeys.map((k) => ({
        itemId: it.id,
        memberId: memberByUser.get(k.userId)!,
        userId: k.userId,
        wrappedKey: fromB64(k.wrappedKey),
      })),
    });
    return it;
  });

  await logActivity(folderId, userId, "post_item", created.id, input.title);

  // Build DTO with the caller's own wrapped key.
  const myKey = input.memberKeys.find((k) => k.userId === userId)!;
  const creator = await prisma.user.findUnique({
    where: { id: userId },
    select: { name: true },
  });
  return {
    id: created.id,
    type: created.type,
    title: created.title,
    creatorId: userId,
    creatorName: creator?.name ?? "",
    cipherBlob: input.cipherBlob,
    cipherIv: input.cipherIv,
    wrappedKey: myKey.wrappedKey,
    createdAt: created.createdAt.toISOString(),
    updatedAt: created.updatedAt.toISOString(),
  };
}

export async function editCollabItem(
  userId: string,
  folderId: string,
  itemId: string,
  input: EditItemInput,
): Promise<CollabItemDto> {
  await ensureMember(folderId, userId);
  const item = await prisma.collabItem.findFirst({
    where: { id: itemId, folderId },
    select: { creatorId: true },
  });
  if (!item) throw new HttpError(HTTP_STATUS.NOT_FOUND, "Item not found");
  if (item.creatorId !== userId) {
    throw new HttpError(HTTP_STATUS.FORBIDDEN, "Only the creator can edit");
  }

  const cipherChanged =
    input.cipherBlob !== undefined && input.cipherIv !== undefined;
  if (cipherChanged && !input.memberKeys) {
    throw new HttpError(
      HTTP_STATUS.BAD_REQUEST,
      "Re-encrypting requires fresh memberKeys for every member",
    );
  }

  await prisma.$transaction(async (tx) => {
    await tx.collabItem.update({
      where: { id: itemId },
      data: {
        ...(input.title !== undefined ? { title: input.title } : {}),
        ...(cipherChanged
          ? {
              cipherBlob: fromB64(input.cipherBlob!),
              cipherIv: fromB64(input.cipherIv!),
            }
          : {}),
      },
    });
    if (cipherChanged && input.memberKeys) {
      const members = await tx.collabMember.findMany({
        where: { folderId },
        select: { id: true, userId: true },
      });
      const memberByUser = new Map(members.map((m) => [m.userId, m.id]));
      for (const m of members) {
        if (!input.memberKeys.some((k) => k.userId === m.userId)) {
          throw new HttpError(
            HTTP_STATUS.BAD_REQUEST,
            `Missing wrapped key for member ${m.userId}`,
          );
        }
      }
      await tx.collabItemKey.deleteMany({ where: { itemId } });
      await tx.collabItemKey.createMany({
        data: input.memberKeys.map((k) => ({
          itemId,
          memberId: memberByUser.get(k.userId)!,
          userId: k.userId,
          wrappedKey: fromB64(k.wrappedKey),
        })),
      });
    }
  });

  await logActivity(folderId, userId, "edit_item", itemId, input.title ?? null);

  // Return updated DTO.
  const fresh = await prisma.collabItem.findUnique({
    where: { id: itemId },
    include: {
      creator: { select: { id: true, name: true } },
      keys: { where: { userId }, take: 1 },
    },
  });
  if (!fresh || fresh.keys.length === 0) {
    throw new HttpError(HTTP_STATUS.INTERNAL_SERVER_ERROR, "Item refresh failed");
  }
  return {
    id: fresh.id,
    type: fresh.type,
    title: fresh.title,
    creatorId: fresh.creator.id,
    creatorName: fresh.creator.name,
    cipherBlob: b64(fresh.cipherBlob),
    cipherIv: b64(fresh.cipherIv),
    wrappedKey: b64(fresh.keys[0]!.wrappedKey),
    createdAt: fresh.createdAt.toISOString(),
    updatedAt: fresh.updatedAt.toISOString(),
  };
}

export async function deleteCollabItem(
  userId: string,
  folderId: string,
  itemId: string,
): Promise<void> {
  await ensureMember(folderId, userId);
  const item = await prisma.collabItem.findFirst({
    where: { id: itemId, folderId },
    select: { creatorId: true, title: true },
  });
  if (!item) throw new HttpError(HTTP_STATUS.NOT_FOUND, "Item not found");
  if (item.creatorId !== userId) {
    throw new HttpError(HTTP_STATUS.FORBIDDEN, "Only the creator can delete");
  }
  await prisma.collabItem.delete({ where: { id: itemId } });
  await logActivity(folderId, userId, "delete_item", itemId, item.title);
}

export async function logViewItem(
  userId: string,
  folderId: string,
  itemId: string,
): Promise<void> {
  await ensureMember(folderId, userId);
  await logActivity(folderId, userId, "viewed_item", itemId);
}
