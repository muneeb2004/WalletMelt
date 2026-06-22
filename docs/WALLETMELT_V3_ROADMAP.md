# WalletMelt V3 — Cloud Platform Transformation Roadmap

## Vision

Transform WalletMelt from a local-first personal expense tracker into a full financial management platform supporting Android, iOS, Web, and Desktop with cloud sync, multi-device access, household collaboration, receipt intelligence, financial insights, and subscription monetization. Architecture must remain capable of operating offline while introducing a scalable cloud backend.

---

## Monorepo Structure

Before any code is written, establish the repository structure. NestJS and Next.js are both TypeScript — they can share type definitions and validation schemas in a Turborepo monorepo. Flutter (Dart) is a separate language and cannot share TypeScript types; it maintains its own model classes that mirror the API DTOs.

```
walletmelt/
  apps/
    api/           # NestJS backend
    web/           # Next.js 15 web app
    mobile/        # Flutter (separate — Dart cannot import TypeScript packages)
  packages/
    types/         # Shared TypeScript interfaces (API response shapes, enums)
    validators/    # Shared Zod schemas (request validation reused on both client and server)
  turbo.json
  package.json
```

`packages/types` contains DTOs exported from NestJS and imported in Next.js. Any change to an API response shape produces a type error in the web app at compile time. This eliminates an entire category of integration bugs.

---

## Phase 0 — Architecture, DevOps Foundation, and Security Baseline

This phase produces running infrastructure, not a design document. Every subsequent phase inherits from it. Nothing in Phases 1–13 is built before Phase 0 is complete.

### 0.1 Backend Architecture: Monolith First

Start with a NestJS monolith structured as domain modules (AuthModule, SyncModule, ReceiptModule, HouseholdModule, InsightsModule, NotificationsModule, BillingModule). Modules are bounded by interface contracts from day one so they can be extracted into services later if warranted. Microservices introduce distributed systems complexity that is unwarranted below 100k MAU.

### 0.2 Backend Stack

- **Framework**: NestJS (TypeScript)
- **ORM**: Prisma with migration files committed to version control
- **API documentation**: Swagger/OpenAPI auto-generated from decorators
- **Validation**: class-validator + class-transformer on all request bodies
- **API versioning**: URL-based (`/api/v1/`) from the first endpoint
- **Email**: Resend (`resend` npm package) for transactional email (verification, password reset, invitations)

### 0.3 Database

- **Primary**: PostgreSQL 16
- **Connection pooling**: PgBouncer in transaction mode (prevents connection exhaustion above 500 concurrent users)
- **Row-level security**: Enabled at the database level before any user data is written. Every tenant-scoped table has RLS policies. API server connects as a restricted role that cannot bypass RLS.
- **Migration discipline**: All schema changes via Prisma Migrate. No manual schema edits via database client. Migrations run automatically on deployment before the new API version starts.

### 0.4 Queue Layer (Initialized Here — Not Deferred)

- **Redis**: Backing store for BullMQ and hot data cache
- **BullMQ**: Job queue library

Queues initialized in Phase 0 even if no jobs are enqueued yet. OCR (Phase 7), thumbnail generation (Phase 6), push notifications (Phase 10), and email delivery all require this infrastructure. Retrofitting a queue after synchronous flows are built creates breaking changes.

Queues defined at Phase 0:

| Queue | Consumer |
|---|---|
| `receipt-thumbnails` | Sharp worker — generates 300×300 JPEG from original |
| `ocr-processing` | Google Document AI worker |
| `push-notifications` | FCM / APNs dispatch worker |
| `email-delivery` | Resend API worker |
| `sync-signals` | WebSocket signal dispatch |

### 0.5 Security Baseline (Applied to Every Phase)

These are Phase 0 constraints enforced from the first endpoint, not Phase 12 items.

- All endpoints behind HTTPS (TLS 1.3). No HTTP served.
- All database queries parameterized via Prisma. No raw string interpolation.
- Row-level security on every user-scoped table.
- Rate limiting: 10 req/15min per IP on auth endpoints; 1,000 req/min on authenticated endpoints.
- Input validation on every request body.
- CORS allowlist restricted to the web platform origin.
- Secrets never hardcoded. No `.env` files on production servers.
- Dependency scanning: `npm audit` in CI pipeline, fail build on critical vulnerabilities.
- Audit log table `audit_events` from Phase 0. Every mutation on expense, budget, receipt, or household entity writes a record: `(userId, action, entityType, entityId, timestamp, deviceId)`.

### 0.6 Infrastructure

**VPS vs. local machine**:

For development and personal testing, a local machine running Docker Compose is fine. For any deployment with real users or paying customers, use a VPS. Local machine production hosting requires: a static IP or dynamic DNS service (DuckDNS, No-IP), port forwarding on the home router (ports 80 and 443), reliable uptime (home internet outage = app outage), and power continuity. None of these are guaranteed on a home connection. A Hetzner CX41 at €15/month eliminates all of these risks. Use local machine for development, VPS for staging and production.

- **Containerization**: Docker + Docker Compose. All services (NestJS API, PostgreSQL, PgBouncer, Redis) in a single Compose file for dev. Same structure promoted to staging and production.
- **Hosting**: Hetzner CX41 (4 vCPU, 8GB RAM, €15/month) for V3 launch. Adequate to 20k MAU. Documented upgrade path to CX51 then Docker Swarm.
- **Environment strategy**: `dev` (local), `staging` (mirrors prod schema, no real user data), `prod`. Separate configuration per environment.
- **Secret management**: Doppler. No `.env` files on servers.
- **Rollout**: Zero-downtime deployments via Docker rolling update. Database migrations run before the new API version accepts traffic.

