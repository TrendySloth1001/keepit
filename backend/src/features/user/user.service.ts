import type { User } from "@prisma/client";
import { MESSAGES } from "../../constants/messages";
import { HTTP_STATUS } from "../../constants/http-status";
import { HttpError } from "../../shared/http-error";
import { prisma } from "../../shared/prisma";
import type { CreateUserInput, UpdateUserInput } from "./user.schema";

const getByIdOrThrow = async (id: string): Promise<User> => {
  const user = await prisma.user.findUnique({ where: { id } });
  if (!user) {
    throw new HttpError(HTTP_STATUS.NOT_FOUND, MESSAGES.USER_NOT_FOUND);
  }
  return user;
};

export const createUser = async (payload: CreateUserInput): Promise<User> => {
  const existing = await prisma.user.findUnique({ where: { email: payload.email } });

  if (existing) {
    throw new HttpError(HTTP_STATUS.CONFLICT, MESSAGES.USER_EMAIL_EXISTS);
  }

  return prisma.user.create({
    data: payload,
  });
};

export const getUsers = async (): Promise<User[]> => {
  return prisma.user.findMany({ orderBy: { createdAt: "desc" } });
};

export const getUserById = async (id: string): Promise<User> => {
  return getByIdOrThrow(id);
};

export const updateUser = async (id: string, payload: UpdateUserInput): Promise<User> => {
  await getByIdOrThrow(id);
  return prisma.user.update({
    where: { id },
    data: payload,
  });
};

export const deleteUser = async (id: string): Promise<void> => {
  await getByIdOrThrow(id);
  await prisma.user.delete({ where: { id } });
};
