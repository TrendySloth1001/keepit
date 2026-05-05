import type { Request, Response } from "express";
import { HTTP_STATUS } from "../../constants/http-status";
import { asyncHandler } from "../../shared/async-handler";
import {
  getCurrentUser,
  initMasterPassword,
  rotateMasterPassword,
  signInWithGoogle,
  signOut,
  verifyMasterPassword,
} from "./auth.service";

export const googleSignIn = asyncHandler(async (req: Request, res: Response) => {
  const result = await signInWithGoogle(req.body, req.headers["user-agent"]);
  res.status(HTTP_STATUS.OK).json({
    success: true,
    data: result,
  });
});

export const logout = asyncHandler(async (req: Request, res: Response) => {
  await signOut(req.auth!.userId, req.auth!.jti);
  res.status(HTTP_STATUS.NO_CONTENT).send();
});

export const initMaster = asyncHandler(async (req: Request, res: Response) => {
  await initMasterPassword(req.auth!.userId, req.body);
  res.status(HTTP_STATUS.NO_CONTENT).send();
});

export const verifyMaster = asyncHandler(async (req: Request, res: Response) => {
  await verifyMasterPassword(req.auth!.userId, req.body);
  res.status(HTTP_STATUS.NO_CONTENT).send();
});

export const rotateMaster = asyncHandler(async (req: Request, res: Response) => {
  await rotateMasterPassword(req.auth!.userId, req.body);
  res.status(HTTP_STATUS.NO_CONTENT).send();
});

export const me = asyncHandler(async (req: Request, res: Response) => {
  const data = await getCurrentUser(req.auth!.userId);
  res.status(HTTP_STATUS.OK).json({ success: true, data });
});
