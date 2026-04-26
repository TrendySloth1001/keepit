import "dotenv/config";
import { app } from "./app";
import { env } from "./constants/env";
import { ensureBucket } from "./shared/storage/s3";

async function start() {
  await ensureBucket();
  app.listen(env.PORT, () => {
    console.log(`Server running on http://localhost:${env.PORT}`);
  });
}

start().catch((err) => {
  console.error("Failed to start server", err);
  process.exit(1);
});