### 0.7 CI/CD

GitHub Actions pipelines:

- **On PR**: lint, type-check, unit tests, `npm audit`
- **On merge to `main`**: build Docker image, push to registry, deploy to staging, run integration tests against staging
- **On version tag**: deploy to production

### 0.8 Object Storage

- **Provider**: Cloudflare R2
- **Reason**: No egress fees (unlike S3), native Cloudflare CDN integration
- **Access**: Signed URLs only. 15-minute expiry for receipt originals. 24-hour expiry for thumbnails. Bucket not publicly accessible.
- **Lifecycle**: Originals retained indefinitely. Deleted receipts moved to soft-delete prefix for 30 days before permanent removal.

### 0.9 Monitoring

- **Sentry**: Error tracking on Flutter mobile, Next.js web, and NestJS API. Source maps uploaded. Alerts on error rate spike.
- **Prometheus + Grafana**: API metrics — request count, p50/p95/p99 latency by endpoint, error rate, queue depth per queue, sync lag.
- **Uptime monitoring**: External health check on API health endpoint (Better Uptime or UptimeRobot).

### 0.10 Feature Flag System

Lightweight feature flags from Phase 0. Use a simple database table `feature_flags (key, enabled, enabledForUserIds[])`. Required for: gradual rollout, beta access, subscription tier gating, emergency kill switches for OCR or sync. Do not ship any major feature without a kill switch.

---

## Phase 1 — V2 Data Migration

This phase is entirely absent from the original plan. It is the first V3 deliverable.

### 1.1 The Problem

V2 users have expense data in local SQLite. Upgrading to V3 without migrating that data means all historical context — spending patterns, categories, budgets — is lost. Unacceptable.

### 1.2 Migration Paths

**Path A: In-app migration wizard (primary)**

On first V3 login on a device with V2 data:

1. App detects existing V2 SQLite database at its known path.
2. Migration wizard displays: "We found your existing WalletMelt data. Import it to your cloud account?"
3. User confirms. App reads all expense, category, and budget records from V2 SQLite.
4. App transforms records to V3 schema (field mapping table defined below).
5. App uploads records via the standard sync push endpoint with `source = migration`.
6. Progress shown per batch (100 records/batch). On failure, retry with exponential backoff.
7. Before upload starts: V2 data exported to a local backup file. If migration fails, V2 data is untouched.

**Path B: CSV bridge (fallback)**

V2 releases a one-time update that exports all data to CSV files (expenses.csv, categories.csv, budgets.csv). V3 web platform's CSV import feature (Phase 5) ingests these files. Simpler to implement; worse UX; available as fallback.

### 1.3 V2 → V3 Field Mapping

| V2 SQLite Field | V3 PostgreSQL Field | Transform |
|---|---|---|
| `_id` (integer) | `id` (UUID) | Generate UUID; store V2 ID as `legacyId` for deduplication |
| `amount` | `amount` (Decimal) | Direct |
| `date` (text) | `date` (Timestamptz) | Parse ISO string; assume local timezone |
| `category` (text) | `categoryId` (UUID) | Match by name; create if new |
| `note` | `notes` | Direct |
| `receiptPath` (local path) | `receiptId` | Not migrated — flag for user to re-upload |
| `createdAt` | `createdAt` | Direct |

### 1.4 Migration Safety

- Migration runs inside a server-side transaction. Partial migrations roll back.
- `legacyId` stored on migrated records for deduplication — re-running migration does not create duplicates.
- Users can trigger re-migration from Settings if first attempt failed.
- Migration status tracked in `migration_status`: `(userId, status, recordsTotal, recordsMigrated, startedAt, completedAt, error)`.

---

## Phase 2 — Identity & Accounts

### 2.1 Authentication: NestJS + Passport.js (Self-Hosted)

No external auth vendor. Authentication is implemented directly in NestJS using the standard Passport.js integration. This removes all vendor dependency for a module that is approximately 400–600 lines of code.

**Required packages**:

```
@nestjs/passport
@nestjs/jwt
passport
passport-local         # email/password strategy
passport-jwt           # JWT verification strategy
passport-google-oauth20  # Google OAuth2
passport-apple         # Apple Sign-In (requires Apple Developer account, private key, team ID)
argon2                 # password hashing
```

**Refresh tokens**: Stored in Redis with TTL = 30 days. Fast lookup and instant invalidation without a database round-trip.

**Email**: All transactional emails (verification, password reset, household invitations) sent via Resend API. Configure a custom domain (e.g., `noreply@walletmelt.com`) and verify it in Resend. Single SDK call per send.

### 2.2 Authentication Methods

- Email + password (mandatory)
- Google OAuth2
- Apple Sign-In — **mandatory on iOS** if any third-party social login is offered (App Store Review Guideline 4.8). Not optional.

### 2.3 Token Architecture

- **Access token**: JWT, RS256 signed, 15-minute expiry
- **Refresh token**: Opaque (random bytes, SHA-256 hashed before storage in Redis), 30-day expiry with rotation on every use
- **Refresh token rotation**: On refresh, old token is invalidated and new token issued. If a previously-used refresh token is presented, the entire session is invalidated (replay detection).

