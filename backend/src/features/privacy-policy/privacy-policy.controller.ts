import type { Request, Response } from "express";
import { HTTP_STATUS } from "../../constants/http-status";
import { asyncHandler } from "../../shared/async-handler";
import {
  acceptActivePrivacyPolicy,
  getActivePrivacyPolicyDto,
  updateActivePrivacyPolicy,
} from "./privacy-policy.service";
import {
  consentPrivacyPolicySchema,
  updatePrivacyPolicySchema,
} from "./privacy-policy.schema";

export const getCurrentPrivacyPolicy = asyncHandler(async (_req: Request, res: Response) => {
  const data = await getActivePrivacyPolicyDto();
  res.status(HTTP_STATUS.OK).json({ success: true, data });
});

export const updateCurrentPrivacyPolicy = asyncHandler(async (req: Request, res: Response) => {
  const input = updatePrivacyPolicySchema.parse(req.body);
  const data = await updateActivePrivacyPolicy(input);
  res.status(HTTP_STATUS.OK).json({ success: true, data });
});

export const acceptPrivacyPolicyConsent = asyncHandler(async (req: Request, res: Response) => {
  const input = consentPrivacyPolicySchema.parse(req.body);
  const data = await acceptActivePrivacyPolicy(req.auth!.userId, input);
  res.status(HTTP_STATUS.OK).json({ success: true, data });
});
