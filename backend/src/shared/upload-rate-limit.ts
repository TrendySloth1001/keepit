import type { NextFunction, Request, Response } from "express";
import { HTTP_STATUS } from "../constants/http-status";
import { env } from "../constants/env";

/**
 * Sliding-window upload limiter.
 *
 * Two budgets, per authenticated user (falls back to client IP when the
 * request is unauthenticated):
 *   - Request count: at most `UPLOAD_RATE_LIMIT_PER_HOUR` upload-related calls
 *     per rolling hour. Catches burst abuse of the small endpoints
 *     (initiate/finalize) without inspecting bodies.
 *   - Byte budget: total bytes accepted across all upload calls capped at
 *     `UPLOAD_BYTES_PER_HOUR`. Forces a daily-ish ceiling on egress to S3
 *     even if every individual file is below the per-file size limit.
 *
 * Uses a fixed-size ring of timestamps so memory grows with active users,
 * not with traffic.
 */

interface Hit {
  ts: number;
  bytes: number;
}

const WINDOW_MS = 60 * 60 * 1000;
const hits = new Map<string, Hit[]>();

function keyFor(req: Request): string {
  const userId = req.auth?.userId;
  if (userId) return `u:${userId}`;
  const ip = req.ip ?? req.socket.remoteAddress ?? "unknown";
  return `ip:${ip}`;
}

function gc(now: number, list: Hit[]): Hit[] {
  const cutoff = now - WINDOW_MS;
  // Hits are appended in time order, so prefix-trim is enough.
  let i = 0;
  while (i < list.length && list[i].ts < cutoff) i += 1;
  return i === 0 ? list : list.slice(i);
}

export function uploadRateLimiter() {
  return function (req: Request, res: Response, next: NextFunction): void {
    const now = Date.now();
    const key = keyFor(req);
    const trimmed = gc(now, hits.get(key) ?? []);

    const declared = (() => {
      const raw = req.headers["content-length"];
      if (typeof raw !== "string") return 0;
      const n = Number.parseInt(raw, 10);
      return Number.isFinite(n) && n > 0 ? n : 0;
    })();

    if (declared > env.MAX_UPLOAD_BYTES) {
      const max = env.MAX_UPLOAD_BYTES;
      res.status(HTTP_STATUS.PAYLOAD_TOO_LARGE).json({
        success: false,
        message: `Payload exceeds the ${(max / (1024 * 1024)).toFixed(0)} MB upload limit`,
      });
      return;
    }

    const count = trimmed.length;
    const bytes = trimmed.reduce((a, h) => a + h.bytes, 0);

    if (count >= env.UPLOAD_RATE_LIMIT_PER_HOUR) {
      const oldest = trimmed[0]?.ts ?? now;
      const retryAfter = Math.max(1, Math.ceil((oldest + WINDOW_MS - now) / 1000));
      res.setHeader("Retry-After", String(retryAfter));
      res.status(HTTP_STATUS.TOO_MANY_REQUESTS).json({
        success: false,
        message: "Upload rate limit reached. Try again later.",
      });
      return;
    }

    if (bytes + declared > env.UPLOAD_BYTES_PER_HOUR) {
      const oldest = trimmed[0]?.ts ?? now;
      const retryAfter = Math.max(1, Math.ceil((oldest + WINDOW_MS - now) / 1000));
      res.setHeader("Retry-After", String(retryAfter));
      res.status(HTTP_STATUS.TOO_MANY_REQUESTS).json({
        success: false,
        message: "Hourly upload size budget exceeded. Try again later.",
      });
      return;
    }

    trimmed.push({ ts: now, bytes: declared });
    hits.set(key, trimmed);
    next();
  };
}
