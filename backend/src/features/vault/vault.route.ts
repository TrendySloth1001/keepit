import express, { Router } from "express";
import { requireAuth } from "../../shared/auth/middleware";
import {
  abortUploadCtl,
  create,
  downloadContentCtl,
  downloadUrl,
  finalizeUploadCtl,
  getOne,
  initiateUploadCtl,
  list,
  remove,
  storage,
  uploadChunkCtl,
  uploadContentCtl,
  update,
} from "./vault.controller";

export const vaultRouter = Router();

vaultRouter.use(requireAuth);

vaultRouter.get("/storage", storage);
vaultRouter.post("/uploads/initiate", initiateUploadCtl);
vaultRouter.post("/uploads/finalize", finalizeUploadCtl);
vaultRouter.post(
  "/uploads/:itemId/content",
  express.raw({ type: "application/octet-stream", limit: "60mb" }),
  uploadContentCtl,
);
vaultRouter.post(
  "/uploads/:itemId/chunks/:partNumber",
  express.raw({ type: "application/octet-stream", limit: "10mb" }),
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
