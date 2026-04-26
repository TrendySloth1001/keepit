import type { NextFunction, Request, Response } from "express";
import { HTTP_STATUS } from "../../constants/http-status";
import { MESSAGES } from "../../constants/messages";
import { HttpError } from "../http-error";
import { prisma } from "../prisma";
import { hashJti, verifySessionToken } from "./jwt";

declare global {
  namespace Express {
    interface Request {
      auth?: { userId: string; jti: string };
    }
  }
}

export async function requireAuth(req: Request, _res: Response, next: NextFunction): Promise<void> {
  try {
    const header = req.headers.authorization;
    if (!header || !header.startsWith("Bearer ")) {
      throw new HttpError(HTTP_STATUS.UNAUTHORIZED, MESSAGES.UNAUTHORIZED);
    }
    const token = header.slice("Bearer ".length).trim();
    const { sub, jti } = verifySessionToken(token);
    const session = await prisma.session.findUnique({ where: { jtiHash: hashJti(jti) } });
    if (!session || session.revokedAt || session.expiresAt < new Date() || session.userId !== sub) {
      throw new HttpError(HTTP_STATUS.UNAUTHORIZED, MESSAGES.INVALID_SESSION);
    }
    req.auth = { userId: sub, jti };
    next();
  } catch (err) {
    if (err instanceof HttpError) return next(err);
    next(new HttpError(HTTP_STATUS.UNAUTHORIZED, MESSAGES.INVALID_SESSION));
  }
}
