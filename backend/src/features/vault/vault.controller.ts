import type { Request, Response } from "express";
import { HTTP_STATUS } from "../../constants/http-status";
import { asyncHandler } from "../../shared/async-handler";
import {
  abortUpload,
  batchDeleteVaultItems,
  batchGetVaultItems,
  createVaultItem,
  downloadCiphertextForItem,
  deleteVaultItem,
  finalizeUpload,
  getDownloadUrl,
  getStorageStats,
  getStorageTimeline,
  getVaultItem,
  initiateUpload,
  listVaultItems,
  uploadChunkForItem,
  uploadCiphertextForItem,
  updateVaultItem,
} from "./vault.service";
import {
  batchIdsSchema,
  createVaultItemSchema,
  finalizeUploadSchema,
  initiateUploadSchema,
  listVaultItemsSchema,
  statsRangeSchema,
  uploadChunkParamsSchema,
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

export const uploadContentCtl = asyncHandler(async (req: Request, res: Response) => {
  const bytes = req.body;
  if (!(bytes instanceof Buffer) || bytes.length === 0) {
    res.status(HTTP_STATUS.BAD_REQUEST).json({
      success: false,
      message: "Binary request body is required",
    });
    return;
  }

  await uploadCiphertextForItem(req.auth!.userId, req.params.itemId, bytes);
  res.status(HTTP_STATUS.NO_CONTENT).send();
});

export const uploadChunkCtl = asyncHandler(async (req: Request, res: Response) => {
  const params = uploadChunkParamsSchema.parse(req.params);
  const bytes = req.body;
  if (!(bytes instanceof Buffer) || bytes.length === 0) {
    res.status(HTTP_STATUS.BAD_REQUEST).json({
      success: false,
      message: "Binary request body is required",
    });
    return;
  }

  await uploadChunkForItem(req.auth!.userId, params.itemId, params.partNumber, bytes);
  res.status(HTTP_STATUS.NO_CONTENT).send();
});

export const abortUploadCtl = asyncHandler(async (req: Request, res: Response) => {
  await abortUpload(req.auth!.userId, req.params.itemId);
  res.status(HTTP_STATUS.NO_CONTENT).send();
});

export const downloadUrl = asyncHandler(async (req: Request, res: Response) => {
  const data = await getDownloadUrl(req.auth!.userId, req.params.id);
  res.status(HTTP_STATUS.OK).json({ success: true, data });
});

export const downloadContentCtl = asyncHandler(async (req: Request, res: Response) => {
  const data = await downloadCiphertextForItem(req.auth!.userId, req.params.id);
  res
    .status(HTTP_STATUS.OK)
    .setHeader("Content-Type", "application/octet-stream")
    .setHeader("Content-Length", String(data.byteLength))
    .send(Buffer.from(data));
});

export const storage = asyncHandler(async (req: Request, res: Response) => {
  const data = await getStorageStats(req.auth!.userId);
  res.status(HTTP_STATUS.OK).json({ success: true, data });
});

export const storageTimeline = asyncHandler(async (req: Request, res: Response) => {
  const input = statsRangeSchema.parse(req.query);
  const data = await getStorageTimeline(req.auth!.userId, input);
  res.status(HTTP_STATUS.OK).json({ success: true, data });
});

export const batchGet = asyncHandler(async (req: Request, res: Response) => {
  const input = batchIdsSchema.parse(req.body);
  const data = await batchGetVaultItems(req.auth!.userId, input);
  res.status(HTTP_STATUS.OK).json({ success: true, data });
});

export const batchDelete = asyncHandler(async (req: Request, res: Response) => {
  const input = batchIdsSchema.parse(req.body);
  const data = await batchDeleteVaultItems(req.auth!.userId, input);
  res.status(HTTP_STATUS.OK).json({ success: true, data });
});
