import { Router } from "express";
import { validate } from "../../shared/validate";
import {
  createUserController,
  deleteUserController,
  getUserByIdController,
  getUsersController,
  updateUserController,
} from "./user.contoller";
import { createUserSchema, updateUserSchema } from "./user.schema";

export const userRouter = Router();

userRouter.post("/", validate(createUserSchema), createUserController);
userRouter.get("/", getUsersController);
userRouter.get("/:id", getUserByIdController);
userRouter.patch("/:id", validate(updateUserSchema), updateUserController);
userRouter.delete("/:id", deleteUserController);
