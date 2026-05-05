import { Router } from "express";
import { requireAuth } from "../../shared/auth/middleware";
import {
  create,
  listReceived,
  listSent,
  lookup,
  myKeys,
  publishKeys,
  revoke,
} from "./share.controller";

export const shareRouter = Router();

shareRouter.use(requireAuth);

// Bootstrap: publish or fetch the caller's X25519 keypair.
shareRouter.post("/keypair", publishKeys);
shareRouter.get("/keypair", myKeys);

// Look up a recipient by email so the client can fetch their public key
// before composing a share. Returns 404 for unknown emails so we don't leak
// arbitrary user existence beyond what email-based sharing already implies.
shareRouter.get("/recipients/lookup", lookup);

// Create / list / revoke shares.
shareRouter.post("/", create);
shareRouter.get("/received", listReceived);
shareRouter.get("/sent", listSent);
shareRouter.delete("/:id", revoke);
