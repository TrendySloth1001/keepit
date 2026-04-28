"use client";
import Link from "next/link";
import { usePathname } from "next/navigation";

const SECTIONS: { head: string; links: { href: string; label: string }[] }[] = [
  {
    head: "Get started",
    links: [
      { href: "/docs", label: "Overview" },
      { href: "/docs/getting-started", label: "Install & run" },
      { href: "/docs/authentication", label: "Authentication" },
    ],
  },
  {
    head: "Cryptography",
    links: [{ href: "/docs/cryptography", label: "KDF, AES-GCM, HKDF" }],
  },
  {
    head: "Backend API",
    links: [{ href: "/docs/api", label: "Endpoints reference" }],
  },
  {
    head: "Algorithms",
    links: [{ href: "/docs/algorithms", label: "Pagination · Quota · Multipart" }],
  },
];

export default function DocsLayout({ children }: { children: React.ReactNode }) {
  const path = usePathname() ?? "";
  return (
    <div className="doc">
      <aside className="doc__nav" aria-label="Docs navigation">
        {SECTIONS.map((sec) => (
          <div key={sec.head}>
            <div className="doc__nav-head">{sec.head}</div>
            <ul>
              {sec.links.map((l) => {
                const active = path === l.href;
                return (
                  <li key={l.href}>
                    <Link href={l.href} aria-current={active ? "page" : undefined}
                      style={active ? { color: "#fff", background: "var(--surface-2)" } : undefined}>
                      {l.label}
                    </Link>
                  </li>
                );
              })}
            </ul>
          </div>
        ))}
      </aside>
      <article className="doc__main">{children}</article>
    </div>
  );
}
