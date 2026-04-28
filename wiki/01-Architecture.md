# Architecture Overview

## System Architecture

Keepit follows a client-server architecture with end-to-end encryption at its core.

```
┌─────────────────────────────────────────────────────────┐
│              Flutter Android Client                      │
│  ┌──────────────────────────────────────────────────┐   │
│  │ • Encryption/Decryption (AES-256-GCM)           │   │
│  │ • Key Management (Argon2id, HKDF)               │   │
│  │ • Secure Storage (flutter_secure_storage)       │   │
│  │ • Google OAuth Integration                       │   │
│  └──────────────────────────────────────────────────┘   │
└─────────────────────┬──────────────────────────────────┘
                      │ HTTPS (Encrypted Data Only)
                      │
┌─────────────────────▼──────────────────────────────────┐
│              Node.js/Express Backend                    │
│  ┌──────────────────────────────────────────────────┐   │
│  │ • Authentication (JWT)                           │   │
│  │ • Vault Management (Encrypted Storage)           │   │
│  │ • Quota Management (Atomic Reservation)          │   │
│  │ • Multipart Upload Handling                      │   │
│  │ • Session Management                             │   │
│  └──────────────────────────────────────────────────┘   │
└─────────────────────┬──────────────────────────────────┘
                      │
┌─────────────────────▼──────────────────────────────────┐
│           PostgreSQL Database (Prisma ORM)             │
│  ┌──────────────────────────────────────────────────┐   │
│  │ • Encrypted Vault Data                           │   │
│  │ • User Sessions                                  │   │
│  │ • Upload Chunks                                  │   │
│  │ • Metadata (size, timestamps)                    │   │
│  └──────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────┘
```

## Key Components

### Frontend (Flutter)
- **Local-first encryption**: All sensitive data encrypted before transmission
- **Secure storage**: Credentials and keys stored in device's secure enclave
- **OAuth integration**: Google Sign-In for user authentication
- **File management**: Resumable uploads/downloads

### Backend (Node.js/Express)
- **REST API**: RESTful endpoints for vault operations
- **Zero-knowledge**: Backend cannot access plaintext data
- **Session management**: JWT-based authentication
- **Rate limiting**: Protection against abuse
- **Database**: PostgreSQL with Prisma ORM

### Database (PostgreSQL)
- **Encrypted storage**: All sensitive fields encrypted at rest
- **Migrations**: Version-controlled schema changes
- **Relationships**: Defined through Prisma schema

## Data Flow

### Encryption Flow
1. User enters data on Android client
2. Client derives encryption key from master password (Argon2id)
3. Data encrypted with AES-256-GCM
4. Only ciphertext sent to backend
5. Backend stores encrypted data

### Decryption Flow
1. Client requests encrypted data
2. Backend returns ciphertext
3. Client decrypts using locally-managed keys
4. User sees plaintext on device only

## Security Model

- **End-to-End Encryption**: Data encrypted client-side before transmission
- **Zero-Knowledge Backend**: Backend has no access to encryption keys or plaintext
- **Key Derivation**: User password → master key (Argon2id) → encryption keys (HKDF)
- **Authentication**: Google OAuth for user identity, JWT for sessions
- **Data Integrity**: AES-256-GCM provides authenticated encryption
