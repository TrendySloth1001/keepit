import {
  AbortMultipartUploadCommand,
  CompleteMultipartUploadCommand,
  CreateMultipartUploadCommand,
  CreateBucketCommand,
  DeleteObjectCommand,
  HeadBucketCommand,
  HeadObjectCommand,
  CompletedPart,
  S3Client,
  UploadPartCommand,
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

export async function putObjectBytes(
  key: string,
  bytes: Uint8Array,
  contentType = "application/octet-stream",
): Promise<void> {
  await internalClient.send(
    new PutObjectCommand({
      Bucket: bucket,
      Key: key,
      Body: bytes,
      ContentLength: bytes.byteLength,
      ContentType: contentType,
    }),
  );
}

export async function createMultipartUpload(
  key: string,
  contentType = "application/octet-stream",
): Promise<string> {
  const out = await internalClient.send(
    new CreateMultipartUploadCommand({
      Bucket: bucket,
      Key: key,
      ContentType: contentType,
    }),
  );

  if (!out.UploadId) {
    throw new Error("Failed to create multipart upload");
  }
  return out.UploadId;
}

export async function uploadMultipartPart(
  key: string,
  uploadId: string,
  partNumber: number,
  body: Uint8Array,
): Promise<string> {
  const out = await internalClient.send(
    new UploadPartCommand({
      Bucket: bucket,
      Key: key,
      UploadId: uploadId,
      PartNumber: partNumber,
      Body: body,
      ContentLength: body.byteLength,
    }),
  );

  if (!out.ETag) {
    throw new Error("Failed to upload multipart part");
  }
  return out.ETag;
}

export async function completeMultipartUpload(
  key: string,
  uploadId: string,
  parts: Array<{ partNumber: number; eTag: string }>,
): Promise<void> {
  const completedParts: CompletedPart[] = parts
    .sort((a, b) => a.partNumber - b.partNumber)
    .map((p) => ({ PartNumber: p.partNumber, ETag: p.eTag }));

  await internalClient.send(
    new CompleteMultipartUploadCommand({
      Bucket: bucket,
      Key: key,
      UploadId: uploadId,
      MultipartUpload: { Parts: completedParts },
    }),
  );
}

export async function abortMultipartUpload(key: string, uploadId: string): Promise<void> {
  await internalClient.send(
    new AbortMultipartUploadCommand({
      Bucket: bucket,
      Key: key,
      UploadId: uploadId,
    }),
  );
}

export async function getObjectBytes(key: string): Promise<Uint8Array | null> {
  try {
    const out = await internalClient.send(new GetObjectCommand({ Bucket: bucket, Key: key }));
    if (!out.Body) return null;

    const body = out.Body as {
      transformToByteArray?: () => Promise<Uint8Array>;
      [Symbol.asyncIterator]?: () => AsyncIterator<Uint8Array | Buffer | string>;
    };

    if (typeof body.transformToByteArray === "function") {
      return body.transformToByteArray();
    }

    if (body[Symbol.asyncIterator]) {
      const chunks: Buffer[] = [];
      for await (const chunk of body as AsyncIterable<Uint8Array | Buffer | string>) {
        chunks.push(Buffer.isBuffer(chunk) ? chunk : Buffer.from(chunk));
      }
      return new Uint8Array(Buffer.concat(chunks));
    }

    return null;
  } catch {
    return null;
  }
}

export function buildVaultObjectKey(userId: string, itemId: string): string {
  return `vault/${userId}/${itemId}`;
}
