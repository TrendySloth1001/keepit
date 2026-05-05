import { Router } from "express";
import { requireAuth } from "../../shared/auth/middleware";
import { validate } from "../../shared/validate";
import {
  googleSignIn,
  initMaster,
  logout,
  me,
  rotateMaster,
  verifyMaster,
} from "./auth.controller";
import {
  googleSignInSchema,
  masterInitSchema,
  masterRotateSchema,
  masterVerifySchema,
} from "./auth.schema";

export const authRouter = Router();

authRouter.post("/google", validate(googleSignInSchema), googleSignIn);
authRouter.get("/me", requireAuth, me);
authRouter.post("/logout", requireAuth, logout);
authRouter.post("/master/init", requireAuth, validate(masterInitSchema), initMaster);
authRouter.post("/master/verify", requireAuth, validate(masterVerifySchema), verifyMaster);
authRouter.post(
  "/master/rotate",
  requireAuth,
  validate(masterRotateSchema),
  rotateMaster,
);
