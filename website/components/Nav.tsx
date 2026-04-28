"use client";
import Link from "next/link";
import { usePathname } from "next/navigation";
import { useEffect, useState } from "react";
import { GitHub } from "./icons";

export default function Nav() {
  const [detached, setDetached] = useState(false);
  const path = usePathname();

  useEffect(() => {
    const SCROLL_THRESHOLD = 24;
    let raf: number | null = null;
    const update = () => {
      const y = window.scrollY || document.documentElement.scrollTop;
      setDetached(y > SCROLL_THRESHOLD);
    };
    const onScroll = () => {
      if (raf !== null) return;
      raf = requestAnimationFrame(() => { update(); raf = null; });
    };
    update();
    window.addEventListener("scroll", onScroll, { passive: true });
    return () => window.removeEventListener("scroll", onScroll);
  }, []);

  const isActive = (href: string) =>
    href === "/" ? path === "/" : path?.startsWith(href);

  return (
    <header className={`nav ${detached ? "nav--detached" : "nav--attached"}`}>
      <div className="nav__inner">
        <Link className="nav__brand" href="/" aria-label="Keepit home">
          <span className="nav__mark"><span className="nav__mark-dot" /></span>
          <span className="nav__name">keepit</span>
        </Link>

        <nav className="nav__links" aria-label="Primary">
          <Link href="/" aria-current={isActive("/") && path === "/" ? "page" : undefined}>Home</Link>
          <Link href="/docs" aria-current={isActive("/docs") ? "page" : undefined}>Docs</Link>
          <Link href="/privacy" aria-current={isActive("/privacy") ? "page" : undefined}>Privacy</Link>
          <Link href="/#features">Features</Link>
        </nav>

        <div className="nav__actions">
          <a className="btn btn--ghost btn--sm"
             href="https://github.com/TrendySloth1001/keepit"
             target="_blank" rel="noopener noreferrer">
            <GitHub className="ic" />
            <span>Star on GitHub</span>
          </a>
          <a className="btn btn--solid btn--sm" href="/#download">Download</a>
        </div>
      </div>
    </header>
  );
}