### 2.4 Security Requirements

- Argon2id for password hashing (memory-hard; preferred over bcrypt)
- Rate limiting on `/auth/login` and `/auth/register`: 10 requests per 15 minutes per IP
- Account lockout after 10 consecutive failed login attempts (15-minute lockout period)
- Password reset via time-limited (1 hour) HMAC-signed token sent to verified email
- Email verification required before sync is enabled. Unverified accounts can log in but sync is blocked with a clear UI message.

### 2.5 Session Management

- Every session records: `deviceId`, `userAgent`, `lastSeen`, `platform`, `ipAddress`
- Users can view all active sessions in Settings
- Users can revoke individual sessions or all sessions (logout everywhere)
- Suspicious login (new device, different country from last session) triggers email notification — not account block

---

## Phase 3 — Cloud Sync Engine

### 3.1 Data Model

Every syncable entity requires:

```
id            UUID        — client-generated, not server-assigned
userId        UUID        — owner
createdAt     Timestamptz
updatedAt     Timestamptz — updated on every local mutation
deletedAt     Timestamptz — nullable; soft delete
syncVersion   Integer     — server-assigned monotonically increasing integer
deviceId      UUID        — which device last mutated this record
```

UUIDs are client-generated. This enables offline record creation without a server round-trip.

### 3.2 Syncable Entities

- `expenses`
- `categories`
- `budgets`
- `grocery_items`
- `receipts` (metadata only — file sync handled in Phase 6)
- `settings` (per key, not as a single blob)
- `household_memberships` (Phase 8)

### 3.3 Sync Architecture

**Client (Flutter, Drift ORM)**:
- Local SQLite is the primary data store for all UI rendering
- All writes go to local first, then enqueued for sync
- Sync queue is persistent — stored in a dedicated SQLite table, survives app kill
- Per-record sync state: `clean` | `dirty` | `syncing` | `conflict`

**Server (NestJS)**:
- Maintains authoritative record versions per user
- Tracks `highestSyncVersion` per user
- Never modifies client-generated UUIDs

### 3.4 Sync Flows

**Outbound push (client → server)**:

1. User mutates a record locally. SQLite write. `syncState = dirty`.
2. Sync queue picks up dirty records (runs on connectivity change and every 30 seconds).
3. `POST /api/v1/sync/push` — batch of up to 100 dirty records.
4. Server validates each record, assigns `syncVersion`, persists.
5. Server returns: `{ accepted: [], rejected: [], conflicts: [] }`.
6. Client marks accepted as `clean`. Rejected remain `dirty`. Conflicted set to `conflict`.
7. If app killed during sync: persistent queue re-attempts on next launch.

**Inbound pull (server → client)**:

1. `GET /api/v1/sync/pull?since={lastSyncVersion}`
2. Server returns all records with `syncVersion > lastSyncVersion` for this user (paginated, 500 records per page).
3. Client applies changes to local SQLite: insert new, update changed, soft-delete if `deletedAt` is set.
4. Client updates stored `lastSyncVersion` to the highest version received.

**Real-time signal**:

- Server maintains WebSocket connection per authenticated client (NestJS `@nestjs/websockets` + socket.io).
- On any write for a user (from any device), server emits a lightweight `sync-available` signal on that user's WebSocket channel.
- Client receives signal, triggers a pull.
- This avoids polling while keeping pull as the authoritative sync mechanism.

**Initial sync (new device login)**:

- `lastSyncVersion = 0`.
- Server returns full dataset, paginated.
- Client shows "Syncing your data" with progress bar (records received / total).
- UI is usable after first page of data is received; remaining pages load in background.

**Long-offline recovery (30+ days offline)**:

- On reconnect, client executes a standard pull with `since={lastSyncVersion}`.
- Server may return thousands of records across many pages.
- Client processes in order. No special handling required — pull model handles this natively.
- If `lastSyncVersion` is so old that the server has purged version history, server returns HTTP 409 with `full_resync_required`. Client drops local cache and performs initial sync.

### 3.5 Sync Queue Persistence

Dedicated SQLite table `sync_queue`:

```
id, entityType, entityId, operation (insert|update|delete), payload,
attempts, lastAttempt, status (pending|failed)
```

On app start, all records with `status = pending` are re-enqueued. Exponential backoff: 5s → 30s → 2min → 10min → 1hr. After 24 hours of consecutive failure, status = `failed`, surfaced to user in sync status UI.

### 3.6 Sync Status UI

Required UI states:

- **Synced**: "Last synced {time}"
- **Syncing**: spinner with "Syncing..."
- **Pending**: "X changes waiting for connection"
- **Failed**: "Sync failed. Tap to retry." with error detail on demand

---

## Phase 4 — Conflict Resolution System

### 4.1 Conflict Detection

A conflict is detected when the server receives a pushed record where:
- The client's `updatedAt` is earlier than the server's current `updatedAt` for the same `id`
- **AND** the payload content has diverged from the server's current version

If content is identical (re-push of same change), it is accepted silently.

### 4.2 Resolution Strategy by Entity

