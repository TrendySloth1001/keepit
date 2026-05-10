import type { Request, Response } from "express";
import { HTTP_STATUS } from "../../constants/http-status";
import { asyncHandler } from "../../shared/async-handler";
import {
  createCollabFolderSchema,
  editItemSchema,
  inviteMemberSchema,
  postItemSchema,
  updateCollabFolderSchema,
} from "./collab-folder.schema";
import {
  createCollabFolder,
  deleteCollabFolder,
  deleteCollabItem,
  editCollabItem,
  getCollabFolderDetail,
  inviteMember,
  listCollabFolders,
  logViewItem,
  lookupRecipient,
  postCollabItem,
  removeMember,
  updateCollabFolder,
} from "./collab-folder.service";

export const list = asyncHandler(async (req: Request, res: Response) => {
  const data = await listCollabFolders(req.auth!.userId);
  res.status(HTTP_STATUS.OK).json({ success: true, data });
});

export const create = asyncHandler(async (req: Request, res: Response) => {
  const input = createCollabFolderSchema.parse(req.body);
  const data = await createCollabFolder(req.auth!.userId, input);
  res.status(HTTP_STATUS.CREATED).json({ success: true, data });
});

export const detail = asyncHandler(async (req: Request, res: Response) => {
  const data = await getCollabFolderDetail(req.auth!.userId, req.params.id);
  res.status(HTTP_STATUS.OK).json({ success: true, data });
});

export const update = asyncHandler(async (req: Request, res: Response) => {
  const input = updateCollabFolderSchema.parse(req.body);
  const data = await updateCollabFolder(req.auth!.userId, req.params.id, input);
  res.status(HTTP_STATUS.OK).json({ success: true, data });
});

export const remove = asyncHandler(async (req: Request, res: Response) => {
  await deleteCollabFolder(req.auth!.userId, req.params.id);
  res.status(HTTP_STATUS.NO_CONTENT).send();
});

export const lookup = asyncHandler(async (req: Request, res: Response) => {
  const email = String(req.query.email ?? "").trim();
  const data = await lookupRecipient(email);
  res.status(HTTP_STATUS.OK).json({ success: true, data });
});

export const invite = asyncHandler(async (req: Request, res: Response) => {
  const input = inviteMemberSchema.parse(req.body);
  const data = await inviteMember(req.auth!.userId, req.params.id, input);
  res.status(HTTP_STATUS.CREATED).json({ success: true, data });
});

export const removeMemberCtl = asyncHandler(async (req: Request, res: Response) => {
  await removeMember(req.auth!.userId, req.params.id, req.params.userId);
  res.status(HTTP_STATUS.NO_CONTENT).send();
});

export const postItem = asyncHandler(async (req: Request, res: Response) => {
  const input = postItemSchema.parse(req.body);
  const data = await postCollabItem(req.auth!.userId, req.params.id, input);
  res.status(HTTP_STATUS.CREATED).json({ success: true, data });
});

export const editItem = asyncHandler(async (req: Request, res: Response) => {
  const input = editItemSchema.parse(req.body);
  const data = await editCollabItem(
    req.auth!.userId,
    req.params.id,
    req.params.itemId,
    input,
  );
  res.status(HTTP_STATUS.OK).json({ success: true, data });
});

export const deleteItem = asyncHandler(async (req: Request, res: Response) => {
  await deleteCollabItem(req.auth!.userId, req.params.id, req.params.itemId);
  res.status(HTTP_STATUS.NO_CONTENT).send();
});

export const viewItem = asyncHandler(async (req: Request, res: Response) => {
  await logViewItem(req.auth!.userId, req.params.id, req.params.itemId);
  res.status(HTTP_STATUS.NO_CONTENT).send();
});
