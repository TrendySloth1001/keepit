import "./globals.css";
import "katex/dist/katex.min.css";
import type { Metadata } from "next";
import Nav from "@/components/Nav";
import Footer from "@/components/Footer";

export const metadata: Metadata = {
  title: "Keepit — Your private vault. On your device.",
  description:
    "Keepit is an open-source, end-to-end encrypted vault for your passwords, notes, keys and files. Built for privacy. Designed for you.",
  themeColor: "#000000",
  metadataBase: new URL("https://keepit.app"),
  openGraph: {
    title: "Keepit — Your private vault.",
    description: "Open-source, end-to-end encrypted vault for passwords, notes, keys and files.",
    type: "website",
  },
};

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="en">
      <head>
        <link rel="preconnect" href="https://fonts.googleapis.com" />
        <link rel="preconnect" href="https://fonts.gstatic.com" crossOrigin="" />
        <link
          href="https://fonts.googleapis.com/css2?family=Inter:wght@300;400;500;600;700;800&family=JetBrains+Mono:wght@400;500&display=swap"
          rel="stylesheet"
        />
      </head>
      <body>
        <div className="bg-layer" aria-hidden>
          <div className="bg-grid" />
          <div className="bg-glow" />
        </div>
        <Nav />
        <main>{children}</main>
        <Footer />
      </body>
    </html>
  );
}
