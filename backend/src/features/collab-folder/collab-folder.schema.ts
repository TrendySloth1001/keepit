import { z } from "zod";

const base64 = z.string().min(1).max(20_000_000);

export const createCollabFolderSchema = z.object({
  name: z.string().trim().min(1).max(80),
  iconKey: z.string().trim().min(1).max(64).optional(),
});
export type CreateCollabFolderInput = z.infer<typeof createCollabFolderSchema>;

export const updateCollabFolderSchema = z.object({
  name: z.string().trim().min(1).max(80).optional(),
  iconKey: z.string().trim().min(1).max(64).nullable().optional(),
});
export type UpdateCollabFolderInput = z.infer<typeof updateCollabFolderSchema>;

export const inviteMemberSchema = z.object({
  email: z.string().email().max(254),
  // The owner pre-wraps every existing item's DEK to the new member's
  // public key (one rewrap per existing item). The server stores these so
  // the new member can decrypt prior content. List MAY be empty if the
  // folder has no items yet.
  itemKeys: z
    .array(
      z.object({
        itemId: z.string().cuid(),
        wrappedKey: base64,
      }),
    )
    .max(1000),
});
export type InviteMemberInput = z.infer<typeof inviteMemberSchema>;

export const postItemSchema = z.object({
  type: z.enum(["password", "note", "key", "file", "image"]),
  title: z.string().trim().min(1).max(200),
  cipherBlob: base64,
  cipherIv: base64,
  // One wrappedKey per current member — caller MUST include themselves.
  // Server validates the set matches the active member set exactly.
  memberKeys: z
    .array(
      z.object({
        userId: z.string().cuid(),
        wrappedKey: base64,
      }),
    )
    .min(1)
    .max(100),
});
export type PostItemInput = z.infer<typeof postItemSchema>;

export const editItemSchema = z.object({
  title: z.string().trim().min(1).max(200).optional(),
  cipherBlob: base64.optional(),
  cipherIv: base64.optional(),
  // When ciphertext changes, the DEK changes too — rewrapped per member.
  memberKeys: z
    .array(
      z.object({
        userId: z.string().cuid(),
        wrappedKey: base64,
      }),
    )
    .optional(),
});
export type EditItemInput = z.infer<typeof editItemSchema>;
