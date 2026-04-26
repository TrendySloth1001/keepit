import { Router } from "express";
import { requireAuth } from "../../shared/auth/middleware";
import { validate } from "../../shared/validate";
import {
  googleSignIn,
  initMaster,
  logout,
  verifyMaster,
} from "./auth.controller";
import {
  googleSignInSchema,
  masterInitSchema,
  masterVerifySchema,
} from "./auth.schema";

export const authRouter = Router();

authRouter.post("/google", validate(googleSignInSchema), googleSignIn);
authRouter.post("/logout", requireAuth, logout);
authRouter.post("/master/init", requireAuth, validate(masterInitSchema), initMaster);
authRouter.post("/master/verify", requireAuth, validate(masterVerifySchema), verifyMaster);
