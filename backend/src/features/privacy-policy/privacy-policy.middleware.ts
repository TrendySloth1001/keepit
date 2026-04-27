import type { NextFunction, Request, Response } from "express";
import { HTTP_STATUS } from "../../constants/http-status";
import { MESSAGES } from "../../constants/messages";
import { env } from "../../constants/env";
import { HttpError } from "../../shared/http-error";

export function requirePolicyEditKey(
  req: Request,
  _res: Response,
  next: NextFunction,
): void {
  const key = req.headers["x-policy-admin-key"];
  const provided = typeof key === "string" ? key : Array.isArray(key) ? key[0] : undefined;

  if (!provided || provided !== env.PRIVACY_POLICY_ADMIN_KEY) {
    next(new HttpError(HTTP_STATUS.FORBIDDEN, MESSAGES.UNAUTHORIZED));
    return;
  }

  next();
}
