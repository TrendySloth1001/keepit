import { Router } from "express";
import { requireAuth } from "../../shared/auth/middleware";
import {
  create,
  createBundleCtl,
  downloadCiphertext,
  listReceived,
  listSent,
  lookup,
  markOpened,
  myKeys,
  publishKeys,
  revoke,
  revokeBundleCtl,
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
// Folder-share bundles: one txn-atomic POST creates the bundle row plus all
// child VaultShare rows. Bundles share the same /received and /sent inbox as
// individual shares — the bundleId/bundleName columns let the UI group them.
shareRouter.post("/bundles", createBundleCtl);
shareRouter.delete("/bundles/:id", revokeBundleCtl);
shareRouter.get("/received", listReceived);
shareRouter.get("/sent", listSent);
// Recipient streams the encrypted body of a shared file/image. The
// per-file DEK rides inside the share payload (sealed to the recipient), so
// the server never sees plaintext. This endpoint also auto-bumps the share's
// read receipt — no separate /opened call needed for files.
shareRouter.get("/:id/content", downloadCiphertext);
// Recipient marks a non-file share as opened (after successful local decrypt).
// Idempotent-ish: openCount keeps climbing, but firstOpenedAt only sets once.
shareRouter.post("/:id/opened", markOpened);
shareRouter.delete("/:id", revoke);
