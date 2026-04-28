import type { Metadata } from "next";
import Math from "@/components/docs/Math";

export const metadata: Metadata = {
  title: "Cryptography — Keepit Docs",
  description: "Argon2id KDF, HKDF subkey derivation, AES-256-GCM authenticated encryption.",
};

export default function Crypto() {
  return (
    <>
      <h1>Cryptography</h1>
      <p className="lede">
        Keepit&rsquo;s security model rests on three primitives: a memory-hard password KDF
        (Argon2id), a key-separation KDF (HKDF), and an authenticated cipher (AES-256-GCM).
        This page defines them precisely.
      </p>

      <h2>Notation</h2>
      <ul>
        <li><Math tex={String.raw`\|`} /> — byte concatenation</li>
        <li><Math tex={String.raw`\{0,1\}^n`} /> — the set of <Math tex="n" />-bit strings</li>
        <li><Math tex={String.raw`P \xleftarrow{\$} S`} /> — sample <Math tex="P" /> uniformly from <Math tex="S" /></li>
        <li><Math tex={String.raw`\mathsf{Enc}_K(N, A, M)`} /> — AEAD encryption with key <Math tex="K" />, nonce <Math tex="N" />, associated data <Math tex="A" />, message <Math tex="M" /></li>
      </ul>

      <h2>Master key derivation — Argon2id</h2>
      <p>
        The master key <Math tex="K_m" /> is derived on-device from the user&rsquo;s
        password <Math tex="\pi" /> with a per-user random salt
        <Math tex={String.raw`\;s \xleftarrow{\$} \{0,1\}^{128}`} />:
      </p>
      <Math display tex={String.raw`
        K_m \;=\; \mathrm{Argon2id}\bigl(\pi,\; s;\; m,\; t,\; p\bigr)
        \quad\text{with}\quad K_m \in \{0,1\}^{256}
      `} />
      <p>Default parameters (auto-tuned upward on capable devices):</p>
      <Math display tex={String.raw`
        m = 64\,\text{MiB},\quad t = 3,\quad p = 1
      `} />
      <p>
        Memory-hardness gives an attacker&rsquo;s expected work for a single guess approximately:
      </p>
      <Math display tex={String.raw`
        W(\pi) \;\approx\; m \cdot t \cdot \tau_{\text{mem}}
      `} />
      <p>
        where <Math tex={String.raw`\tau_{\text{mem}}`} /> is the per-byte cost of the
        memory-hard pass. Doubling <Math tex="m" /> doubles attacker cost while client
        cost grows the same way; the exponent on the user&rsquo;s side is
        <em> linear </em>but the asymmetry against ASIC/GPU farms is dramatic.
      </p>

      <h3>Verifier</h3>
      <p>
        The server stores <Math tex={String.raw`V = \mathrm{Argon2id}(\pi, s; m, t, p)`} />
        and the parameters <Math tex="(s, m, t, p)" /> in <code>User.masterSalt</code> /
        <code>User.masterParams</code>. On login, the client recomputes
        <Math tex="V" /> and submits it; the server compares constant-time.
      </p>

      <h2>Per-item subkeys — HKDF</h2>
      <p>
        For each item with id <Math tex="i" />, a subkey <Math tex="K_i" /> is derived from
        <Math tex="\;K_m" /> using HKDF-SHA-256:
      </p>
      <Math display tex={String.raw`
        K_i \;=\; \mathrm{HKDF}\bigl(K_m,\; \mathsf{salt} = \varepsilon,\;
        \mathsf{info} = \texttt{"keepit-item:"} \,\|\, i,\; L = 32\bigr)
      `} />
      <p>
        This guarantees independent keys for independent items. Compromise of any single
        ciphertext yields no information about other items&rsquo; keys, and the
        <em> info </em>parameter binds the subkey to its item id, making swap attacks impossible.
      </p>

      <h2>Authenticated encryption — AES-256-GCM</h2>
      <p>
        Each plaintext payload <Math tex="M" /> (e.g. the JSON body of a note) is sealed under
        <Math tex={String.raw`\;K_i`} /> with a fresh nonce
        <Math tex={String.raw`\;N \xleftarrow{\$} \{0,1\}^{96}`} />:
      </p>
      <Math display tex={String.raw`
        C \,\|\, T \;=\; \mathrm{AES\text{-}GCM}_{K_i}\bigl(N,\; A,\; M\bigr)
      `} />
      <p>where the associated data is</p>
      <Math display tex={String.raw`
        A \;=\; \mathsf{userId} \,\|\, \mathsf{itemId} \,\|\, \mathsf{type}
      `} />
      <p>
        The 128-bit tag <Math tex="T" /> is appended to <Math tex="C" /> in
        <code> VaultItem.cipherBlob</code>, the nonce in <code>VaultItem.cipherIv</code>.
        Tampering with any byte — header, body, or moving ciphertext between items —
        causes decryption to fail.
      </p>

      <h3>Nonce safety</h3>
      <p>
        GCM is catastrophic under nonce reuse. Keepit uses a per-write random 96-bit nonce.
        The collision probability after <Math tex="q" /> writes by the same key is bounded by
        the birthday formula:
      </p>
      <Math display tex={String.raw`
        \Pr[\text{collision}] \;\le\; \frac{q(q-1)}{2 \cdot 2^{96}}
      `} />
      <p>
        For <Math tex="q = 2^{32}" /> writes per key (4 billion), this is at most
        <Math tex={String.raw`\;2^{-33}`} />, well below cryptographic concern. Per-item
        subkeys further isolate the budget.
      </p>

      <h2>Decryption</h2>
      <p>The client recovers <Math tex="M" /> as:</p>
      <Math display tex={String.raw`
        M \;=\; \mathrm{AES\text{-}GCM\text{-}Dec}_{K_i}\bigl(N,\; A,\; C\,\|\,T\bigr)
      `} />
      <p>
        which returns <Math tex={String.raw`\bot`} /> on tag failure. The client treats
        <Math tex={String.raw`\;\bot`} /> as a hard error and never falls back to silently
        accepting plaintext.
      </p>

      <h2>Key lifetime</h2>
      <ul>
        <li><Math tex="K_m" /> is held in memory only while the app is unlocked.</li>
        <li>The Android keystore wraps an in-memory copy with a hardware-backed key.</li>
        <li>Auto-lock zeros <Math tex="K_m" /> after a configurable idle period.</li>
        <li>Subkeys <Math tex="K_i" /> are recomputed on demand and never persisted.</li>
      </ul>

      <h2>Threat model</h2>
      <ul>
        <li><strong>Server compromise</strong>: attacker reads ciphertext only. Confidentiality and integrity hold under standard AES-GCM assumptions.</li>
        <li><strong>Network MITM</strong>: TLS plus ciphertext-only payloads.</li>
        <li><strong>Lost device</strong>: vault is gated behind biometrics + master password Argon2id verifier.</li>
        <li><strong>Out of scope</strong>: rooted device with active malware in the same UID; physical attacker with an unlocked screen.</li>
      </ul>
    </>
  );
}
