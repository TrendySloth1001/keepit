import { z } from "zod";

export const createFolderSchema = z.object({
  name: z.string().trim().min(1).max(80),
  iconKey: z.string().trim().min(1).max(64).optional(),
});
export type CreateFolderInput = z.infer<typeof createFolderSchema>;

export const updateFolderSchema = z.object({
  name: z.string().trim().min(1).max(80).optional(),
  // null clears the icon; undefined leaves it untouched.
  iconKey: z.string().trim().min(1).max(64).nullable().optional(),
});
export type UpdateFolderInput = z.infer<typeof updateFolderSchema>;
