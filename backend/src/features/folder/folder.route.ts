import { Router } from "express";
import { requireAuth } from "../../shared/auth/middleware";
import { create, list, remove, update } from "./folder.controller";

export const folderRouter = Router();
folderRouter.use(requireAuth);

folderRouter.get("/", list);
folderRouter.post("/", create);
folderRouter.patch("/:id", update);
folderRouter.delete("/:id", remove);