| Entity | Strategy | Rationale |
|---|---|---|
| expenses (amount, category, date) | Last Write Wins (server-receipt timestamp) | Low conflict probability; silent override acceptable |
| expenses (notes) | Last Write Wins | Cosmetic field, low stakes |
| budgets (amount) | User Choice | High-intent setting; silent override is wrong |
| categories (name, color) | Last Write Wins | Cosmetic |
| settings | Last Write Wins per key | Granular LWW prevents full-settings conflicts |
| receipts (metadata) | Last Write Wins | File already committed; metadata is secondary |
| household budgets | User Choice | Shared resource; requires explicit human decision |

### 4.3 LWW Tie-breaking

When `updatedAt` timestamps are equal (possible with clock skew or low-resolution device clocks):

Tie-break by `deviceId` lexicographic order. Deterministic. Consistent across both clients without coordination.

### 4.4 User Choice Conflict UI

For entities requiring User Choice:

Flutter modal: "Conflict on [Entity Name]"

Displays two columns:
- This device: [field values]
- Another device: [field values]

User taps "Use this" on one column. Selection pushed as a new mutation with current timestamp and `conflictResolved = true` flag. Server accepts without conflict check on records with this flag.

### 4.5 Conflict Log

All conflict events written to `conflict_log`:

```
id, userId, entityType, entityId, deviceIdA, deviceIdB,
strategyApplied, winningSide, resolvedAt, resolvedBy
```

---

## Phase 5 — Web Application

### 5.1 Web Framework: Next.js 15 (App Router)

**Why not Flutter Web**: Flutter Web with CanvasKit renderer has a 2–5MB WASM initial payload, measurable scroll performance degradation above ~2,000 rows, and known limitations on native browser text selection and accessibility tooling. These are incompatible with a desktop-first power-user workflow.

