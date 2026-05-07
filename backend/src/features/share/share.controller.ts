import type { Request, Response } from "express";
import { HTTP_STATUS } from "../../constants/http-status";
import { asyncHandler } from "../../shared/async-handler";
import {
  createBundleSchema,
  createShareSchema,
  lookupRecipientSchema,
  publishKeypairSchema,
} from "./share.schema";
import {
  createBundle,
  createShare,
  getMyKeypair,
  getSharedCiphertext,
  listReceivedShares,
  listSentShares,
  lookupRecipient,
  markShareOpened,
  publishKeypair,
  revokeBundle,
  revokeShare,
} from "./share.service";

export const lookup = asyncHandler(async (req: Request, res: Response) => {
  const input = lookupRecipientSchema.parse(req.query);
  const data = await lookupRecipient(input);
  res.status(HTTP_STATUS.OK).json({ success: true, data });
});

export const publishKeys = asyncHandler(
  async (req: Request, res: Response) => {
    const input = publishKeypairSchema.parse(req.body);
    await publishKeypair(req.auth!.userId, input);
    res.status(HTTP_STATUS.OK).json({ success: true });
  },
);

export const myKeys = asyncHandler(async (req: Request, res: Response) => {
  const data = await getMyKeypair(req.auth!.userId);
  res.status(HTTP_STATUS.OK).json({ success: true, data });
});

export const create = asyncHandler(async (req: Request, res: Response) => {
  const input = createShareSchema.parse(req.body);
  const data = await createShare(req.auth!.userId, input);
  res.status(HTTP_STATUS.CREATED).json({ success: true, data });
});

export const listReceived = asyncHandler(
  async (req: Request, res: Response) => {
    const data = await listReceivedShares(req.auth!.userId);
    res.status(HTTP_STATUS.OK).json({ success: true, data });
  },
);

export const listSent = asyncHandler(async (req: Request, res: Response) => {
  const data = await listSentShares(req.auth!.userId);
  res.status(HTTP_STATUS.OK).json({ success: true, data });
});

export const downloadCiphertext = asyncHandler(
  async (req: Request, res: Response) => {
    const data = await getSharedCiphertext(req.auth!.userId, req.params.id);
    res
      .status(HTTP_STATUS.OK)
      .setHeader("Content-Type", "application/octet-stream")
      .setHeader("Content-Length", String(data.byteLength))
      .send(Buffer.from(data));
  },
);

export const revoke = asyncHandler(async (req: Request, res: Response) => {
  await revokeShare(req.auth!.userId, req.params.id);
  res.status(HTTP_STATUS.OK).json({ success: true });
});

export const markOpened = asyncHandler(async (req: Request, res: Response) => {
  await markShareOpened(req.auth!.userId, req.params.id);
  res.status(HTTP_STATUS.OK).json({ success: true });
});

export const createBundleCtl = asyncHandler(
  async (req: Request, res: Response) => {
    const input = createBundleSchema.parse(req.body);
    const data = await createBundle(req.auth!.userId, input);
    res.status(HTTP_STATUS.CREATED).json({ success: true, data });
  },
);

export const revokeBundleCtl = asyncHandler(
  async (req: Request, res: Response) => {
    await revokeBundle(req.auth!.userId, req.params.id);
    res.status(HTTP_STATUS.OK).json({ success: true });
  },
);
