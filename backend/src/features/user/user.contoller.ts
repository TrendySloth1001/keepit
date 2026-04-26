import type { Request, Response } from "express";
import { HTTP_STATUS } from "../../constants/http-status";
import { asyncHandler } from "../../shared/async-handler";
import {
  createUser,
  deleteUser,
  getUserById,
  getUsers,
  updateUser,
} from "./user.service";

export const createUserController = asyncHandler(async (req: Request, res: Response) => {
  const user = await createUser(req.body);
  res.status(HTTP_STATUS.CREATED).json({
    success: true,
    data: user,
  });
});

export const getUsersController = asyncHandler(async (_req: Request, res: Response) => {
  const users = await getUsers();
  res.status(HTTP_STATUS.OK).json({
    success: true,
    data: users,
  });
});

export const getUserByIdController = asyncHandler(async (req: Request, res: Response) => {
  const user = await getUserById(req.params.id);
  res.status(HTTP_STATUS.OK).json({
    success: true,
    data: user,
  });
});

export const updateUserController = asyncHandler(async (req: Request, res: Response) => {
  const user = await updateUser(req.params.id, req.body);
  res.status(HTTP_STATUS.OK).json({
    success: true,
    data: user,
  });
});

export const deleteUserController = asyncHandler(async (req: Request, res: Response) => {
  await deleteUser(req.params.id);
  res.status(HTTP_STATUS.NO_CONTENT).send();
});
