import Phone from "@/components/Phone";
import Reveal from "@/components/Reveal";
import { Download, GitHub, Lock, Notes, Shield } from "@/components/icons";

export default function Home() {
  return (
    <>
      {/* HERO */}
      <section className="hero" id="top">
        <Reveal className="hero__copy">
          <span className="pill">
            <span className="pill__dot" />
            Open source · End-to-end encrypted
          </span>
          <h1 className="hero__title">
            Your private vault.<br />
            <span className="hero__title-italic">On your device.</span>
          </h1>
          <p className="hero__sub">
            Keepit is a beautifully minimal vault for your passwords, notes, keys and files.
            Encrypted on-device. Yours alone. Always.
          </p>
          <div className="hero__cta">
            <a className="btn btn--solid btn--lg" href="#download">
              <Download className="ic" /> Download for Android
            </a>
            <a className="btn btn--ghost btn--lg"
               href="https://github.com/TrendySloth1001/keepit" target="_blank" rel="noopener noreferrer">
              <GitHub className="ic" /> Star on GitHub
            </a>
          </div>
          <ul className="hero__meta">
            <li><span className="dot" /> Zero telemetry</li>
            <li><span className="dot" /> Local-first</li>
            <li><span className="dot" /> MIT licensed</li>
          </ul>
        </Reveal>

        <Phone />
      </section>

      {/* MARQUEE */}
      <section className="marquee" aria-hidden>
        <div className="marquee__track">
          {[
            "End-to-end encrypted","Zero telemetry","Local-first","Open source",
            "MIT licensed","Biometric lock","End-to-end encrypted","Zero telemetry",
            "Local-first","Open source","MIT licensed","Biometric lock",
          ].map((t, i) => (
            <span key={i} style={{ display: "inline-flex", alignItems: "center", gap: 40 }}>
              {t}<span className="marquee__dot">●</span>
            </span>
          ))}
        </div>
      </section>

      {/* FEATURES */}
      <section className="features" id="features">
        <Reveal className="section-head">
          <span className="pill"><span className="pill__dot" /> Features</span>
          <h2>Built around one idea — <em>your data is yours.</em></h2>
          <p>Every detail of Keepit is shaped by privacy, simplicity, and speed.</p>
        </Reveal>

        <div className="grid">
          {[
            {
              ic: <Lock />, t: "End-to-end encryption",
              d: "AES-256-GCM encryption happens on your device. We never see your keys, your data, or even know you exist.",
            },
            {
              ic: <Shield />, t: "Biometric lock",
              d: "Face & fingerprint unlock with auto-lock policies. Decryption stays in the secure enclave.",
            },
            {
              ic: <Notes />, t: "Notes, keys & files",
              d: "One vault for everything sensitive. Rich notes, secure keys, image gallery, and arbitrary files.",
            },
            {
              ic: <Lock />, t: "Local-first sync",
              d: "Works fully offline. Optional encrypted backup keeps your data safe across devices — without the cloud knowing.",
            },
            {
              ic: <Notes />, t: "Effortless capture",
              d: "One tap to add a password, paste a note, or import a file. Smart categorization keeps the vault tidy.",
            },
            {
              ic: <GitHub />, t: "Open source",
              d: "Every line of code is auditable. MIT licensed, community-driven, no hidden funnels.",
            },
          ].map((f, i) => (
            <Reveal key={i}>
              <article className="card">
                <div className="card__ic">{f.ic}</div>
                <h3>{f.t}</h3>
                <p>{f.d}</p>
              </article>
            </Reveal>
          ))}
        </div>
      </section>

      {/* SECURITY */}
      <section className="security" id="security">
        <Reveal className="security__panel">
          <div className="security__copy">
            <span className="pill"><span className="pill__dot" /> Security</span>
            <h2>Encrypted before it ever leaves your hands.</h2>
            <p>
              Keepit derives your master key locally with Argon2id. Items are sealed with AES-256-GCM.
              The server, if used, only sees opaque ciphertext.
            </p>
            <ul className="bullets">
              <li><span className="check">✓</span>Argon2id KDF, parameter-tuned per device</li>
              <li><span className="check">✓</span>AES-256-GCM authenticated encryption</li>
              <li><span className="check">✓</span>Hardware-backed keystore on Android</li>
              <li><span className="check">✓</span>No analytics. No trackers. Ever.</li>
            </ul>
          </div>

          <div className="security__diagram" aria-hidden>
            <div className="ring ring--1" />
            <div className="ring ring--2" />
            <div className="ring ring--3" />
            <div className="lock"><Lock /></div>
          </div>
        </Reveal>
      </section>

      {/* OPEN */}
      <section className="open" id="open">
        <Reveal className="open__inner">
          <span className="pill"><span className="pill__dot" /> Open source</span>
          <h2>Read the code. Star the repo. Make it better.</h2>
          <p>Keepit is built in the open. Issues, PRs and ideas are welcome.</p>
          <a className="btn btn--solid btn--lg"
             href="https://github.com/TrendySloth1001/keepit" target="_blank" rel="noopener noreferrer">
            <GitHub className="ic" /> Star on GitHub
          </a>
        </Reveal>
      </section>

      {/* DOWNLOAD */}
      <section className="download" id="download">
        <Reveal>
          <h2>Get Keepit</h2>
          <p>Available for Android. iOS coming soon.</p>
          <div className="download__row">
            <a className="btn btn--solid btn--lg"
               href="https://github.com/TrendySloth1001/keepit/releases" target="_blank" rel="noopener noreferrer">
              Download .apk
            </a>
            <a className="btn btn--ghost btn--lg"
               href="https://github.com/TrendySloth1001/keepit" target="_blank" rel="noopener noreferrer">
              View source
            </a>
          </div>
        </Reveal>
      </section>
    </>
  );
}
