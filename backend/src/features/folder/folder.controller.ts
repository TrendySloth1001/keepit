import type { Request, Response } from "express";
import { HTTP_STATUS } from "../../constants/http-status";
import { asyncHandler } from "../../shared/async-handler";
import { createFolderSchema, updateFolderSchema } from "./folder.schema";
import {
  createFolder,
  deleteFolder,
  listFolders,
  updateFolder,
} from "./folder.service";

export const list = asyncHandler(async (req: Request, res: Response) => {
  const data = await listFolders(req.auth!.userId);
  res.status(HTTP_STATUS.OK).json({ success: true, data });
});

export const create = asyncHandler(async (req: Request, res: Response) => {
  const input = createFolderSchema.parse(req.body);
  const data = await createFolder(req.auth!.userId, input);
  res.status(HTTP_STATUS.CREATED).json({ success: true, data });
});

export const update = asyncHandler(async (req: Request, res: Response) => {
  const input = updateFolderSchema.parse(req.body);
  const data = await updateFolder(req.auth!.userId, req.params.id, input);
  res.status(HTTP_STATUS.OK).json({ success: true, data });
});

export const remove = asyncHandler(async (req: Request, res: Response) => {
  await deleteFolder(req.auth!.userId, req.params.id);
  res.status(HTTP_STATUS.NO_CONTENT).send();
});
