import crypto from "node:crypto";
import jwt from "jsonwebtoken";
import { env } from "../../constants/env";

export interface SessionTokenPayload {
  sub: string; // user id
  jti: string;
}

export interface IssuedToken {
  token: string;
  jti: string;
  jtiHash: string;
  expiresAt: Date;
}

export function issueSessionToken(userId: string): IssuedToken {
  const jti = crypto.randomUUID();
  const expiresAt = new Date(Date.now() + env.JWT_TTL_SECONDS * 1000);
  const token = jwt.sign({ sub: userId, jti }, env.JWT_SECRET, {
    expiresIn: env.JWT_TTL_SECONDS,
  });
  return {
    token,
    jti,
    jtiHash: hashJti(jti),
    expiresAt,
  };
}

export function verifySessionToken(token: string): SessionTokenPayload {
  const decoded = jwt.verify(token, env.JWT_SECRET) as jwt.JwtPayload & {
    sub?: string;
    jti?: string;
  };
  if (!decoded.sub || !decoded.jti) {
    throw new Error("Malformed token payload");
  }
  return { sub: decoded.sub, jti: decoded.jti };
}

export function hashJti(jti: string): string {
  return crypto.createHash("sha256").update(jti).digest("hex");
}
