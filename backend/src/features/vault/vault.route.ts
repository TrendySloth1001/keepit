import express, { Router } from "express";
import { requireAuth } from "../../shared/auth/middleware";
import { uploadRateLimiter } from "../../shared/upload-rate-limit";
import {
  abortUploadCtl,
  batchDelete,
  batchGet,
  create,
  downloadContentCtl,
  downloadUrl,
  finalizeUploadCtl,
  getOne,
  initiateUploadCtl,
  list,
  remove,
  storage,
  storageTimeline,
  uploadChunkCtl,
  uploadContentCtl,
  update,
} from "./vault.controller";

export const vaultRouter = Router();

vaultRouter.use(requireAuth);

vaultRouter.get("/storage", storage);
vaultRouter.get("/storage/timeline", storageTimeline);
vaultRouter.post("/items/batch", batchGet);
vaultRouter.post("/items/batch-delete", batchDelete);
// Upload endpoints are aggressively rate-limited (per-user request count
// and bytes-per-hour) on top of per-file size cap. The express.raw limits
// are intentionally just above the per-chunk / per-file ceiling — anything
// larger is rejected at the parser before hitting handler logic.
vaultRouter.post("/uploads/initiate", uploadRateLimiter(), initiateUploadCtl);
vaultRouter.post("/uploads/finalize", uploadRateLimiter(), finalizeUploadCtl);
vaultRouter.post(
  "/uploads/:itemId/content",
  uploadRateLimiter(),
  express.raw({ type: "application/octet-stream", limit: "16mb" }),
  uploadContentCtl,
);
vaultRouter.post(
  "/uploads/:itemId/chunks/:partNumber",
  uploadRateLimiter(),
  express.raw({ type: "application/octet-stream", limit: "6mb" }),
  uploadChunkCtl,
);
vaultRouter.delete("/uploads/:itemId", abortUploadCtl);
vaultRouter.get("/items/:id/download", downloadUrl);
vaultRouter.get("/items/:id/content", downloadContentCtl);

vaultRouter.get("/items", list);
vaultRouter.post("/items", create);
vaultRouter.get("/items/:id", getOne);
vaultRouter.patch("/items/:id", update);
vaultRouter.delete("/items/:id", remove);
