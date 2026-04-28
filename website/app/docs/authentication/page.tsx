import type { Metadata } from "next";

export const metadata: Metadata = {
  title: "Authentication — Keepit Docs",
  description: "Google ID-Token exchange, JWT issuance, and session revocation.",
};

export default function Auth() {
  return (
    <>
      <h1>Authentication</h1>
      <p className="lede">
        Sign-in is delegated to Google. The server verifies the ID token, provisions a
        <code> User </code> record on first login, then mints a short-lived JWT bound to a
        revocable server-side <code>Session</code>.
      </p>

      <h2>Sign-in flow</h2>
      <ol>
        <li>The Android client retrieves a Google ID Token via Google Sign-In.</li>
        <li>Client posts the token to <code>POST /v1/auth/google</code>.</li>
        <li>Server verifies the token using <code>google-auth-library</code> against the configured <code>GOOGLE_CLIENT_ID</code>.</li>
        <li>Server upserts the <code>User</code> by <code>googleSub</code>.</li>
        <li>Server creates a <code>Session</code> row with <code>jtiHash = SHA-256(jti)</code> and returns a JWT.</li>
        <li>Subsequent requests send <code>Authorization: Bearer &lt;jwt&gt;</code>.</li>
      </ol>

      <h2>Endpoint</h2>
<pre><code>{`POST /v1/auth/google
Content-Type: application/json

{ "idToken": "<google-id-token>" }

→ 200
{
  "success": true,
  "data": {
    "token": "<jwt>",
    "expiresAt": "2026-05-05T18:00:00Z",
    "user": { "id": "...", "email": "...", "name": "...", "avatarUrl": "..." }
  }
}`}</code></pre>

      <h2>JWT payload</h2>
<pre><code>{`{
  "sub": "<userId>",
  "jti": "<random uuid>",
  "iat": 1714323600,
  "exp": 1714928400
}`}</code></pre>
      <p>
        The server only stores <code>SHA-256(jti)</code> in the <code>Session</code> table.
        On each authenticated request, the middleware:
      </p>
      <ol>
        <li>Verifies the JWT signature and expiry.</li>
        <li>Looks up the <code>Session</code> by <code>jtiHash</code>.</li>
        <li>Rejects if missing, expired, or revoked.</li>
      </ol>

      <h2>Logout / revocation</h2>
      <p>
        <code>POST /v1/auth/logout</code> deletes the <code>Session</code> row matching the caller&rsquo;s <code>jti</code>.
        After deletion, the JWT is permanently invalidated even if it has not yet expired.
      </p>

      <h2>Master-password registration</h2>
      <p>
        On first sign-in, the client establishes a master password and submits an
        Argon2id verifier. See <a href="/docs/cryptography">Cryptography</a> for the exact
        construction. This step is local-only as far as plaintext is concerned — the password
        never leaves the device.
      </p>
    </>
  );
}
