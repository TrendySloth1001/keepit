# Keepit

**An open-source, end-to-end encrypted vault for your passwords, notes, keys, and files.**

## What is Keepit?

Keepit is a private vault application designed with security and privacy at its core. Your Android device owns all encryption keys and ciphertext—the backend is merely an opaque store with no ability to access your data. Every piece of information is encrypted locally before ever leaving your device.

## Why Keepit?

Existing password managers and vaults often require you to trust a third party with your sensitive data. Keepit eliminates that trust requirement:

- **End-to-End Encryption**: All data is encrypted on your device before reaching our servers
- **Zero-Knowledge Architecture**: The backend has no access to plaintext data or encryption keys
- **Open Source**: Fully transparent codebase that can be audited and self-hosted
- **Built for Privacy**: Privacy-first design decisions throughout the application

## For Whom?

Keepit is for anyone who wants to:
- Securely store passwords and credentials
- Keep sensitive notes and documents private
- Manage cryptographic keys safely
- Control their own data without relying on third-party trust
- Understand exactly how their security works (through open-source code)

## Project Structure

- **`backend/`** - Node.js/Express REST API with Prisma ORM for encrypted data storage
- **`frontend/`** - Flutter application for Android (iOS planned) with local encryption
- **`website/`** - Next.js documentation and landing page

## Key Features

- **Atomic Quota Reservation** - Efficient quota management for vault storage
- **Resumable Multipart Uploads** - Upload large files reliably
- **Formal Cryptography Definitions** - Using industry-standard primitives:
  - Argon2id for key derivation
  - HKDF for key derivation functions
  - AES-256-GCM for authenticated encryption
- **Session Management** - Google ID Token authentication with JWT issuance and revocation
- **Time-Bucket Aggregation** - Efficient data organization and retrieval

## Getting Started

See the [documentation](website/README.md) for detailed setup instructions to:
- Clone and install dependencies
- Run the backend server
- Build and run the Flutter client
- Access API reference and cryptography details

## License

MIT

## Status

- **Backend**: v1 — Stable
- **Frontend**: Flutter, Android-first; iOS planned
- **License**: MIT
