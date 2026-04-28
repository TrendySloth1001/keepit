import type { Metadata } from "next";

export const metadata: Metadata = {
  title: "Getting started — Keepit Docs",
  description: "Clone, configure, and run the Keepit backend and Flutter client.",
};

export default function GettingStarted() {
  return (
    <>
      <h1>Getting started</h1>
      <p className="lede">
        Keepit ships as two components: a Flutter client (Android-first) and a Node.js
        backend backed by PostgreSQL and S3-compatible object storage.
      </p>

      <h2>Prerequisites</h2>
      <ul>
        <li>Node <code>&gt;= 20</code></li>
        <li>PostgreSQL <code>&gt;= 14</code></li>
        <li>An S3-compatible object store (AWS S3, MinIO, Cloudflare R2, …)</li>
        <li>Flutter <code>&gt;= 3.22</code> for the client</li>
      </ul>

      <h2>Clone the repo</h2>
<pre><code>{`git clone https://github.com/TrendySloth1001/keepit.git
cd keepit`}</code></pre>

      <h2>Backend</h2>
<pre><code>{`cd backend
cp .env.example .env       # fill in DATABASE_URL, S3_*, GOOGLE_CLIENT_ID, JWT_SECRET, ...
npm install
npm run prisma:migrate     # applies schema to the database
npm run dev                # starts http://localhost:8080`}</code></pre>

      <h3>Required environment variables</h3>
      <ul>
        <li><code>DATABASE_URL</code> — Postgres connection string.</li>
        <li><code>S3_ENDPOINT</code>, <code>S3_REGION</code>, <code>S3_BUCKET</code>, <code>S3_ACCESS_KEY</code>, <code>S3_SECRET_KEY</code></li>
        <li><code>GOOGLE_CLIENT_ID</code> — used to verify Google ID tokens.</li>
        <li><code>JWT_SECRET</code> — at least 32 bytes of entropy.</li>
        <li><code>MAX_UPLOAD_BYTES</code> — per-item upload ceiling, default 64 MiB.</li>
      </ul>

      <h2>Frontend (Flutter)</h2>
<pre><code>{`cd ../frontend
flutter pub get
flutter run                # connect a device or emulator first`}</code></pre>

      <h2>Docker (optional)</h2>
      <p>The backend folder ships a <code>docker-compose.yml</code> with Postgres + MinIO for one-command local boot:</p>
<pre><code>{`docker compose up -d
npm run prisma:migrate
npm run dev`}</code></pre>

      <h2>Verify</h2>
      <p>Hit the health endpoint:</p>
<pre><code>{`curl -s http://localhost:8080/healthz
→ { "ok": true }`}</code></pre>
    </>
  );
}
