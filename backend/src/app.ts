import cors from "cors";
import express from "express";
import helmet from "helmet";
import morgan from "morgan";
import { HTTP_STATUS } from "./constants/http-status";
import { errorHandler, notFoundHandler } from "./shared/error-handler";
import { userRouter } from "./features/user/user.route";

export const app = express();

app.use(helmet());
app.use(cors());
app.use(express.json());
app.use(morgan("dev"));

app.get("/health", (_req, res) => {
  res.status(HTTP_STATUS.OK).json({
    success: true,
    message: "Server is healthy",
  });
});

app.use("/api/v1/users", userRouter);

app.use(notFoundHandler);
app.use(errorHandler);
