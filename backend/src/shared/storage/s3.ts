import {
  CreateBucketCommand,
  DeleteObjectCommand,
  HeadBucketCommand,
  HeadObjectCommand,
  S3Client,
} from "@aws-sdk/client-s3";
import { getSignedUrl } from "@aws-sdk/s3-request-presigner";
import { GetObjectCommand, PutObjectCommand } from "@aws-sdk/client-s3";
import { env } from "../../constants/env";

const internalClient = new S3Client({
  endpoint: env.MINIO_ENDPOINT,
  region: env.MINIO_REGION,
  forcePathStyle: true,
  credentials: {
    accessKeyId: env.MINIO_ACCESS_KEY,
    secretAccessKey: env.MINIO_SECRET_KEY,
  },
});

const publicClient = env.MINIO_PUBLIC_ENDPOINT && env.MINIO_PUBLIC_ENDPOINT !== env.MINIO_ENDPOINT
  ? new S3Client({
      endpoint: env.MINIO_PUBLIC_ENDPOINT,
      region: env.MINIO_REGION,
      forcePathStyle: true,
      credentials: {
        accessKeyId: env.MINIO_ACCESS_KEY,
        secretAccessKey: env.MINIO_SECRET_KEY,
      },
    })
  : internalClient;

export const s3 = internalClient;
export const bucket = env.MINIO_BUCKET;

export async function ensureBucket(): Promise<void> {
  try {
    await internalClient.send(new HeadBucketCommand({ Bucket: bucket }));
  } catch {
    await internalClient.send(new CreateBucketCommand({ Bucket: bucket }));
  }
}

export async function presignPutUrl(
  key: string,
  contentLength: number,
  contentType: string,
  ttlSeconds = 300,
): Promise<string> {
  const cmd = new PutObjectCommand({
    Bucket: bucket,
    Key: key,
    ContentLength: contentLength,
    ContentType: contentType,
  });
  return getSignedUrl(publicClient, cmd, { expiresIn: ttlSeconds });
}

export async function presignGetUrl(key: string, ttlSeconds = 300): Promise<string> {
  const cmd = new GetObjectCommand({ Bucket: bucket, Key: key });
  return getSignedUrl(publicClient, cmd, { expiresIn: ttlSeconds });
}

export async function statObject(key: string): Promise<{ size: number } | null> {
  try {
    const head = await internalClient.send(new HeadObjectCommand({ Bucket: bucket, Key: key }));
    return { size: Number(head.ContentLength ?? 0) };
  } catch {
    return null;
  }
}

export async function deleteObject(key: string): Promise<void> {
  await internalClient.send(new DeleteObjectCommand({ Bucket: bucket, Key: key }));
}

export function buildVaultObjectKey(userId: string, itemId: string): string {
  return `vault/${userId}/${itemId}`;
}
