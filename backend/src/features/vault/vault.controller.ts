import type { Request, Response } from "express";
import { HTTP_STATUS } from "../../constants/http-status";
import { asyncHandler } from "../../shared/async-handler";
import {
  createVaultItem,
  deleteVaultItem,
  finalizeUpload,
  getDownloadUrl,
  getStorageStats,
  getVaultItem,
  initiateUpload,
  listVaultItems,
  updateVaultItem,
} from "./vault.service";
import {
  createVaultItemSchema,
  finalizeUploadSchema,
  initiateUploadSchema,
  listVaultItemsSchema,
  updateVaultItemSchema,
} from "./vault.schema";

export const list = asyncHandler(async (req: Request, res: Response) => {
  const input = listVaultItemsSchema.parse(req.query);
  const data = await listVaultItems(req.auth!.userId, input);
  res.status(HTTP_STATUS.OK).json({ success: true, data });
});

export const getOne = asyncHandler(async (req: Request, res: Response) => {
  const data = await getVaultItem(req.auth!.userId, req.params.id);
  res.status(HTTP_STATUS.OK).json({ success: true, data });
});

export const create = asyncHandler(async (req: Request, res: Response) => {
  const input = createVaultItemSchema.parse(req.body);
  const data = await createVaultItem(req.auth!.userId, input);
  res.status(HTTP_STATUS.CREATED).json({ success: true, data });
});

export const update = asyncHandler(async (req: Request, res: Response) => {
  const input = updateVaultItemSchema.parse(req.body);
  const data = await updateVaultItem(req.auth!.userId, req.params.id, input);
  res.status(HTTP_STATUS.OK).json({ success: true, data });
});

export const remove = asyncHandler(async (req: Request, res: Response) => {
  await deleteVaultItem(req.auth!.userId, req.params.id);
  res.status(HTTP_STATUS.NO_CONTENT).send();
});

export const initiateUploadCtl = asyncHandler(async (req: Request, res: Response) => {
  const input = initiateUploadSchema.parse(req.body);
  const data = await initiateUpload(req.auth!.userId, input);
  res.status(HTTP_STATUS.CREATED).json({ success: true, data });
});

export const finalizeUploadCtl = asyncHandler(async (req: Request, res: Response) => {
  const input = finalizeUploadSchema.parse(req.body);
  const data = await finalizeUpload(req.auth!.userId, input);
  res.status(HTTP_STATUS.OK).json({ success: true, data });
});

export const downloadUrl = asyncHandler(async (req: Request, res: Response) => {
  const data = await getDownloadUrl(req.auth!.userId, req.params.id);
  res.status(HTTP_STATUS.OK).json({ success: true, data });
});

export const storage = asyncHandler(async (req: Request, res: Response) => {
  const data = await getStorageStats(req.auth!.userId);
  res.status(HTTP_STATUS.OK).json({ success: true, data });
});
