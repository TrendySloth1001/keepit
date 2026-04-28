import Link from "next/link";

export default function Footer() {
  return (
    <footer className="foot">
      <div className="foot__inner">
        <div className="foot__brand">
          <span className="nav__mark"><span className="nav__mark-dot" /></span>
          <span>keepit</span>
        </div>
        <div className="foot__cols">
          <Link href="/">Home</Link>
          <Link href="/docs">Docs</Link>
          <Link href="/privacy">Privacy</Link>
          <a href="https://github.com/TrendySloth1001/keepit" target="_blank" rel="noopener noreferrer">GitHub</a>
        </div>
        <div className="foot__copy">© 2026 Keepit · MIT licensed</div>
      </div>
    </footer>
  );
}
