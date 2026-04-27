import { Router } from "express";
import { requireAuth } from "../../shared/auth/middleware";
import {
  acceptPrivacyPolicyConsent,
  getCurrentPrivacyPolicy,
  updateCurrentPrivacyPolicy,
} from "./privacy-policy.controller";
import { requirePolicyEditKey } from "./privacy-policy.middleware";

export const privacyPolicyRouter = Router();

privacyPolicyRouter.get("/current", getCurrentPrivacyPolicy);
privacyPolicyRouter.put("/current", requirePolicyEditKey, updateCurrentPrivacyPolicy);
privacyPolicyRouter.post("/consent", requireAuth, acceptPrivacyPolicyConsent);