**Why Next.js over SvelteKit**:
- The existing stack (HU-Carpool, MeritGrid) is React + TypeScript + shadcn/ui + TanStack Query — no new framework or ecosystem to learn
- TanStack Table is the industry standard for data-heavy React UIs and handles virtual scrolling, bulk selection, column sorting, and filtering at any dataset size
- TypeScript types shared directly with NestJS via `packages/types` in the monorepo (not possible with Svelte's component model)
- App Router's nested layouts (`layout.tsx`) map cleanly to the dashboard-with-sidebar structure
- Recharts for financial charts; Framer Motion for transitions; Zod for form validation (already used in HU-Carpool)

**Full web stack**:

```
Next.js 15 (App Router)
TypeScript
Tailwind CSS v4
shadcn/ui (Radix UI primitives — accessible, unstyled, composable)
TanStack Table v8 (transaction list, budgets table — virtual scroll)
TanStack Query v5 (server state management, sync with NestJS API)
TanStack Virtual (row virtualization for large lists)
Recharts (spending charts, budget progress, trend lines)
Framer Motion (page transitions, micro-animations)
Zod (form validation — shared schemas from packages/validators)
React Hook Form (form state management)
```

### 5.2 Pages and Features

**Dashboard**:
- Monthly spending vs. budget by category
- Spending trend (6-month bar chart via Recharts)
- Budget health cards (% utilized, days remaining)
- Recent transactions (last 10)
- Financial insights cards (from Phase 9)

**Transactions**:
- TanStack Table with TanStack Virtual — renders 50 rows at a time regardless of dataset size
- Server-side search above 1,000 records (PostgreSQL FTS), client-side below
- Filters: date range, category, amount range, has-receipt (URL-synced filter state via nuqs)
- Sort: date (default desc), amount, category
- Bulk select: checkbox column, bulk delete, bulk re-categorize
- CSV export of current filtered view
- CSV import

**Budgets**:
- Monthly overview with Recharts progress bars
- Per-category budget with spend vs. budget
- Inline editing via shadcn/ui Popover + React Hook Form

**Receipts**:
- Grid gallery (thumbnail view)
- Receipt viewer with zoom and pan
- Link / unlink to expense
- OCR result display with confidence indicators (Plus+ only)

**Settings**:
- Account: email, password change, connected social accounts
- Devices: active sessions with revoke control
- Sync: sync status, force sync, clear local cache
- Subscription: current plan, upgrade/downgrade (Paddle-hosted portal)
- Data: full export (JSON + CSV), delete account (30-day retention period)

### 5.3 CSV Import Specification

- Imported records receive client-generated UUIDs
- `deviceId` = `web-import-{userId}-{timestamp}`
- `createdAt` parsed from CSV date column; `updatedAt` = import timestamp
- Category matching: exact name match first, case-insensitive fuzzy match second, "Uncategorized" fallback with flagging
- Duplicate detection: match on `(userId, amount, date, categoryId)` → surface duplicates to user for confirmation, do not silently discard

### 5.4 Performance Baseline

Before any growth marketing spend, run Lighthouse on the Transactions page with a 500-record dataset. Target: Performance ≥ 85. If it fails this threshold at launch, the issue is in the data fetching layer (TanStack Query configuration or API pagination), not the framework itself.

---

## Phase 6 — Receipt Cloud System

### 6.1 Upload Pipeline

1. User selects or captures image on Flutter client
2. Client converts HEIC to JPEG (Flutter image_picker handles this)
3. Client compresses to max 2MB, max 2048px on longest side
4. Client calls `POST /api/v1/receipts` → server creates receipt record with `uploadStatus = pending`, returns signed R2 upload URL (15-minute expiry)
5. Client uploads directly to R2 via signed URL (bypasses API server bandwidth)
6. Client calls `PATCH /api/v1/receipts/{id}/uploaded` to confirm
7. API enqueues `receipt-thumbnails` job (BullMQ)
8. API enqueues `ocr-processing` job (BullMQ) — gated by subscription tier
9. Response returns to client immediately; thumbnail and OCR are async

### 6.2 Thumbnail Generation (Async Worker)

Worker consumes `receipt-thumbnails` queue:
- Fetches original from R2
- Generates 300×300 JPEG via Sharp (cover crop)
- Uploads thumbnail to R2 at `receipts/{userId}/{receiptId}/thumb.jpg`
- Updates `receipts.thumbKey` and `receipts.thumbStatus = ready`
- On failure: retry 3 times. Mark `thumbStatus = failed` after third failure. Client shows placeholder icon.

### 6.3 Receipt Metadata Schema

```
id            UUID
userId        UUID
expenseId     UUID (nullable)
originalKey   String (R2 object key)
thumbKey      String (R2 object key, nullable until generated)
thumbStatus   Enum: pending | ready | failed
mimeType      String
sizeBytes     Integer
width         Integer
height        Integer
uploadStatus  Enum: pending | uploaded | failed
ocrStatus     Enum: pending | queued | processing | completed | failed | not_eligible
ocrData       JSONB (structured OCR output from Google Document AI)
createdAt     Timestamptz
deletedAt     Timestamptz
```

### 6.4 Serving

Receipts served via Cloudflare CDN fronting R2. Signed read URLs: 15-minute expiry for originals, 24-hour for thumbnails.

---

## Phase 7 — OCR Receipt Intelligence

### 7.1 Provider Decision: Google Cloud Document AI (Expense Parser)

**Evaluated providers — accuracy ranking for diverse receipt types**:

| Provider | Structured Fields | Multilingual | Low-Quality Images | Cost/Page |
|---|---|---|---|---|
| Google Document AI (Expense Parser) | Yes — labeled fields | 100+ languages incl. Arabic | Best | $0.10 |
| Azure Document Intelligence (Prebuilt Receipt) | Yes — labeled fields | Good | Good | $0.01 |
| AWS Textract (AnalyzeExpense) | Yes — labeled fields | Limited (English-primary) | Good | $0.015 |
| Google Vision API | No — raw text only | Excellent | Good | $0.0015 |

**Decision: Google Cloud Document AI — Expense Parser processor.**

Rationale for accuracy priority:
- Returns labeled fields (vendor name, vendor address, receiver name, total amount, net amount, tax amounts, tip, receipt date, receipt time, line items with description/quantity/unit price/amount) as structured JSON — not raw text requiring post-processing
- Multilingual support covers 100+ languages. For Pakistani receipts that mix English and Urdu or use varied number formats, Document AI handles this more reliably than Textract (English-primary) or Azure
- On low-quality, crumpled, or partially obscured receipt images, Document AI's accuracy advantage is most pronounced — this is the exact category of inputs a mobile app receives
- First 1,000 pages/month free — covers development, testing, and early users at zero OCR cost

**Cost model and revised tier limits**:

At $0.10/page, OCR limits must be adjusted from the original plan to keep OCR COGS within 30% of subscription revenue per tier:

| Tier | Monthly Price | OCR Limit | OCR Cost | OCR as % of Revenue |
|---|---|---|---|---|
| Free | $0 | 0 | $0 | — |
| Plus | $4.99 | 10 receipts | $1.00 | 20% |
| Family | $9.99 | 25 receipts/household | $2.50 | 25% |
| Pro | $14.99 | 60 receipts | $6.00 | 40% |

Pro tier OCR cost at 40% of revenue is high. Two mitigations: (a) most Pro users will not use all 60 OCR calls — average usage will be lower than the limit, and (b) Pro is the highest-margin tier overall due to lower support cost relative to revenue.

**If $0.10/page is unacceptable after observing real usage patterns**, switch to **Azure Document Intelligence Prebuilt Receipt** at $0.01/page. Accuracy is marginally lower than Document AI but significantly higher than AWS Textract, and the cost model restores the original tier limits (50 receipts on Plus, unlimited on Pro).

### 7.2 OCR Pipeline

```
receipt-thumbnails job completes
    ↓
ocr-processing job dequeued
    ↓
Check user entitlement — if not eligible, mark ocrStatus = not_eligible, stop
    ↓
Check monthly OCR usage count vs. tier limit — if exceeded, mark ocrStatus = not_eligible, stop
    ↓
Fetch original from R2
    ↓
Submit to Document AI Expense Parser endpoint
    ↓
Parse response: merchant, date, total, tax, line items, confidence scores per field
    ↓
Store in receipts.ocrData (JSONB)
    ↓
Update ocrStatus = completed, increment monthly_ocr_usage for user
    ↓
Enqueue sync-signals job to notify client
```

### 7.3 Google Document AI Setup

- Create a Google Cloud project
- Enable Document AI API
- Create a processor of type "Expense Parser" in the desired region (us-central1 or europe-west4)
- Create a service account with `roles/documentai.apiUser` permission
- Download service account JSON key — store in Doppler, not in code

SDK usage in NestJS:
```typescript
import { DocumentProcessorServiceClient } from '@google-cloud/documentai';
```

The `processDocument` call accepts a base64-encoded document and returns structured `Document` proto with entity fields and confidence scores.

### 7.4 Confidence Handling

Document AI returns per-entity confidence (0.0–1.0):

| Confidence | Behavior |
|---|---|
| ≥ 0.90 | Pre-fill field; label as "Auto-filled" |
| 0.70–0.89 | Pre-fill field; highlight in amber for review |
| < 0.70 | Leave field empty; show "Could not read" |

### 7.5 User Review Flow

Client receives OCR-complete sync signal. User opens receipt:
- Pre-filled fields with confidence labels
- Editable inline
- "Save and link to expense" creates or links an expense with extracted values
- "Save standalone" stores OCR data without linking

### 7.6 Failure Handling

On Document AI error: mark `ocrStatus = failed`. Do not retry automatically. Surface retry button to user explicitly. Each retry consumes one OCR credit from the monthly limit.

---

## Phase 8 — Household Accounts

### 8.1 Data Model

```sql
households:
  id UUID, name TEXT, ownerId UUID, createdAt TIMESTAMPTZ, deletedAt TIMESTAMPTZ

household_members:
  id UUID, householdId UUID, userId UUID, role ENUM, invitedAt TIMESTAMPTZ,
  joinedAt TIMESTAMPTZ, status ENUM(pending|active|removed)

household_invitations:
  id UUID, householdId UUID, invitedEmail TEXT, invitedBy UUID,
  token TEXT, expiresAt TIMESTAMPTZ, status ENUM(pending|accepted|expired|revoked)
```

### 8.2 Permissions Matrix

| Action | Owner | Admin | Member | Viewer |
|---|---|---|---|---|
| View shared expenses | ✓ | ✓ | ✓ | ✓ |
| Add shared expense | ✓ | ✓ | ✓ | ✗ |
| Edit own shared expense | ✓ | ✓ | ✓ | ✗ |
| Edit others' expense | ✓ | ✓ | ✗ | ✗ |
| Delete shared expense | ✓ | ✓ | ✗ | ✗ |
| Manage shared budgets | ✓ | ✓ | ✗ | ✗ |
| Invite members | ✓ | ✓ | ✗ | ✗ |
| Remove members | ✓ | ✓ | ✗ | ✗ |
| Change member roles | ✓ | ✗ | ✗ | ✗ |
| Transfer ownership | ✓ | ✗ | ✗ | ✗ |
| Delete household | ✓ | ✗ | ✗ | ✗ |

### 8.3 Invitation Flow

1. Admin or Owner invites an email address
2. Server creates `household_invitations` record with a cryptographically random token, 15-day expiry
3. Invitation email sent via Resend with deep link: `walletmelt://invite/{token}`
4. Recipient clicks link:
   - Existing account: JWT-authenticated accept endpoint links them to household
   - No account: redirect to registration; after registration, invitation auto-accepted
5. On accept: `household_members` record created with `status = active`, `role = member`

### 8.4 Ownership Transfer

Owner initiates transfer to any current Admin. Owner must confirm. Transfer is effective immediately. Previous owner's role becomes Admin.

### 8.5 Household Dissolution

Owner triggers dissolution:

1. Server marks `households.deletedAt = now + 7 days`
2. Push notification sent to all members: "Household [name] will be dissolved in 7 days"
3. All shared expenses moved to each member's personal account scope
4. After 7-day grace: household record and memberships hard-deleted
5. No personal expense data is affected

---

## Phase 9 — Financial Intelligence

### 9.1 Architecture: Rule-Based, Not ML

ML for financial insights at sub-50k users is premature. Rule-based analytics are deterministic, debuggable, require no training data, and produce the same user-visible output for the stated insight types.

### 9.2 Analytics Pipeline

Materialized views refreshed nightly by a scheduled NestJS cron job:

```sql
monthly_category_totals:
  (userId, year, month, categoryId, totalAmount, transactionCount)

daily_expense_totals:
  (userId, date, totalAmount)

budget_utilization:
  (userId, year, month, categoryId, budgetAmount, actualAmount, utilizationPct)
```

Results cached in Redis with 24-hour TTL. Cache invalidated when new expenses are pushed.

### 9.3 Insight Definitions

**Budget health**: "You have used {X}% of your {category} budget. {N} days remaining." Trigger exceeded-streak insight at N ≥ 2 consecutive months.

**Trend detection**: Compare current month vs. prior month per category. Trigger if change ≥ 20%: "Your {category} spending is up {X}% vs. last month."

**Spending anomalies**: Per category, compute mean and standard deviation over last 90 days. Flag single expense > mean + 2σ: "This {category} expense is {X}x your usual."

**Recurring expense detection**: Group expenses by merchant (pg_trgm similarity ≥ 0.7). Within each group, find expenses with amount ±5% appearing within ±5 days of the same day across ≥ 3 consecutive months. Flag: "You appear to have a recurring charge of ~{amount} from {merchant}."

### 9.4 Delivery

Insights stored in `user_insights (id, userId, insightType, entityId, message, severity, createdAt, dismissedAt)`. Delivered to client on sync pull. Client renders on Dashboard. Dismissible per insight.

---

## Phase 10 — Notifications System

### 10.1 Push Infrastructure

- **Android + Web**: Firebase Cloud Messaging (FCM)
- **iOS**: Apple Push Notification Service (APNs), routed through FCM via Firebase Admin SDK
- **Server SDK**: Firebase Admin SDK (Node.js) in NestJS NotificationsModule

Device registration: Flutter app requests notification permission post-login, obtains FCM token, sends to `POST /api/v1/devices/fcm-token`. Server stores in `device_tokens (id, userId, platform, token, lastActive, active)`. On logout, token deregistered. FCM `UNREGISTERED` errors trigger `active = false`.

### 10.2 Notification Types

**Local (Flutter scheduled, no server)**:
- Bill payment reminders (user-configured)
- Weekly spending summary (Sunday 8pm, user timezone)

**Push (server-initiated)**:
- Budget 80% utilized
- Budget exceeded
- Sync completed after long-offline recovery
- Household: new member joined
- Household: member added expense above user-configured threshold
- Household invitation received
- OCR completed

### 10.3 Notification Preferences

`notification_settings` table with a row per user per notification type and `enabled` boolean. Synced via settings sync. Both client and server respect preferences.

---

## Phase 11 — Subscription Platform

### 11.1 Payment Processor: Paddle

Stripe does not support Pakistani merchant accounts directly. Paddle operates as merchant of record — handles VAT, GST, and international tax compliance. Web checkout only for V3 launch (no App Store / Play Store platform fee).

### 11.2 Subscription Tiers (Revised for Document AI Cost Model)

**Free**:
- 1 device, local only, no cloud sync
- 100 expense entries/month
- No receipt upload, no OCR

**Plus** — $4.99/month | $39.99/year:
- Unlimited devices, cloud sync
- Unlimited expense entries
- Receipt upload (unlimited storage)
- OCR: 10 receipts/month
- 12-month history

**Family** — $9.99/month | $79.99/year:
- Everything in Plus
- Household sharing (up to 6 members)
- Shared budgets
- OCR: 25 receipts/month (shared household pool)
- 24-month history

**Pro** — $14.99/month | $119.99/year:
- Everything in Family
- OCR: 60 receipts/month
- Advanced financial insights
- CSV export
- Priority support

### 11.3 Trial Period

14-day free trial on Plus, Family, and Pro. No credit card required. One trial per email address.

### 11.4 Entitlement Enforcement

Subscription status synced to client on pull. Client gates UI. Server validates entitlement and monthly OCR usage count on every gated API call. Client-side gating alone is bypassable.

---

## Phase 12 — Security Audit

Phase 0 established the security baseline. Phase 12 is a formal audit before any growth marketing.

### 12.1 Penetration Testing

Third-party penetration test covering: auth session management, RLS bypass attempts (User A accessing User B's data), receipt signed URL forgery, direct bucket access, sync endpoint authorization, household role escalation, rate limiting bypass.

Remediate all critical and high findings before growth marketing spend.

### 12.2 Compliance

**Pakistan (primary)**: Verify PTA data localization requirements for financial data. If applicable, Hetzner must be replaced with a Pakistan-located or compliant-jurisdiction host.

**GDPR (secondary — EU users)**: Full data export (Phase 5), account deletion with 30-day retention (Phase 5), privacy policy covering Paddle, Google Cloud (OCR), Cloudflare. Data processing agreements with all processors.

### 12.3 Pre-Launch Checklist

- OWASP Top 10 coverage verified
- Zero critical/high severity dependency vulnerabilities
- Production secrets rotated from development values
- TLS: A or A+ on SSL Labs
- Content Security Policy headers on Next.js web app
- No PII in application logs (verified by log sampling)
- Audit log retention: 12 months minimum

---

## Phase 13 — Scalability

### 13.1 Revised Targets

| Year | MAU Target | Expenses/day | Sync requests/day |
|---|---|---|---|
| 1 | 5,000 | 50,000 | 200,000 |
| 2 | 30,000 | 300,000 | 1,200,000 |
| 3 | 100,000 | 1,000,000 | 4,000,000 |

### 13.2 Infrastructure Scaling Path

**0–20k MAU**: Single Hetzner CX41, Docker Compose. ~€40/month.
**20k–50k MAU**: Hetzner CX51 (8 vCPU, 16GB). Hetzner Managed PostgreSQL (separate, automated backups). Redis on separate CX21. ~€120/month.
**50k–100k MAU**: Docker Swarm on 3-node cluster. API scaled to 3 replicas. PgBouncer in front of primary. PostgreSQL read replica for insight queries and sync pulls. Redis Sentinel for HA. ~€350/month.

### 13.3 ClickHouse Evaluation Gate

Introduce ClickHouse only when PostgreSQL materialized view refresh time exceeds 60 seconds nightly **or** insight query p95 latency exceeds 5 seconds at 50k MAU. Measurable, conditional — not calendar-based.

### 13.4 Required Indexes (Phase 0)

```sql
-- Sync pull (most frequent query pattern)
CREATE INDEX idx_expenses_user_sync ON expenses (userId, syncVersion);

-- Date range queries for insights
CREATE INDEX idx_expenses_user_date ON expenses (userId, date DESC);

-- Category aggregation
CREATE INDEX idx_expenses_user_category ON expenses (userId, categoryId, date);

-- Fuzzy merchant matching (recurring detection)
CREATE EXTENSION pg_trgm;
CREATE INDEX idx_expenses_merchant_trgm ON expenses USING GIN (merchant gin_trgm_ops);
```

---

## Revised Tech Stack

| Layer | Technology | Decision Basis |
|---|---|---|
| Mobile client | Flutter | Shared mobile codebase (Android, iOS) |
| Web client | Next.js 15 (App Router) + TypeScript | Performance, data table requirements, existing React/TS familiarity |
| Web UI components | shadcn/ui (Radix UI + Tailwind) | Accessible, composable; already in use on HU-Carpool |
| Web data tables | TanStack Table v8 + TanStack Virtual | Virtual scroll; bulk select; sorting/filtering at any dataset size |
| Web data fetching | TanStack Query v5 | Already in use on HU-Carpool; pairs natively with Next.js App Router |
| Web charts | Recharts | React-native; budget progress, trend lines |
| Monorepo | Turborepo | Shared TypeScript types and Zod schemas between NestJS and Next.js |
| Backend framework | NestJS | TypeScript, module architecture |
| Auth | NestJS + Passport.js (passport-local, passport-jwt, passport-google-oauth20, passport-apple) | Self-hosted; no vendor dependency |
| Password hashing | Argon2id | Memory-hard; preferred over bcrypt |
| ORM + migrations | Prisma | Type-safe queries; migration tooling |
| Database | PostgreSQL 16 | Relational, RLS, JSONB, FTS, pg_trgm |
| Connection pooling | PgBouncer | Prevents connection exhaustion |
| Cache | Redis | BullMQ backing store + hot data |
| Job queue | BullMQ | Redis-backed; visibility tools |
| Object storage | Cloudflare R2 | No egress fees |
| CDN | Cloudflare | Integrated with R2 |
| OCR | Google Cloud Document AI (Expense Parser) | Highest accuracy; multilingual; structured output |
| Image processing | Sharp (Node.js) | Thumbnail generation in NestJS worker |
| Push notifications | FCM + APNs via Firebase Admin SDK | Flutter-native support; unified dispatch |
| Email | Resend | Modern transactional email API; simple SDK; custom domain support |
| Payments | Paddle | Merchant of record; Pakistan-compatible |
| Full-text search | PostgreSQL FTS + pg_trgm | Sufficient to 100k MAU |
| Analytics | PostgreSQL materialized views | Sufficient to 50k MAU; ClickHouse conditional |
| Hosting | Hetzner VPS (Docker Compose) | Self-hosted; cost-effective; documented scaling path |
| Monitoring | Sentry + Prometheus + Grafana | Error tracking + metrics |
| Uptime | Better Uptime | External health monitoring |
| CI/CD | GitHub Actions | |
| Containerization | Docker + Docker Compose | |
| Secret management | Doppler | Dev and prod |
| Feature flags | Database table (`feature_flags`) | Lightweight; no third-party dependency |

---

## Phase Order Summary

| Phase | Name | Status vs. Original |
|---|---|---|
| 0 | Architecture + DevOps + Security Baseline | Expanded; queue layer and security baseline added; Supabase removed |
| 1 | V2 Data Migration | New — entirely absent from original |
| 2 | Identity & Accounts | Self-hosted auth in NestJS + Passport.js; Supabase Auth option removed; Apple Sign-In mandatory |
| 3 | Cloud Sync Engine | Full-offline recovery, initial sync, queue persistence, status UI added |
| 4 | Conflict Resolution | LWW tie-breaking; entity matrix; conflict UI; log table added |
| 5 | Web Application | Flutter Web replaced with Next.js 15; full stack specified; monorepo integration |
| 6 | Receipt Cloud System | Direct-to-R2 upload; thumbnail async |
| 7 | OCR Receipt Intelligence | Provider changed to Google Document AI; cost model; confidence handling; revised tier limits |
| 8 | Household Accounts | Permissions matrix; invitation flow; ownership transfer; dissolution |
| 9 | Financial Intelligence | Rule-based; materialized views; insight algorithms specified |
| 10 | Notifications System | FCM + APNs; local vs. push; preference management; stale token handling |
| 11 | Subscription Platform | Paddle; tiers revised for Document AI cost model; entitlement enforcement |
| 12 | Security Audit | Formal audit; PTA compliance added |
| 13 | Scalability | Targets revised to 100k MAU; tiered infrastructure path; ClickHouse conditional |

**Removed**: Public API (Phase 11 in original) — premature; post-v3 scope

---

## V3 Success Criteria

| Criterion | Metric |
|---|---|
| V2 migration | V2 users migrate existing data without loss; duplicate prevention works |
| Authentication | Users authenticate from any device; Apple Sign-In works on iOS |
| Sync speed | Expense on one device appears on all others within 10 seconds on standard connectivity |
| Offline resilience | Device offline up to 30 days reconnects and syncs without data loss |
| Conflict resolution | Budget conflicts surface to user; no silent overwrites on high-intent entities |
| Receipt sync | Originals accessible across devices within 15 minutes of upload |
| OCR accuracy | Merchant, date, and total extracted with ≥ 90% confidence on clear receipt photos |
| Web parity | Next.js web platform reaches feature parity with mobile for expense and budget management |
| Web performance | Lighthouse Performance ≥ 85 on Transactions page with 500-record dataset |
| Household | Household collaboration for up to 6 members with correct permission enforcement server-side |
| Billing | Subscription billing collects payment; entitlement enforced server-side on every gated API call |
| API performance | p95 latency < 500ms for sync endpoints under normal load |
| Scale | Infrastructure supports 100,000 MAU without architectural change |
| Security | Zero critical findings in third-party penetration test before growth marketing |