import { Router } from "express";
import { requireAuth } from "../../shared/auth/middleware";
import {
  create,
  deleteItem,
  detail,
  editItem,
  invite,
  list,
  lookup,
  postItem,
  remove,
  removeMemberCtl,
  update,
  viewItem,
} from "./collab-folder.controller";

export const collabFolderRouter = Router();
collabFolderRouter.use(requireAuth);

// Recipient lookup must be declared before "/:id" so Express doesn't
// match the literal segment as an id.
collabFolderRouter.get("/_lookup/recipient", lookup);

// Folder CRUD
collabFolderRouter.get("/", list);
collabFolderRouter.post("/", create);
collabFolderRouter.get("/:id", detail);
collabFolderRouter.patch("/:id", update);
collabFolderRouter.delete("/:id", remove);

// Membership
collabFolderRouter.post("/:id/members", invite);
collabFolderRouter.delete("/:id/members/:userId", removeMemberCtl);

// Items
collabFolderRouter.post("/:id/items", postItem);
collabFolderRouter.patch("/:id/items/:itemId", editItem);
collabFolderRouter.delete("/:id/items/:itemId", deleteItem);
collabFolderRouter.post("/:id/items/:itemId/viewed", viewItem);
