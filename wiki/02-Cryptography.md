# Cryptography Details

## Encryption Primitives

Keepit uses industry-standard cryptographic primitives to ensure data confidentiality and integrity.

### Symmetric Encryption: AES-256-GCM

**Purpose**: Encrypt and authenticate user data

**Definition**:
$$\mathsf{Enc}_K(M) = C \| T$$

Where:
- $K$ = 256-bit encryption key
- $M$ = plaintext message
- $C$ = ciphertext
- $T$ = 128-bit authentication tag

**Properties**:
- 256-bit key space
- Authenticated encryption (confidentiality + integrity)
- Nonce requirement: unique per message
- Tag provides forgery resistance

**Implementation**: Node.js `crypto.createCipheriv()` with `aes-256-gcm`

### Key Derivation: Argon2id

**Purpose**: Derive encryption key from user password

**Definition**:
$$K = \mathsf{KDF}(P, S, t, m, p)$$

Where:
- $P$ = user password
- $S$ = random salt (16 bytes)
- $t$ = time cost (iterations)
- $m$ = memory cost (in KiB)
- $p$ = parallelism factor
- $K$ = derived key

**Parameters**:
- Time cost: 2 iterations
- Memory cost: 65536 KiB (64 MB)
- Parallelism: 4 threads
- Output: 32 bytes (256 bits)

**Properties**:
- Resistant to GPU/ASIC attacks
- Memory-hard function
- Recommended by OWASP

**Implementation**: argon2 library for Flutter

### Key Expansion: HKDF

**Purpose**: Derive multiple independent keys from master key

**Definition**:
$$\mathsf{PRK} = \mathsf{HMAC}(S, IKM)$$
$$K_i = \mathsf{HMAC}(PRK, \text{info} \| \|i)$$

Where:
- $IKM$ = input key material (master key)
- $S$ = salt
- $\text{info}$ = context string
- $K_i$ = derived key for purpose $i$

**Properties**:
- RFC 5869 compliant
- Extracts randomness (extract-then-expand)
- Domain separation for different keys

**Implementation**: Node.js `crypto.hkdf()`

## Authentication: JWT

**Purpose**: Session management and API authentication

**Structure**:
```
Header.Payload.Signature
```

**Header**:
```json
{
  "alg": "HS256",
  "typ": "JWT"
}
```

**Payload**:
```json
{
  "sub": "user_id",
  "iat": 1234567890,
  "exp": 1234571490,
  "sessionId": "session_uuid"
}
```

**Claims**:
- `sub`: User subject (Google ID)
- `iat`: Issued at timestamp
- `exp`: Expiration timestamp (1 hour)
- `sessionId`: Session identifier for revocation

## Nonce Generation

**Purpose**: Ensure unique nonces for GCM encryption

**Method**: 12-byte random nonce generated per encryption
- Stored with ciphertext: `ciphertext || nonce || tag`
- Random enough: $2^{96}$ possible values
- Collision probability: negligible

## Key Management

### Master Key Hierarchy

```
User Password
    ↓ (Argon2id)
Master Key (MK)
    ↓ (HKDF)
├─ Encryption Key (EK)
├─ HMAC Key (HK)
└─ Backup/Recovery Keys
```

### Key Storage

**Client-side**:
- Master key: Device secure enclave (flutter_secure_storage)
- Temporary keys: In-memory only
- Never written to disk

**Backend**:
- Zero keys stored
- Only processes encrypted data
- No plaintext access

## Security Assumptions

- User password has sufficient entropy (12+ characters recommended)
- Device is not compromised
- HTTPS used for all communication
- Cryptographic libraries correctly implemented
- Random number generation is cryptographically secure

## Compliance

- AES-256-GCM: NIST approved
- Argon2id: Winner of Password Hashing Competition (2015)
- HKDF: RFC 5869
- HMAC: FIPS 198-1
- TLS 1.3: Modern encryption in transit
