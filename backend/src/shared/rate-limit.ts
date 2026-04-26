import type { NextFunction, Request, Response } from "express";
import { HTTP_STATUS } from "../constants/http-status";

type Bucket = { count: number; resetAt: number };

const WINDOW_MS = 60_000;
const MAX_REQUESTS = 120;
const buckets = new Map<string, Bucket>();

function keyFor(req: Request): string {
  const ip = req.ip ?? req.socket.remoteAddress ?? "unknown";
  return `${ip}:${req.method}:${req.baseUrl}${req.path}`;
}

export function rateLimitMiddleware(req: Request, res: Response, next: NextFunction): void {
  const now = Date.now();
  const key = keyFor(req);
  const bucket = buckets.get(key);

  if (!bucket || now >= bucket.resetAt) {
    buckets.set(key, { count: 1, resetAt: now + WINDOW_MS });
    next();
    return;
  }

  if (bucket.count >= MAX_REQUESTS) {
    const retryAfter = Math.max(1, Math.ceil((bucket.resetAt - now) / 1000));
    res.setHeader("Retry-After", String(retryAfter));
    res.status(HTTP_STATUS.TOO_MANY_REQUESTS).json({
      success: false,
      message: "Too many requests. Please try again shortly.",
    });
    return;
  }

  bucket.count += 1;
  next();
}
