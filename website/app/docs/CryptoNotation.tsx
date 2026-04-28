"use client";

import { InlineMath } from "react-katex";

export function CryptoNotation() {
  return (
    <li>
      Cryptographic primitives are written in standard notation. We use
      <InlineMath math="\\mathsf{Enc}_K(M)" /> for authenticated encryption,
      <InlineMath math="\\mathsf{KDF}(\\cdot)" /> for key-derivation, and
      <InlineMath math="\\|" /> for byte concatenation.
    </li>
  );
}