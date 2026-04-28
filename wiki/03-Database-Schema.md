# Database Schema

## Overview

Keepit uses PostgreSQL with Prisma ORM for data persistence. All sensitive data is stored encrypted.

## Core Tables

### Users
Stores user account information linked to Google authentication.

```prisma
model User {
  id            String      @id @default(uuid())
  googleId      String      @unique
  email         String      @unique
  name          String?
  picture       String?
  
  sessions      Session[]
  vault         Vault?
  uploadSessions UploadSession[]
  
  createdAt     DateTime    @default(now())
  updatedAt     DateTime    @updatedAt
}
```

**Purpose**: User identity and authentication
**Notes**: 
- Linked to Google via `googleId`
- One vault per user
- Can have multiple sessions (devices)

### Sessions
Tracks user sessions for authentication and revocation.

```prisma
model Session {
  id            String      @id @default(uuid())
  userId        String
  user          User        @relation(fields: [userId], references: [id])
  
  token         String      @unique
  expiresAt     DateTime
  revokedAt     DateTime?   // NULL if active
  
  deviceInfo    String?     // User agent
  ipAddress     String?
  
  createdAt     DateTime    @default(now())
  updatedAt     DateTime    @updatedAt
  
  @@index([userId])
}
```

**Purpose**: Session management and revocation
**Notes**:
- JWT stored for validation
- Expiration for security
- Revocation support for logout
- Optional device info for security audit

### Vault
Container for a user's encrypted data.

```prisma
model Vault {
  id            String      @id @default(uuid())
  userId        String      @unique
  user          User        @relation(fields: [userId], references: [id])
  
  items         VaultItem[]
  quotaUsedBytes Int        @default(0)
  quotaLimitBytes Int       @default(5_000_000_000) // 5GB
  
  createdAt     DateTime    @default(now())
  updatedAt     DateTime    @updatedAt
}
```

**Purpose**: Vault container and quota tracking
**Notes**:
- One per user
- Quota in bytes (default 5GB)
- Tracks storage usage

### VaultItem
Individual encrypted items in a vault (passwords, notes, files).

```prisma
model VaultItem {
  id            String      @id @default(uuid())
  vaultId       String
  vault         Vault       @relation(fields: [vaultId], references: [id])
  
  type          String      // "password", "note", "file", "key"
  name          String      // Encrypted
  description   String?     // Encrypted
  
  content       String      // Encrypted ciphertext
  metadata      Json        // Encrypted metadata
  
  nonce         String      // 12-byte nonce (hex encoded)
  tag           String      // Authentication tag
  
  createdAt     DateTime    @default(now())
  updatedAt     DateTime    @updatedAt
  
  @@index([vaultId])
}
```

**Purpose**: Encrypted vault items
**Notes**:
- Content fully encrypted
- Nonce stored with ciphertext (safe, doesn't compromise security)
- Authentication tag for integrity verification

### UploadSession
Manages resumable multipart file uploads.

```prisma
model UploadSession {
  id            String      @id @default(uuid())
  userId        String
  user          User        @relation(fields: [userId], references: [id])
  
  fileName      String
  totalSize     Int
  chunkSize     Int        @default(5_242_880) // 5MB
  
  uploadedBytes Int        @default(0)
  chunks        UploadChunk[]
  
  expiresAt     DateTime   // Session expires after 7 days
  status        String     @default("pending") // "pending", "completed", "failed"
  
  createdAt     DateTime    @default(now())
  updatedAt     DateTime    @updatedAt
  
  @@index([userId])
  @@index([status])
}
```

**Purpose**: Resumable upload management
**Notes**:
- Tracks upload progress
- Automatic expiration after 7 days
- Chunk-based storage

### UploadChunk
Individual chunks of a multipart upload.

```prisma
model UploadChunk {
  id                String    @id @default(uuid())
  uploadSessionId   String
  uploadSession     UploadSession @relation(fields: [uploadSessionId], references: [id])
  
  chunkNumber       Int
  content           Bytes     // Encrypted chunk data
  contentHash       String    // For integrity verification
  
  createdAt         DateTime  @default(now())
  
  @@unique([uploadSessionId, chunkNumber])
}
```

**Purpose**: Storage for individual upload chunks
**Notes**:
- Unique constraint prevents duplicate chunks
- Content hash for verification

## Indexes

Performance-critical indexes:

```prisma
// User lookups
@@index([googleId])
@@index([email])

// Session management
Session.@@index([userId])
Session.@@index([status])

// Vault queries
VaultItem.@@index([vaultId])
UploadSession.@@index([userId])
UploadSession.@@index([status])
```

## Encryption Strategy

### At-Rest Encryption
- All sensitive fields encrypted with AES-256-GCM
- Encryption key stored server-side (different from client keys)
- Backend can search encrypted data using database-level encryption

### Fields Encrypted
- `VaultItem.name`
- `VaultItem.description`
- `VaultItem.content`
- `VaultItem.metadata`
- `UploadChunk.content`

### Nonce Management
- 12-byte random nonce per encryption
- Stored with ciphertext: `ciphertext || nonce || tag`
- Ensures uniqueness even with identical plaintext

## Migrations

Migrations are version-controlled in `prisma/migrations/`:

```
prisma/migrations/
├── 20260426043709_init/
├── 20260426120000_vault_chunked_uploads/
└── 20260426132000_privacy_policy_consent/
```

**Running migrations**:
```bash
# Development
npx prisma migrate dev

# Production
npx prisma migrate deploy

# Reset (development only)
npx prisma migrate reset
```

## Scalability Considerations

### Current Design Supports:
- Millions of users
- Terabytes of encrypted data
- Thousands of concurrent uploads

### Future Optimizations:
- Database sharding by user ID
- Read replicas for queries
- Archive old sessions
- Partition upload chunks table
