import * as React from "react";

type P = React.SVGProps<SVGSVGElement>;
const s = (props: P) => ({
  viewBox: "0 0 24 24",
  fill: "none",
  stroke: "currentColor",
  strokeWidth: 1.7,
  strokeLinecap: "round" as const,
  strokeLinejoin: "round" as const,
  ...props,
});

export const GitHub = (p: P) => (
  <svg viewBox="0 0 24 24" {...p}>
    <path
      fill="currentColor"
      d="M12 .5C5.65.5.5 5.65.5 12c0 5.08 3.29 9.39 7.86 10.91.58.1.79-.25.79-.56v-2c-3.2.7-3.87-1.36-3.87-1.36-.52-1.32-1.27-1.67-1.27-1.67-1.04-.71.08-.7.08-.7 1.15.08 1.76 1.18 1.76 1.18 1.02 1.75 2.68 1.24 3.34.95.1-.74.4-1.24.72-1.53-2.55-.29-5.24-1.28-5.24-5.69 0-1.26.45-2.29 1.18-3.1-.12-.29-.51-1.46.11-3.04 0 0 .97-.31 3.18 1.18a11.05 11.05 0 0 1 5.79 0c2.21-1.49 3.18-1.18 3.18-1.18.62 1.58.23 2.75.11 3.04.74.81 1.18 1.84 1.18 3.1 0 4.42-2.7 5.39-5.27 5.68.41.35.78 1.04.78 2.1v3.11c0 .31.21.66.8.55C20.71 21.39 24 17.08 24 12 24 5.65 18.85.5 12 .5Z"
    />
  </svg>
);

export const Lock = (p: P) => (
  <svg {...s(p)}><rect x="5" y="11" width="14" height="9" rx="2"/><path d="M8 11V8a4 4 0 0 1 8 0v3"/></svg>
);
export const Settings = (p: P) => (
  <svg {...s(p)}><circle cx="12" cy="12" r="3"/><path d="M19.4 15a1.7 1.7 0 0 0 .34 1.87l.06.06a2 2 0 1 1-2.83 2.83l-.06-.06A1.7 1.7 0 0 0 15 19.4a1.7 1.7 0 0 0-1 1.55V21a2 2 0 1 1-4 0v-.1A1.7 1.7 0 0 0 9 19.4a1.7 1.7 0 0 0-1.87.34l-.06.06A2 2 0 1 1 4.24 16.97l.06-.06A1.7 1.7 0 0 0 4.6 15a1.7 1.7 0 0 0-1.55-1H3a2 2 0 1 1 0-4h.1A1.7 1.7 0 0 0 4.6 9a1.7 1.7 0 0 0-.34-1.87l-.06-.06A2 2 0 1 1 7.03 4.24l.06.06A1.7 1.7 0 0 0 9 4.6a1.7 1.7 0 0 0 1-1.55V3a2 2 0 1 1 4 0v.1A1.7 1.7 0 0 0 15 4.6a1.7 1.7 0 0 0 1.87-.34l.06-.06a2 2 0 1 1 2.83 2.83l-.06.06A1.7 1.7 0 0 0 19.4 9c.16.4.5.71 1 .85"/></svg>
);
export const Search = (p: P) => (
  <svg {...s(p)} strokeWidth={1.8}><circle cx="11" cy="11" r="7"/><path d="m20 20-3.5-3.5"/></svg>
);
export const Chev = (p: P) => (<svg {...s(p)}><path d="m9 6 6 6-6 6"/></svg>);
export const Plus = (p: P) => (<svg {...s(p)} strokeWidth={2.2}><path d="M12 5v14M5 12h14"/></svg>);
export const Notes = (p: P) => (<svg {...s(p)}><path d="M5 7h10M5 12h14M5 17h8"/></svg>);
export const Image = (p: P) => (
  <svg {...s(p)}><rect x="3" y="5" width="18" height="14" rx="2"/><circle cx="9" cy="11" r="1.5"/><path d="m4 18 5-5 4 4 3-3 4 4"/></svg>
);
export const Paperclip = (p: P) => (
  <svg {...s(p)}><path d="M21 11.5 12.5 20a5 5 0 0 1-7-7L14 4.5a3.5 3.5 0 0 1 5 5L10.5 18a2 2 0 0 1-3-3L15 7.5"/></svg>
);
export const Key = (p: P) => (
  <svg {...s(p)} strokeWidth={2}><circle cx="8" cy="14" r="4"/><path d="m11 11 9-9m-3 3 2 2m-4 0 2 2"/></svg>
);
export const Grid = (p: P) => (
  <svg {...s(p)} strokeWidth={2}><path d="M4 6h.01M10 6h.01M16 6h.01M4 12h.01M10 12h.01M16 12h.01M4 18h.01M10 18h.01M16 18h.01"/></svg>
);
export const Shield = (p: P) => (
  <svg {...s(p)}><path d="M12 2 4 6v6c0 5 3.5 9 8 10 4.5-1 8-5 8-10V6l-8-4Z"/></svg>
);
export const Download = (p: P) => (
  <svg {...s(p)} strokeWidth={2}><path d="M12 3v12m0 0 4-4m-4 4-4-4M5 21h14"/></svg>
);
