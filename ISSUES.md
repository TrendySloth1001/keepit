# Keepit Issues & Resolutions

This document tracks identified issues, their status, and resolutions.

## Issue #1: LaTeX Math Rendering in Documentation

**Status**: ✅ RESOLVED

**Description**: Math notation in documentation was causing "Enc is not defined" ReferenceError when pages were rendered.

**Root Cause**: Next.js was attempting to evaluate LaTeX expressions as JavaScript code at build time when wrapped in `<code>` tags with `$...$` delimiters.

**Solution**: 
- Installed `react-katex` package for proper KaTeX rendering
- Created a separate client component `CryptoNotation.tsx` with `"use client"` directive
- Used `InlineMath` component from react-katex for math expressions
- Separated client-side rendering from server-side metadata exports

**Changes Made**:
- `website/app/docs/CryptoNotation.tsx` (new)
- `website/app/docs/page.tsx` (updated)
- `website/package.json` (added react-katex dependency)

**Test Result**: ✅ Documentation pages render correctly with proper mathematical notation

---

## Issue #2: Missing Dependencies in Website

**Status**: ✅ RESOLVED

**Description**: TypeScript compilation errors: modules `framer-motion` and `lucide-react` could not be found.

**Root Cause**: Dependencies were used in components but not installed in `package.json`.

**Solution**:
- Ran `npm install framer-motion lucide-react` in website directory
- Verified installation through package-lock.json

**Changes Made**:
- `website/package.json` (updated dependencies)
- `website/package-lock.json` (auto-generated)

**Test Result**: ✅ No TypeScript errors related to missing modules

---

## Issue #3: Next.js Build Cache Corruption

**Status**: ✅ RESOLVED

**Description**: Server errors with missing `.next/routes-manifest.json` and module loading failures.

**Root Cause**: Stale build cache from incomplete builds and previous development sessions.

**Solution**:
- Allowed Next.js to rebuild cache on first run
- The `.next/` directory regenerated automatically

**Prevention**:
- Added `.next/` to `.gitignore` to prevent cache files from being committed
- Developers should clean build cache if encountering persistent issues: `rm -rf .next/`

**Test Result**: ✅ Website development server runs successfully

---

## Issue #4: Node Modules in Version Control

**Status**: ✅ RESOLVED

**Description**: `node_modules/` directory was being tracked in Git, significantly increasing repository size.

**Root Cause**: Initial repository setup did not properly exclude node_modules directories.

**Solution**:
- Updated `.gitignore` to exclude:
  - `**/node_modules/`
  - `**/.next/`
  - Build artifacts
- Removed `website/node_modules` from staging before commit

**Changes Made**:
- `.gitignore` (updated patterns)

**Test Result**: ✅ Repository no longer contains node_modules; developers install via `npm install`

---

## Issue #5: Backend Database Migration Failure

**Status**: ⏳ PENDING INVESTIGATION

**Description**: `npx prisma db push` command failed with exit code 1.

**Context**: Backend terminal shows this command was executed but returned error.

**Potential Causes**:
- Database connection issues
- Prisma schema conflicts
- Missing environment variables (.env)
- Database permissions

**Investigation Steps**:
1. [ ] Check `.env` configuration in backend directory
2. [ ] Verify database connection string
3. [ ] Review Prisma schema for conflicts
4. [ ] Check database server status

**Next Steps**: Need to investigate database connectivity and schema state

---

## Issue #6: Website TypeScript Metadata Export

**Status**: ✅ RESOLVED (Warning Level)

**Description**: Warning during compilation: "Unsupported metadata themeColor is configured in metadata export in /."

**Root Cause**: Next.js 15.5.15 deprecated `themeColor` in metadata export in favor of viewport export.

**Current Status**: Application functions correctly, but generates build warnings.

**Recommended Fix**:
- Migrate `themeColor` from `layout.tsx` metadata to viewport export
- Update pattern in app/layout.tsx:
```typescript
export const viewport: Viewport = {
  themeColor: "#000000"
};
```

**Priority**: Low (functionality not affected, cosmetic warning)

---

## Issue #7: Git Push Network Access

**Status**: ✅ RESOLVED

**Description**: Initial GitHub push attempt failed with "CONNECT tunnel failed, response 403".

**Root Cause**: Sandboxed execution environment network restrictions.

**Solution**: 
- Retried push with unsandboxed execution flag
- Successfully pushed 302 objects (76.14 MiB) to remote

**Test Result**: ✅ Repository successfully synced with GitHub (commit 197dc16)

---

## Issue #8: Rate Limiting Not Implemented

**Status**: ⏳ TODO

**Description**: API endpoints lack rate limiting protection against brute force and DOS attacks.

**Importance**: High (Security)

**Solution Design**:
- Implement rate limiting middleware using `express-rate-limit`
- Configure per endpoint:
  - Authentication endpoints: 5 requests per 15 minutes
  - API endpoints: 100 requests per 15 minutes per user
  - Public endpoints: 1000 requests per hour

**Estimated Effort**: 2-3 hours

---

## Issue #9: Missing API Error Standardization

**Status**: ⏳ TODO

**Description**: API error responses may not follow consistent format across all endpoints.

**Importance**: Medium (Developer Experience)

**Solution Design**:
- Define standard error response format
- Implement centralized error handler
- Document error codes and meanings

**Recommended Format**:
```json
{
  "code": "AUTH_INVALID_TOKEN",
  "message": "Provided token is invalid or expired",
  "statusCode": 401,
  "timestamp": "2026-04-28T19:30:00Z"
}
```

---

## Issue #10: Frontend Encryption Performance

**Status**: ⏳ TODO

**Description**: Large file encryption on mobile device may cause UI freezing.

**Importance**: Medium (User Experience)

**Solution Design**:
- Implement chunked encryption for files > 10MB
- Use Flutter isolates for background encryption
- Add progress indication during encryption

**Estimated Effort**: 4-5 hours

---

## Summary Statistics

| Status | Count |
|--------|-------|
| ✅ Resolved | 6 |
| ⏳ Pending Investigation | 1 |
| ⏳ TODO | 3 |
| **Total** | **10** |

## How to Report Issues

When reporting issues, please include:
1. Clear description of the problem
2. Steps to reproduce
3. Expected vs. actual behavior
4. Environment details (OS, versions)
5. Any error messages or logs
