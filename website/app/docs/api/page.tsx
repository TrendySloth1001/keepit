import type { Metadata } from "next";

export const metadata: Metadata = {
  title: "API reference — Keepit Docs",
  description: "Endpoint reference for the Keepit backend.",
};

export default function Api() {
  return (
    <>
      <h1>API reference</h1>
      <p className="lede">
        All endpoints are mounted under <code>/v1</code>. Authenticated routes require
        <code> Authorization: Bearer &lt;jwt&gt; </code>and respond with
        <code>{` { success, data } `}</code>or
        <code>{` { success: false, message, code } `}</code>.
      </p>

      <h2>Vault items</h2>

      <h3>List</h3>
      <p><span className="endpoint"><span className="verb">GET</span> /v1/vault/items</span></p>
      <p><strong>Query parameters</strong>:</p>
      <ul>
        <li><code>type</code> — single type filter (<code>password|note|key|file|image</code>)</li>
        <li><code>types</code> — CSV multi-type filter, e.g. <code>types=password,note</code></li>
        <li><code>q</code> — case-insensitive title search (LIKE metacharacters escaped server-side)</li>
        <li><code>since</code>, <code>until</code> — ISO timestamps; half-open <code>[since, until)</code></li>
        <li><code>sort</code> — <code>updated_desc</code> (default) | <code>updated_asc</code> | <code>created_desc</code> | <code>created_asc</code> | <code>title_asc</code> | <code>title_desc</code></li>
        <li><code>cursor</code> — id returned previously as <code>nextCursor</code></li>
        <li><code>limit</code> — 1–100, default 50</li>
      </ul>
<pre><code>{`GET /v1/vault/items?types=password,note&q=github&sort=updated_desc&limit=20

→ 200
{
  "success": true,
  "data": {
    "items": [{
      "id": "ckxyz...",
      "type": "password",
      "title": "GitHub account",
      "cipherBlob": "<base64>",
      "cipherIv":   "<base64>",
      "fileSize":   null,
      "fileMime":   null,
      "uploadStatus": null,
      "createdAt": "2026-04-26T12:00:00.000Z",
      "updatedAt": "2026-04-26T12:00:00.000Z"
    }],
    "nextCursor": "ckxyz..." | null
  }
}`}</code></pre>

      <h3>Get one</h3>
      <p><span className="endpoint"><span className="verb">GET</span> /v1/vault/items/&#123;id&#125;</span></p>

      <h3>Create</h3>
      <p><span className="endpoint"><span className="verb">POST</span> /v1/vault/items</span></p>
      <p>For <code>password | note | key</code>. File and image use the upload protocol.</p>
<pre><code>{`POST /v1/vault/items
{
  "type":      "password",
  "title":     "GitHub account",
  "cipherBlob": "<base64 ciphertext>",
  "cipherIv":   "<base64 96-bit nonce>"
}`}</code></pre>

      <h3>Update</h3>
      <p><span className="endpoint"><span className="verb">PATCH</span> /v1/vault/items/&#123;id&#125;</span></p>
      <p>Any subset of <code>title</code>, <code>cipherBlob</code>, <code>cipherIv</code>.</p>

      <h3>Delete</h3>
      <p><span className="endpoint"><span className="verb">DELETE</span> /v1/vault/items/&#123;id&#125;</span></p>

      <h3>Batch fetch</h3>
      <p><span className="endpoint"><span className="verb">POST</span> /v1/vault/items/batch</span></p>
<pre><code>{`{ "ids": ["ckxyz...", "ckabc..."] }   // ≤ 200`}</code></pre>

      <h3>Batch delete</h3>
      <p><span className="endpoint"><span className="verb">POST</span> /v1/vault/items/batch-delete</span></p>
<pre><code>{`{ "ids": [...] }
→ 200 { success: true, data: { deleted: 2 } }`}</code></pre>

      <h2>Uploads</h2>
      <p>Upload protocol for file and image items — ciphertext only.</p>

      <h3>Initiate</h3>
      <p><span className="endpoint"><span className="verb">POST</span> /v1/vault/uploads/initiate</span></p>
<pre><code>{`{
  "type":       "file" | "image",
  "title":      "scaled_1000044174.jpg",
  "cipherBlob": "<base64>",   // header / metadata blob
  "cipherIv":   "<base64>",
  "fileSize":   319876,        // declared ciphertext length
  "fileMime":   "image/jpeg"
}
→ 201 { itemId, objectKey, chunkSize: 5242880 }`}</code></pre>

      <h3>Push chunk</h3>
      <p><span className="endpoint"><span className="verb">POST</span> /v1/vault/uploads/&#123;itemId&#125;/chunks/&#123;partNumber&#125;</span></p>
      <p><code>Content-Type: application/octet-stream</code>; idempotent on <code>(itemId, partNumber)</code>.</p>

      <h3>Push whole body</h3>
      <p><span className="endpoint"><span className="verb">POST</span> /v1/vault/uploads/&#123;itemId&#125;/content</span></p>
      <p>Single-shot for items below the chunk threshold.</p>

      <h3>Finalize</h3>
      <p><span className="endpoint"><span className="verb">POST</span> /v1/vault/uploads/finalize</span></p>
<pre><code>{`{ "itemId": "ckxyz..." }
→ 200 (item DTO with uploadStatus = "ready")`}</code></pre>

      <h3>Abort</h3>
      <p><span className="endpoint"><span className="verb">DELETE</span> /v1/vault/uploads/&#123;itemId&#125;</span></p>
      <p>Aborts the multipart upload, refunds quota, deletes the row.</p>

      <h3>Download</h3>
      <p><span className="endpoint"><span className="verb">GET</span> /v1/vault/items/&#123;id&#125;/download</span> — pre-signed URL (5 min TTL)</p>
      <p><span className="endpoint"><span className="verb">GET</span> /v1/vault/items/&#123;id&#125;/content</span> — raw ciphertext stream</p>

      <h2>Storage</h2>
      <p><span className="endpoint"><span className="verb">GET</span> /v1/vault/storage</span> — bytes used, quota, per-type breakdown.</p>
      <p><span className="endpoint"><span className="verb">GET</span> /v1/vault/storage/timeline</span></p>
      <ul>
        <li><code>bucket</code> — <code>day | week | month</code></li>
        <li><code>since</code>, <code>until</code> — ISO timestamps</li>
      </ul>
<pre><code>{`→ 200
{
  "success": true,
  "data": {
    "bucket": "day",
    "since":  "2026-03-29T00:00:00.000Z",
    "until":  "2026-04-28T00:00:00.000Z",
    "points": [
      { "t": "2026-04-12T00:00:00.000Z", "bytes": "14624321", "count": 4 }
    ]
  }
}`}</code></pre>

      <h2>Errors</h2>
      <ul>
        <li><code>400</code> — malformed input (Zod parse failure)</li>
        <li><code>401</code> — missing / invalid / revoked token</li>
        <li><code>404</code> — item not owned by caller, or upload missing</li>
        <li><code>409</code> — finalize on an already-ready item</li>
        <li><code>413</code> — upload exceeds <code>MAX_UPLOAD_BYTES</code> or remaining quota</li>
        <li><code>422</code> — declared file size differs from received bytes</li>
        <li><code>429</code> — rate-limited (per-IP and per-user buckets)</li>
        <li><code>500</code> — unhandled internal error (logged, no stack returned)</li>
      </ul>
    </>
  );
}
