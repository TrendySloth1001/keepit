import type { Metadata } from "next";
import Link from "next/link";
import { CryptoNotation } from "./CryptoNotation";

export const metadata: Metadata = {
  title: "Docs — Keepit",
  description: "Technical documentation for Keepit: cryptography, API, and algorithms.",
};

export default function DocsHome() {
  return (
    <>
      <h1>Documentation</h1>
      <p className="lede">
        Keepit is an end-to-end encrypted vault. The Android client owns all keys and ciphertext;
        the backend is an opaque store. These docs are the technical contract between them.
      </p>

      <h2>Sections</h2>
      <p>The documentation is organized into focused sections:</p>
      <ul>
        <li><Link href="/docs/getting-started"><strong>Getting started</strong></Link> — clone, install, run the backend and the Flutter client.</li>
        <li><Link href="/docs/authentication"><strong>Authentication</strong></Link> — Google ID-Token exchange, JWT issuance, session revocation.</li>
        <li><Link href="/docs/cryptography"><strong>Cryptography</strong></Link> — Argon2id, HKDF, AES-256-GCM with formal definitions.</li>
        <li><Link href="/docs/api"><strong>API reference</strong></Link> — every endpoint, every parameter, every error path.</li>
        <li><Link href="/docs/algorithms"><strong>Algorithms</strong></Link> — pagination, atomic quota reservation, resumable multipart, time-bucket aggregation, with complexity analysis.</li>
      </ul>

      <h2>Conventions</h2>
      <ul>
        <li>Endpoint signatures use <code>METHOD /path</code>.</li>
        <li>JSON shapes are shown as TypeScript types when ambiguous.</li>
        <CryptoNotation />
        <li>Complexity is reported in big-O for the dominant operation.</li>
      </ul>

      <h2>Status</h2>
      <p>
        Backend: <code>v1</code> — stable.
        Frontend: Flutter, Android-first; iOS planned.
        License: MIT.
      </p>
    </>
  );
}
