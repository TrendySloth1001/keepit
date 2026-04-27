import cors from "cors";
import express from "express";
import helmet from "helmet";
import morgan from "morgan";
import { HTTP_STATUS } from "./constants/http-status";
import { errorHandler, notFoundHandler } from "./shared/error-handler";
import { authRouter } from "./features/auth/auth.route";
import { privacyPolicyRouter } from "./features/privacy-policy/privacy-policy.route";
import { vaultRouter } from "./features/vault/vault.route";
import { rateLimitMiddleware } from "./shared/rate-limit";

export const app = express();

app.use(helmet());
app.use(cors());
app.use(express.json({ limit: "2mb" }));
app.use(morgan("dev"));
app.use(rateLimitMiddleware);

app.get("/health", (_req, res) => {
  res.status(HTTP_STATUS.OK).json({
    success: true,
    message: "Server is healthy",
  });
});

app.use("/api/v1/auth", authRouter);
app.use("/api/v1/privacy-policy", privacyPolicyRouter);
app.use("/api/v1/vault", vaultRouter);

app.use(notFoundHandler);
app.use(errorHandler);
