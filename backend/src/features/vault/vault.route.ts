import { Router } from "express";
import { requireAuth } from "../../shared/auth/middleware";
import {
  create,
  downloadUrl,
  finalizeUploadCtl,
  getOne,
  initiateUploadCtl,
  list,
  remove,
  storage,
  update,
} from "./vault.controller";

export const vaultRouter = Router();

vaultRouter.use(requireAuth);

vaultRouter.get("/storage", storage);
vaultRouter.post("/uploads/initiate", initiateUploadCtl);
vaultRouter.post("/uploads/finalize", finalizeUploadCtl);
vaultRouter.get("/items/:id/download", downloadUrl);

vaultRouter.get("/items", list);
vaultRouter.post("/items", create);
vaultRouter.get("/items/:id", getOne);
vaultRouter.patch("/items/:id", update);
vaultRouter.delete("/items/:id", remove);
