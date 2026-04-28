import type { Metadata } from "next";

export const metadata: Metadata = {
  title: "Privacy Policy — Keepit",
  description: "How Keepit handles (and doesn't handle) your data.",
};

const EFFECTIVE = "April 28, 2026";
const VERSION = "v1.0";

export default function Privacy() {
  return (
    <div className="doc">
      <aside className="doc__nav" aria-label="Privacy navigation">
        <div className="doc__nav-head">Privacy</div>
        <ul>
          <li><a href="#summary">Summary</a></li>
          <li><a href="#what-we-collect">What we collect</a></li>
          <li><a href="#what-we-dont">What we don&rsquo;t collect</a></li>
          <li><a href="#encryption">Encryption</a></li>
          <li><a href="#retention">Retention</a></li>
          <li><a href="#rights">Your rights</a></li>
          <li><a href="#third-parties">Third parties</a></li>
          <li><a href="#changes">Changes</a></li>
          <li><a href="#contact">Contact</a></li>
        </ul>
      </aside>

      <article className="doc__main">
        <h1>Privacy Policy</h1>
        <p className="lede">
          Keepit is built so that we cannot read your data even if we wanted to.
          This policy explains the small amount of information we do handle and how
          we handle it.
        </p>
        <p style={{ color: "var(--fg-3)" }}>
          <span className="kbd">Effective</span> &nbsp;{EFFECTIVE} &nbsp;·&nbsp;
          <span className="kbd">Version</span> &nbsp;{VERSION}
        </p>

        <h2 id="summary">1. Summary</h2>
        <ul>
          <li>Your vault items — passwords, notes, keys, files, images — are <strong>encrypted on your device</strong> with a key derived from your master password.</li>
          <li>The server stores ciphertext and minimal metadata required to operate the service. It never sees plaintext.</li>
          <li>We do not run analytics, advertising, or third-party tracking SDKs.</li>
          <li>You can delete your account, and all associated data, at any time.</li>
        </ul>

        <h2 id="what-we-collect">2. What we collect</h2>
        <p>To make sign-in and sync work, we store the following:</p>
        <ul>
          <li><strong>Account</strong>: your Google subject identifier, email, display name, and avatar URL — supplied by Google when you sign in.</li>
          <li><strong>Master verifier</strong>: an Argon2id verifier derived from your master password, plus the salt and parameters used. The password itself never leaves your device.</li>
          <li><strong>Vault items</strong>: encrypted ciphertext, an item type tag (<code>password | note | key | file | image</code>), the display title, file size and MIME type, and timestamps. Title is stored in plaintext to enable search; everything else inside the item is encrypted.</li>
          <li><strong>Sessions</strong>: a hash of your JWT&rsquo;s <code>jti</code>, your user-agent string, and an expiry — used to revoke tokens.</li>
          <li><strong>Privacy-policy acceptance</strong>: the version you accepted and the timestamp.</li>
          <li><strong>Operational logs</strong>: standard HTTP access logs (IP address, path, status code, latency) retained for up to 30 days for abuse prevention.</li>
        </ul>

        <h2 id="what-we-dont">3. What we don&rsquo;t collect</h2>
        <ul>
          <li>No analytics, no event tracking, no advertising IDs.</li>
          <li>No third-party SDKs that profile users.</li>
          <li>No plaintext of your vault contents — bodies, passwords, file contents, notes are sealed with AES-256-GCM before they ever leave the device.</li>
          <li>No location data.</li>
          <li>No contact-list, calendar, or device-inventory access.</li>
        </ul>

        <h2 id="encryption">4. Encryption details</h2>
        <p>
          Your master key is derived locally with <strong>Argon2id</strong> (memory-hard,
          OWASP-recommended). Each vault item is sealed with <strong>AES-256-GCM</strong>
          using a 96-bit IV per write and 128-bit auth tag. Per-item subkeys are derived
          via HKDF so that compromising one item&rsquo;s ciphertext does not weaken any other.
        </p>
        <p>
          See the <a href="/docs#cipher">cryptography section of the docs</a> for the full
          construction.
        </p>

        <h2 id="retention">5. Data retention</h2>
        <ul>
          <li><strong>Account &amp; vault data</strong>: kept until you delete your account.</li>
          <li><strong>Sessions</strong>: deleted on logout, or automatically after expiry.</li>
          <li><strong>Operational logs</strong>: retained at most 30 days, then purged.</li>
          <li><strong>Backups</strong>: encrypted at rest; rotated on a 30-day window.</li>
        </ul>

        <h2 id="rights">6. Your rights</h2>
        <p>
          Wherever you live, you may exercise the following rights:
        </p>
        <ul>
          <li><strong>Access</strong>: export your account data and ciphertext on request.</li>
          <li><strong>Deletion</strong>: erase your account and all associated rows from the database, plus best-effort deletion from object storage and backups within 30 days.</li>
          <li><strong>Portability</strong>: vault items are exported as JSON with the original ciphertext blobs and the parameters needed to decrypt them on another device.</li>
          <li><strong>Withdraw consent</strong>: revoke the privacy-policy acceptance, which will sign you out of all devices.</li>
        </ul>

        <h2 id="third-parties">7. Third parties</h2>
        <ul>
          <li><strong>Google Identity</strong> — used solely to verify the email address you sign in with. Google&rsquo;s policies apply to the sign-in flow.</li>
          <li><strong>Object storage (S3-compatible)</strong> — stores encrypted blobs only. The provider sees ciphertext, not your data.</li>
          <li><strong>Hosting provider</strong> — operates the API server. Sees ciphertext and the metadata listed above.</li>
        </ul>
        <p>
          We do not sell, rent, or share your data with advertisers or data brokers.
          Ever.
        </p>

        <h2 id="changes">8. Changes to this policy</h2>
        <p>
          When this policy changes, we increment the version number and prompt you to
          accept the new version on next sign-in. Material changes that broaden data
          collection are surfaced with a clear summary.
        </p>

        <h2 id="contact">9. Contact</h2>
        <p>
          Questions or requests? Open an issue at{" "}
          <a href="https://github.com/TrendySloth1001/keepit/issues" target="_blank" rel="noopener noreferrer">
            github.com/TrendySloth1001/keepit/issues
          </a>{" "}or email <code>privacy@keepit.app</code>.
        </p>
      </article>
    </div>
  );
}
