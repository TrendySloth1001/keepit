import type { NextFunction, Request, Response } from "express";

type AsyncController = (req: Request, res: Response, next: NextFunction) => Promise<void>;

export const asyncHandler = (controller: AsyncController) => {
  return (req: Request, res: Response, next: NextFunction) => {
    void controller(req, res, next).catch(next);
  };
};
