# Otlob Monorepo — Architecture Reference

Food-delivery platform (Otlob-style): customer / driver / vendor-admin apps + a single
NestJS backend. Also read `.agents/AGENTS.md` (development rules, dependency hierarchy,
Definition of Done) — this document is the *how it works* companion to that *how to work* doc.

---

## 1. Repository layout

```
otlob_workspace/
├── backend/                    NestJS (TypeScript) API — Prisma 7 / Postgres / Redis / BullMQ / Socket.IO
│   └── .env.example            Canonical env template for the backend
├── apps/
│   ├── customer/               Flutter customer app
│   ├── driver/                 Flutter driver app
│   └── vendor/                 Flutter vendor/admin console (ADMIN, SUPER_ADMIN, VENDOR_MEMBER)
├── packages/
│   ├── api/                    Generated OpenAPI client (dart-dio + built_value)   [generated, do not hand-edit]
│   ├── core/                   Shared infra: Dio, auth interceptor, tokens, socket, FCM push, env, providers, l10n
│   ├── data/                   Repository layer over the API client + shared chat/inbox providers
│   └── ui_kit/                 Shared theme + presentational widgets only
├── docs/                       This document
├── .agents/AGENTS.md           Development rules (read first)
├── docs.json                   Live Swagger spec exported by the backend  (generator input)
└── swagger.json                Older/orphaned export — do not use
```

Melos/Dart workspace root: `pubspec.yaml` (`workspace: apps/*, packages/*`), SDK ^3.11.0.

Dependency chain (must never be violated — backend is the single source of truth):

```
backend → docs.json(OpenAPI) → packages/api → packages/data → packages/core → packages/ui_kit → apps/*
```

---

## 2. Backend (`backend/`)

NestJS 11, Prisma 7 (`@prisma/adapter-pg`, PostGIS + pgcrypto), Redis, BullMQ, Socket.IO.

### 2.1 Three processes, one codebase

| Process | Entry file | Module | Responsibility |
|---|---|---|---|
| API | `src/api.ts` | `ApiModule` | HTTP REST + Swagger at `/docs`, global guards/filters/interceptors |
| Worker | `src/worker.ts` | `WorkerModule` | BullMQ processors + cron jobs (orders, dispatch, statistics, tickets, vendors, drivers, promotions, audit-logs, mail, push) |
| WS | `src/ws.ts` | `WsModule` | Socket.IO server (namespace `/events`) with `RedisIoAdapter` |

Workers/queues: BullMQ defaults 3 attempts, exponential backoff 2s,
`removeOnComplete {count:30}`, `removeOnFail {count:50}` (`src/infrastructure/queue/queue.module.ts`).
Queue/job/cron names centralized in `src/infrastructure/queue/queues.constants.ts`
(ORDER_JOBS, CRON_JOBS, STATS_JOBS, AUDIT_JOBS, TICKET_JOBS). Processors are registered
ONLY in `WorkerModule` (`worker.module.ts:75-85`); e.g. `DispatchProcessor` is intentionally
not in `DispatchModule`. `MailModule.register({enableWorker})` / `PushModule.register(...)`
switch worker ownership between API (false) and worker process (true).

### 2.2 Global pipeline (`api.module.ts:105-112`)

- `APP_GUARD`: `JwtAuthGuard` → `VerifiedGuard` → `CustomThrottlerGuard` (Redis-backed rate limiter)
- `APP_INTERCEPTOR`: `TransformInterceptor` (envelope) → `AuditLogInterceptor`
- `APP_FILTER`: `AllExceptionsFilter` (Prisma P2002→409, P2025→404)

Response envelope (via `common/utils/api-response.builder.ts`, `common/dto/api-response.dto.ts`):

```json
{ "success": true, "statusCode": 200, "message": "...", "data": {...} | null, "errors": null, "timestamp": "..." }
```

Error keys are dotted i18n constants (`common/constants/response.constants.ts`,
e.g. `order.error.invalid_transition`) shared across all layers; Flutter maps them via
`ApiErrorMapper` / app-specific `ErrorUtils.translate`.

### 2.3 Feature module layout (`src/features/<name>/`)

- `<name>.controller.ts` — routes, DTO validation, Swagger response decorators
- `<name>.service.ts` (split into `*-checkout/-state/-payment.service.ts` for orders)
- `<name>.repository.ts` — Prisma + raw SQL (geometry, sequences) when needed
- `<name>.processor.ts` — BullMQ job handling (worker process only)
- `<name>.module.ts`, `dto/*.dto.ts`
- Used guards/decorators from `common/`: `@Public`, `@Roles(Role.X)`, `@RequirePermissions(Permission.X)`,
  `@VendorMember`, `@Verified`, `@UnverifiedAllowed`, `@CurrentUser()`, branch/role decorators.
- Swagger response decorators: `@ApiStandardResponse(T)`, `@ApiArrayResponse(T)`,
  `@ApiPaginatedResponse(T)` using the generated `_gen/prisma-classes` response DTOs.

### 2.4 Order lifecycle (events → queues → sockets → settlement)

Event bus: `@nestjs/event-emitter` (`common/events/event-names.ts` registry, naming `domain.action`,
typed payloads in `common/events/index.ts`). Listeners in `common/listeners/*.ts`
(driver, order, dispatch, socket, mail, notification, chat, cart, audit-log, review),
registered in the `@Global()` `ListenersModule` (imported last in `ApiModule`).

**Listener side-effects** (events = in-process; durable work fans out to BullMQ, socket rooms, or DB):

| Listener | Event (key) | Side effect |
|---|---|---|
| `mail` | `AUTH_OTP_REQUESTED` (EMAIL) | build HTML (verify/reset) → `mail_queue` job `send_email` |
| `chat` | `CHAT_MESSAGE_SENT/READ`, `CHAT_CONVERSATION_CREATED/CLOSED` | socket emit to participants (`chat.message`/`chat.read`/`conversation.created`/`conversation.closed`) + batched `NotificationType.CHAT_MESSAGE` |
| `notification` | `TICKET_STATUS_UPDATED`, `SHIFT_REMINDER`, `SHIFT_MISSED`, `SHIFT_SWAP_CANCELLED` | `NotificationsService.create` (bilingual title/body), skips self-actor |
| `order` | order lifecycle events | socket emits (`order.new`, `order.status`, `order.cancelled`, `dispatch.incoming`, `dispatch.cancelled`) + notifications |
| `dispatch` | `ORDER_CANCELLED`; status→`DRIVER_ASSIGNED`/`PENDING_PAYMENT` | `dispatchService.cancelActiveDispatch(orderId)` |
| `socket` | `ws.driver.location.update`, `ws.driver.disconnected` | `LocationRepository.processLiveLocationUpdate` / `handleUserDisconnect` |
| `driver` | `DRIVER_LOCATION_UPDATED`, `DRIVER_STATUS_CHANGED` (e.g. reason `UNPAID_COMMISSION`) | socket emit `driver.location` to customer; notification/queue actions |
| `cart` | `ORDER_CREATED` | `cartService.clearCart(customerUserId, vendorId)` (vendor orders only) |
| `audit-log` | `AUDIT_LOG_CREATED` (async) | `audit_logs_queue` job `audit_log.create` (attempts 3, exp backoff 5s) |
| `review` | `REVIEW_SUBMITTED` (async) | aggregate `orderReview` → update `vendor.rating` / `driver.rating` (driver rating ×100) |

Live order flow:

1. **Place** — `orders-checkout.service.ts` → `orders.repository.ts` (raw SQL w/ geometry,
   `ORD-*` order number) → creates `Order` (PENDING), items, status event.
   Also supports `CUSTOM_DELIVERY` and `RIDE` order types.
2. **Vendor accept** — `orders-state.service.ts` (status transition maps at `:51-96`,
   quick-accept at `:116-161`); emits `order.*` events.
3. **Dispatch** — `dispatch.service.ts` / `dispatch.processor.ts`: pick drivers near vendor,
   create `OrderDispatch` PENDING, broadcast `dispatch.incoming` socket events to driver rooms,
   handle accept/reject/expire with search-radius expansion (platform settings:
   `driverSearchRadiusKm`, `driverSearchRadiusStepKm`, `driverSearchRadiusMaxKm`,
   `driverAcceptTimeoutSecs`, `driverSearchMaxAttempts`).
4. **Fee estimate & payment** — `POST /orders/fee-estimate` (standard) and
   `POST /orders/custom-fee-estimate` (custom/ride) compute delivery fee, service fee,
   driver bonus, tax, and grand total at checkout using vendor→customer distance
   (PostGIS `ST_Distance`) or pickup→dropoff distance respectively. The fee is fixed
   at checkout and shown to the customer before placing the order. `PENDING_CUSTOMER_APPROVAL`
   is dead in status transitions. `PENDING_PAYMENT` for mobile-wallet orders (cash on delivery
   vs mobile wallet); customer confirms transfer, backend marks paid.
5. **Delivery & settle** — `statistics.service.settleOrder`: commission, driver tier bonus,
   cash-collected, driver/vendor wallet ledgers (row locks), coins earned/spent,
   DAILY/WEEKLY/MONTHLY/YEARLY stat upserts, emits `ORDER_SETTLED`.

Monitors/crons in `orders.processor.ts` (`delivery_watchdog`,
`auto_cancel_pending`), data-retention crons in `statistics.processor.ts`.

### 2.5 Live state in Redis (prefix `otlobegy:`)

`otlobegy:dispatch:{id}` · `otlobegy:order-dispatch-active:{orderId}` ·
`otlobegy:driver-pending-dispatches:{driverId}` · `otlobegy:dispatch:{id}:rejected` ·
`otlobegy:driver-locations` (GEO set — `GEOADD`/`GEORADIUS`/`GEOPOS`/`ZREM`) ·
`otlobegy:user-driver-map:{userId}` (userId→driverId, cached 12h) ·
`otlobegy:driver-active-order:{driverId}` (JSON: `orderId` + `customerUserId`, drives
0-DB-hit location broadcast) · `banned:user:{sub}` · `revoked:session:{sid}` ·
`revoked:user:{sub}` (checked on WS handshake).

Redis usage overview (`infrastructure/redis/`): `RedisService` = one shared client (or Cluster from
`REDIS_URL` + optional `REDIS_CLUSTER_MODE`, parsed by `redis.parser.ts`) with
get/set/ttl/incr/del/expire/exists + geo + set helpers; `RedisPubSubService` = dedicated
publish/subscribe clients with a per-channel handler map (cross-process bus). Other Redis
consumers: BullMQ (queues), `@socket.io/redis-emitter` (socket broadcasts), throttler storage
**on db 1** (non-cluster only), cache-manager via Keyv. Stale offline-driver entries are
lazy-swept from `otlobegy:driver-locations` during `findNearbyDrivers` (Redis buffer + DB status filter,
cap 20).

### 2.6 Socket layer

- **Gateway** (`infrastructure/socket/socket.gateway.ts`) — namespace `/events`, ping 10s/5s. Handshake
  JWT from `auth.token` → `query.token` → `Bearer` header; verifies access JWT, then checks Redis
  `banned:user:{sub}` / `revoked:session:{sid}` / `revoked:user:{sub}`; joins `user_{userId}` +
  `session_{sid}` rooms; client→server `driver.location.update` (DRIVER only) and disconnect
  re-emitted as `ws.driver.location.update` / `ws.driver.disconnected` events.
- **Auth rules** (`socket-auth.service.ts`) — role must be a valid `Role`; DRIVER rejected only if
  `SUSPENDED`; CUSTOMER always allowed; VENDOR/ADMIN/SUPER_ADMIN allowed by default.
- **Emit service** (`socket.service.ts`) — `@socket.io/redis-emitter` over the shared Redis client, so the
  **worker process can emit to users** without holding a WS server: `emitToUser(userId, event, data)`,
  `emitToRoom`, `broadcast`, `emitToSocket`, `joinRoom/leaveRoom`, `disconnectUser/Session/Room`.
- **Adapter** (`redis-io.adapter.ts`) — `RedisIoAdapter` wires Socket.IO's pub/sub adapter (separate
  pub/sub clients from `parseRedisConfig`) so WS instances scale horizontally.
- Client events used by apps (see `packages/core/.../socket_events.dart`):
  `order.status`, `order.updated`, `order.new`, `order.cancelled`, `dispatch.incoming`,
  `dispatch.cancelled`, `driver.location`, `notification.new`, `chat.message`, `chat.read`,
  plus client→server `driver.location.update`.

### 2.7 Infrastructure modules (`src/infrastructure/`)

Producer/consumer split: `MailModule.register({enableWorker})` and `PushModule.register({enableWorker})`
expose `MailService`/`PushService` (queue-writing producers) in the API process, but only the **worker
process** registers the processor consumers — the pattern for any fan-out module.

| Module | Purpose / key details |
|---|---|
| `prisma` | `pg` Pool (20 conns, idle 30s) → `@prisma/adapter-pg` driver adapter (no binary). Auto **soft-delete filter** (`$extends` query): models with `deletedAt` get `deletedAt: null` injected on `findUnique` (rewritten to `findFirst`), `findFirst`, `findMany`, `count` |
| `redis` | Shared client (or Cluster) singleton: string/ttl/incr + geospatial (`geoadd/georadius/geopos/zrem`) + set ops; `redis-pubsub.service.ts` has dedicated pub/sub clients with per-channel handler registration |
| `queue` | BullMQ `forRoot` (Redis/cluster-aware): attempts 3, exp backoff 2s, keep 30 done / 50 failed. **10 queues** (`queues.constants.ts`): MAIL, PUSH, ORDERS, STATS, TICKETS, VENDORS, DRIVERS, PROMOTIONS, DISPATCH, AUDIT_LOGS. Job sets: `MAIL_JOBS` (`send_email`), `PUSH_JOBS` (`send_devices`/`send_topic`/`subscribe_topic`/`unsubscribe_topic`), `ORDER_JOBS` (`order.dispatch`/`dispatch_expire`/`settle`/`delivery_watchdog`), `STATS_JOBS`, `AUDIT_JOBS`, `TICKET_JOBS`, `CRON_JOBS` (12 schedulers: vendor schedule, auto-cancel pending, expire dispatches, ticket SLA, data retention, archive orphans, system health, promotion check, stuck/unsettled-order monitors, shift warning/late-check) |
| `mail` | `MailService` queues `send_email`; `MailProcessor` (concurrency 10) nodemailer (pool 5/100) — validates recipient MX before send, classifies permanent (5xx, unknown-user, spam → `UnrecoverableError`) vs transient (network/4xx → retry) |
| `push` | `PushService` queues device/topic/subscribe/unsubscribe; `PushProcessor` (concurrency 50) FCM `sendEachForMulticast` chunks of 500, high-priority Android + `contentAvailable` iOS, **auto-deletes invalid tokens** from `device`; credentials from `firebase.provider.ts` (`FIREBASE_PROJECT_ID`/`CLIENT_EMAIL`/`PRIVATE_KEY`) |
| `jwt` | `JwtAccessModule`/`JwtRefreshModule` register `JwtModule` with own secret+expiry and expose DI tokens `JWT_ACCESS_SERVICE` / `JWT_REFRESH_SERVICE` (`common/constants/jwt.constants.ts`) |
| `socket` | gateway + `SocketAuthService` + redis-emitter service + `RedisIoAdapter` — see §2.6 |
| `rate-limiter` | `@nestjs/throttler` over Redis db 1 (non-cluster): `short` 20/s + `medium` 200/min; consumed by `CustomThrottlerGuard` (global, tracker `user-{sub}` else IP) |
| `cache` | cache-manager via `@keyv/redis`, default TTL 10 min (`@Global`) |
| `events` | EventEmitter `forRoot` (delimiter `.`, maxListeners 20, `ignoreErrors: false`) |
| `location` | `LocationRepository` (`@Global`): driver geo pool + 12h user→driver map + active-order JSON (drives live broadcast), `findNearbyDrivers` (geo buffer → DB ONLINE/hasUnpaidCommission=false/vehicle/shift filter → lazy sweep → sort by distance, cap 20), PostGIS: `findZoneByLocation`, `getDistanceKm`, `getOrderLocationContext` (pickup→branch fallback), `buildPointSql`/`buildGeoJsonSql` |
| `storage` | `StorageService`: local disk under `storage/`, uuid names, returns `/media/{folder}/{file}`, path-traversal guard on delete |
| `logger` | Winston console always; **production** daily-rotate `storage/logs/error-*.log` (30d) + `combined-*.log` (14d), level from `LOG_LEVEL` |

### 2.8 Auth

`features/auth` — register/login (email+phone, OTP verify), refresh w/ rotation + grace,
`Session` rows with `hashedRt`, logout/logout-all; JWT strategies in
`features/auth/strategies/{jwt,jwt-rt}.strategy.ts`; `Account` model supports social logins
(`/auth/social`, `SocialLoginDto`) — backend + shared layer ready, but **no social UI exists**
in any app yet. `DevicePlatform`/`RegisterDeviceDto` tie FCM push tokens to users.

### 2.9 Data model (`backend/prisma/schema.prisma`)

~50 models + 30 enums; Postgres extensions `postgis` (geometry) + `pgcrypto`
(`previewFeatures = ["postgresqlExtensions"]`). Core conventions:

- **Money = `Int`** (minor units) everywhere — order lines, product prices, wallet balances,
  commissions. No floats for money. `PlatformSetting` also uses `Int` for % rates and fees
  (`0` = unlimited for `max*Fee`).
- **`PlatformSetting` is a singleton row** (`id @default("default")`, ~130 fields) holding all
  pricing/commission/tax, per-vehicle `pricePerKm`+`min/maxDeliveryFee`+`allow*` matrix, driver
  search radius (`driverSearchRadiusKm/StepKm/MaxKm`, `driverAcceptTimeoutSecs`,
  `driverSearchMaxAttempts`, `maxDispatchBatchSize`), approval timeouts
  (`customerApprovalTimeoutSecs/Mins`, `mobileWalletTimeoutMins`, `autoCancelPendingMins`),
  version/force-update gate, retention days per entity, coins rules, driver bonus program,
  shift toggle + tier bonus, `maxActiveOrdersPerCustomer`, `requirePriorDeliveryForMultipleOrders`,
  `maxOtpAttempts`/`otpExpirySeconds`, `maxNegativeDriverBalance`.
- **Soft-delete convention** — `deletedAt`: `User, Customer, Vendor, Product, Driver, Order, Message`.
  Auto-filtered by `PrismaService.$extends` for `findUnique/findFirst/findMany/count`; **raw SQL must
  add `deletedAt IS NULL` by hand** (see `LocationRepository.findNearbyDrivers`).
- **Optimistic concurrency** — `Product.version`, `ProductVariant.version`, `Driver.version`
  (default 100); repositories compare-and-swap → `CONCURRENT_MODIFICATION` error.
- **DB sequences** — `orders.orderNumber` (`ORD-` + `order_number_seq`) and
  `support_tickets.ticketNumber` (`TKT-` + `ticket_number_seq`) via `dbgenerated(...)`.
- **Snapshot denormalization** — `OrderItem`/`OrderItemOption` copy name/price from the menu at
  order time; `CartItem` supports free-form custom products (CUSTOM_DELIVERY) with null FKs.
- **Geometry (`Unsupported("geometry")`, GiST-indexed)** — `Zone.boundary`, `Address.location`,
  `VendorBranch.location`, `Order.deliveryLocation` (required) + `pickupLocation` (nullable),
  `Driver.lastLocation`, `DriverShift.starting/endingLocation`. `spatial_ref_sys` mirrored from PostGIS.

Aggregates worth knowing:

- **Order** = central hub: typed money snapshot (`subtotal/deliveryFee/driverBonusFee/serviceFee/tax/
  discount/coinsUsed/coinsEarned/grandTotal/upfrontAmount`), status timeline
  (`acceptedAt/preparedAt/driverAssignedAt/pickedUpAt/actualDeliveryTime`), `OrderStatusEvent` history,
  relations to customer/vendor/branch/driver/shift/zone; `OrderType` STANDARD | CUSTOM_DELIVERY | RIDE.
- **Wallets/ledgers** — `DriverWalletTransaction`/`VendorWalletTransaction` always store
  `balanceAfter` + `referenceId`; mobile-wallet top-ups (`MobileWallet.isPlatform` + admin-approved
  `WalletTopUpRequest`) clear driver debt (`hasUnpaidCommission` blocks dispatch).
- **Shifts** — `ShiftPool` (zone/date/window/maxDrivers) → `DriverShift` (scheduled vs actual,
  dispatch-health counters `expiredDispatches/rejectedDispatches/warningSent`) → `ShiftSwapRequest`
  (`driverShiftId @unique`).
- **Stats** — `{Vendor,Driver,App}Statistic` upserted per `@unique([owner, period, startDate])`;
  driver stats track the dispatch funnel + `onlineHours`.
- **Chat/tickets** — `Conversation` polymorphic (ORDER/SUPPORT/VENDOR); `SupportTicket.conversationId
  @unique` links each ticket to a conversation; SLA via `lastStatusUpdateAt`+`escalatedAt` cron.
- **Marketing** — `Promotion` (BANNER/VENDOR/PRODUCT/EXTERNAL_LINK/POPUP/NOTIFICATION) + `Offer`
  (product price offer). No `Announcement` model: announcements are `Notification`s
  (`NotificationType.ANNOUNCEMENT`).
- **Auth** — `Session.hashedRt` + Redis revoke; `Account` = social identities
  (`@@unique([provider, providerAccountId])`); `Device` holds unique FCM tokens.

Gotchas: `PaymentMethod` = CASH_ON_DELIVERY | MOBILE_WALLET only (no gateway; `PaymentStatus.PAID`
set after manual confirmation); `User.email/phone` stay `@unique` after soft-delete (deleted users'
credentials can't be re-registered without a partial unique index); `Order`→customer/vendor/driver are
**restrict** (no cascade) so deletes go through soft-delete; driver rating is `Int 0-1000` (×100) while
vendor rating is `Float 0-5`.

### 2.10 Feature modules at a glance

All under `src/features/<name>/`. Guard shorthand in this table: any authenticated = bare JWT;
`:R` = `@Roles`; `:P` = `@RequirePermissions`; `:VM` = `@VendorMember`. Processors marked *worker*
are registered only in `WorkerModule`, never in their feature module.

| Module | Role & key endpoints | Guards / deps | Notable behavior / pitfalls |
|---|---|---|---|
| `audit-logs` | GET `audit-logs` (only endpoint) — role-scoped: VENDOR_MEMBER→own vendor, ADMIN→`VIEW_AUDIT_LOGS`, SUPER_ADMIN→any; filters `userId/entityType/entityId/actionType` | `@Roles` SUPER_ADMIN/ADMIN/VENDOR_MEMBER | Write path fully async: `AuditLogInterceptor` → `audit.log.created` → `audit-log.processor` (*worker*, concurrency 20). `entityType` derived from controller class name; `oldValues` never populated; GETs never logged; no worker process ⇒ no audit rows |
| `auth` | 10 `/auth` routes (register/login/OTP/social refresh/logout) | — | See §2.8; `users` owns profile, `devices` owns FCM tokens |
| `cart` | Cart CRUD incl. free-form custom products (CUSTOM_DELIVERY); coin **SPENT** ledgers at order creation | class `@Roles(CUSTOMER, SUPER_ADMIN)` | Cleared on `ORDER_CREATED` (cart listener); coins refunded on cancel (`orders-state.service`) |
| `chat` | `@Global`; conversations / messages / media services; inbox facade | imported by orders, dispatches | Socket emits + batched `CHAT_MESSAGE` notifications; `Conversation` polymorphic (ORDER/SUPPORT/VENDOR) |
| `customers` | Self: addresses (raw-SQL PostGIS), favorites toggle, coins history. Admin (`MANAGE_CUSTOMERS`): list/by-user/detail, enable/disable-ordering, hard delete (cascade) | addresses: 4-role `@Roles`; admin: `:P` | `assertCanOrder` gates checkout. No self profile endpoints (users module). Address creation does **no zone validation** |
| `devices` | Push-token register/unregister for FCM | any authenticated | Consumed by push + notifications |
| `dispatch` | Driver search (radius expansion per settings), `OrderDispatch` lifecycle | — | `DispatchProcessor` (*worker*); Redis `otlobegy:dispatch:*` states; emits/cancels with order events |
| `driver-shifts` | Shift pools / assigned shifts / swap requests | imports `PlatformSettingsModule` + `NotificationsModule` | Crons: `shift_warning` (30-min), `late_check` (5-min), auto-complete + force-offline at end; tier bonuses read from settings |
| `drivers` | Profile, verification, vehicle, status/suspension, active order | imports `AuthModule` + `SocketModule` | `DriversProcessor` (*worker*); driver rating `Int 0-1000` (×100) |
| `inbox` | Conversation listing + unread counts | — | Thin facade over `@Global` chat services |
| `notifications` | `@Global`; list / unread-count / read (one-all) / delete; admin announcements (FCM topic) | announcements: `:P MANAGE_ANNOUNCEMENTS` | Socket emit `notification.new`; `NotificationSetting` gates **push only** — stored row + socket always. `retentionNotificationsDays` has **no cleanup cron** |
| `offers` | Variant-level price offers; public active + admin CRUD | public; admin `:P MANAGE_PROMOTIONS` | Read-time activation only (variant/product/vendor active gates incl. manual `deletedAt` filters); no scheduler; create has no `isActive` |
| `orders` | Checkout (zone check, coins, fee estimate via `POST /orders/fee-estimate` + `/custom-fee-estimate`), state machine + payment, readiness | — | Monitors: `delivery_watchdog`, `auto_cancel_pending`, unsettled-order monitor; `OrdersProcessor` (*worker*); dispatch moves `ORD-*` via DB sequence |
| `otp` | OTP request/verify | — | `maxOtpAttempts`/`otpExpirySeconds` from settings |
| `platform-settings` | `@Global`; singleton `id='default'`. `/public` handshake + `/app-version-check` (semver gate); PATCH whitelist ~130 knobs; home-cover + vehicle icons | public / admin `:P MANAGE_SETTINGS` | 1h cache invalidated on writes. `calculateDeliveryFee` used by `orders-checkout.service.estimateOrder` (vendor→customer PostGIS distance) and `estimateCustomOrder` (pickup→dropoff). Per-vehicle `pricePerKm*` + `min/maxDeliveryFee*` + `baseDeliveryFee` + `minDistanceFixedPrice` + `minOrderKm` control pricing. **`maxNegativeDriverBalance` in DB but no DTO/API to set it** |
| `promotions` | Public active list; admin CRUD + image | public / admin `:P MANAGE_PROMOTIONS` | `PromotionType` stored but **never branched on** (client-side semantics). `promotion_check` hourly cron (*worker*) handles date-window activate/expire |
| `reviews` | Submit for DELIVERED order (once), vendor public list, driver self / admin (`MANAGE_DRIVERS`) | submit: `@Roles(CUSTOMER)` | Listener recomputes rating aggregates on each submit: vendor `Float 0-5`, driver `Int ×100`, default **500** when none. Pre-check non-atomic (DB unique is the backstop → raw P2002 on race) |
| `statistics` | `@Global`; endpoint series by period (`VendorMember`/DRIVER/`VIEW_STATISTICS`/`MANAGE_DRIVERS`), driver/customer/vendor/product leaderboards (`VIEW_STATISTICS`) | imports PlatformSettings + Socket | `settleOrder` (§2.4 step 5); `recordCancellation` + dispatch counters; retention crons (audits 01:50, wallets 02:00, stats 02:10); **no CSV/PDF/export anywhere**; `STATS_JOBS.UPDATE_*` have no producers |
| `tickets` | Support tickets + admin routing; SLA watchdog | — | `SupportTicket.conversationId @unique` links to chat |
| `users` | Admin/user management, profile, soft-delete | permission-scoped | `User.email/phone` unique persists after soft-delete |
| `vendors` | Branches (PostGIS zone containment), members (OWNER writes, `FOR UPDATE`, last-owner guard), discovery/search + cache, `mapVendorForApp` | — | `cron.vendor_schedule` every 5 min; `VendorsProcessor` (*worker*); slug gen incl. Arabic fallback |
| `wallet` | Driver top-up (receipt upload → PENDING → admin review: credit + unsuspend + `DRIVER_STATUS_CHANGED 'UNPAID_COMMISSION_SETTLED'`), manual vendor/driver adjustments (type normalization, signed amounts), platform receiving wallets, ledgers | admin: `:P MANAGE_FINANCE`; driver `@Roles(DRIVER)`; vendor `:VM OWNER/MANAGER` | No PDF (receipt = uploaded image). Manual transactions have **no `FOR UPDATE` and no idempotency key** → double-submit double-credits |
| `zones` | CRUD boundary (GeoJSON→PostGIS `ST_GeomFromGeoJSON`), `check-location` → **smallest** active zone, customers-in-polygon search | admin `:P MANAGE_SETTINGS`; **GET `/zones` unauthenticated** | Catch-all → `INVALID_BOUNDARY`. **No overlap validation** (`OVERLAPPING_ZONE` defined, unused). `updateZone` boundary + fields non-atomic |

### 2.11 Cross-cutting pitfalls (from the features dive)

1. **Statistics settlement is not end-to-end atomic** — wallet writes are idempotent via `orderId+type`
   (`statistics.service.ts:544-549`), but the 12 stat upserts are **not** guarded; a partial failure +
   BullMQ retry double-counts stats while keeping wallets correct. Coin `EARNED` has **no row lock**.
2. **Manual wallet transactions** (`wallet.service.ts:252-308`) skip `FOR UPDATE` + idempotency keys and
   have no negative-balance guard — admin double-submit double-credits.
3. **Soft-delete window** — the `$extends` filter covers only top-level Prisma calls; raw SQL and
   relation-level `where` (e.g. offers) must re-add `deletedAt IS NULL` by hand. `findUnique` is
   **remapped to `findFirst`** — a unique query on a non-unique field can silently match a wrong row.
4. **Zone overlaps are silently allowed** (smallest-area-first resolves at query time);
   `updateZone`'s geometry + scalar writes aren't one transaction.
5. **Timezone** — period bucketing uses server-local time against `@db.Date` columns
   (`statistics.repository.ts:19-75`): buckets shift if the host isn't in Egypt.
6. **Dead-but-wired affordances** — `ARCHIVE_ORPHANS` never scheduled; `STATS_JOBS.UPDATE_*` have no
   producers; audit `oldValues` never written; notifications `retentionNotificationsDays` has no cron;
   `PromotionType` never branched on; `maxNegativeDriverBalance` not API-editable.
7. **Perf** — leaderboards are N+1 (`statistics.repository.ts:240-336`); `getTopVendors` reads DAILY
   stats only while customer/product use live orders; 12 concurrent upserts per settlement.
8. **Exposure** — `GET /zones` is unauthenticated vs `GET /zones/:id` needing MANAGE_SETTINGS;
   `/platform-settings/public` leaks full per-vehicle pricing + bonus economics; promotions/offers
   public endpoints expose vendor/product names.

---

## 3. Flutter side

### 3.1 Dependency / DI flow

Apps → `packages/data` repositories (one `Provider<Repo>` per generated API, `packages/data/lib/providers.dart`)
→ `packages/api` generated client (`Api(dio:, serializers: standardSerializers)`, 29 `getXxxApi()` getters)
→ `packages/core` infra (`DioClient`, `AuthInterceptor`, `TokenService`, `CoreSocketService`, push, env)
→ HTTP REST to backend, Socket.IO to WS process.

**Exception:** the **customer app owns its own network stack** (`apps/customer/lib/core/network/*`,
`token_service.dart`, `socket_service.dart`) and imports `package:core` with
`hide tokenServiceProvider`. It still uses data/api/ui_kit and core's `unauthenticatedEventStream`,
`ApiErrorMapper`, push, etc. Driver + vendor apps use core's shared stack directly.

### 3.2 packages/core

- `DioClient` (15s timeouts) + `AuthInterceptor` (guest paths `/auth/login|refresh|register|social|verify/*|password/*`,
  terminal `/auth/logout`, single-flight refresh via `Completer`, emits `unauthenticatedEventStream` on 401).
- `TokenService` — secure-storage keys `access_token|refresh_token|user_id|user_role|user_name|vendor_memberships|user_permissions`.
- `CoreSocketService` — per-event broadcast StreamControllers, `onEvent(SocketEvent)`, token-refresh preflight,
  reconnect on resume/connect-error.
- `PushNotificationService` — FCM + local notifications (`high_importance_channel`), token register/unregister
  via `DevicesPushNotificationsApi`, role topics `topic_all` + `topic_customers|drivers|vendors|admin`.
- `EnvConfig.init()` requires `API_URL` + `WS_URL` (loaded via `dotenv`, per-app `.env`).
- Providers: `core_providers.dart` (secureStorage, baseUrl, dioClient, dio, apiClient, tokenService,
  coreSocketService, permissionService, coreLocationService, pushNotificationService, mediaConfigService)
  + `api_providers.dart` (per-API providers).
- L10n assets under `packages/core/assets/translations` via EasyLocalization.

### 3.3 packages/data

- Repos under `lib/src/{admin,customer,driver,shared,vendor}/`; pattern: call generated client
  controller method → `ResponseParser.parse/parseList` (unwrap `ApiResponseDto` envelope).
- Shared riverpod providers: `SharedChatProvider` (family by `SharedChatArgs(id,type)`), `SharedInboxProvider`,
  `SharedInboxCountsProvider` (classic Notifier), `SharedNotificationSettingsProvider` — keepAlive codegen.
- `PaginatedResult<T>` (`items/total/page/limit/totalPages`).

### 3.4 packages/ui_kit

Presentation only (no networking/business logic): `AppTheme.lightTheme/darkTheme` (primary `#D4920E`),
`PrimaryButton`, `CustomTextField`, `DialogScaffold`, `SkeletonLoader`, `OtpInput`, `EmptyState`,
`TimeFormatter`, `ChatBubble`, `InboxConversationTile`, `ChangePasswordDialog`, `DeleteAccountDialog`, `validators`.

### 3.5 Apps at a glance

**Customer** (`apps/customer`, own network stack) — Riverpod codegen + GoRouter (19 routes;
`route_names/paths` only cover the 8 auth/splash routes — router uses inline names).
Screens: onboarding, auth (no social yet), home (vendors/offers/promos/categories/search), vendor detail +
product bottom sheet, cart + checkout (cash / mobile-wallet, coins, live fee estimate from `POST /orders/fee-estimate`),
order tracking (wallet pay-confirm, rating, support chat), custom delivery + ride (live estimate from `POST /orders/custom-fee-estimate`),
profile/addresses/coins,
notifications, chat/inbox. Realtime via `core/providers/global_order_listener.dart`
(order.status/updated, FCM, resume refetch) and `global_message_listener.dart`
(OFFER chat metadata → global bottom sheet).

**Driver** (`apps/driver`, shared stack) — Riverpod codegen + codegen GoRouter + hand-written l10n
(`lib/l10n/app_localizations{,_en,_ar}.dart`), **dark + Arabic defaults**. Splash → dashboard | active order;
root `global_message_listener.dart` shows dispatch modal on `dispatch.incoming`, heartbeat polling fallback,
re-check on reconnect; `OrderExecutionProvider` handles status updates; location service emits
`driver.location` (client). Features: dashboard, dispatch modal, order execution (flutter_map), shifts
(pools/swap), wallet (top-up), deliveries history, chat (voice), profile/vehicle, notifications.

**Vendor admin** (`apps/vendor`, shared stack) — entry+router+app shell all in `main.dart` (`OtlobAdminApp`);
GoRouter only for splash/login/select-vendor/dashboard; the rest is an **IndexedStack dashboard** with
~18 permission-gated sections (orders, vendors, drivers, users, tickets, inbox, settings, zones, verticals,
promotions, wallet + PDF export, audit logs, announcements, access control, driver shifts, analytics, notifications).
Role-aware repo selection (`admin*` vs `vendor*`), `activeVendorProvider` context switcher for VENDOR_MEMBER,
`global_order_listener.dart` for realtime order rows, ARB-generated l10n (`flutter gen-l10n`, do not hand-edit).

---

## 4. Regenerating `packages/api` (THE critical workflow)

`.agents/AGENTS.md` mandates: when backend DTOs/endpoints/enums/response models change,
**do not manually touch `packages/api`**. Ask the user to restart the backend so `/docs-json`
is fresh, then:

1. Export spec → `docs.json` (backend writes it via `src/generate-swagger.ts`).
2. Regenerate client from `docs.json` using OpenAPI Generator **dart-dio + built_value**
   (handled by the team; generator-patched, `test/**` ignored, version 7.23.0).
3. `dart run build_runner build -d` for `.g.dart` parts in core/data/apps.
4. Update `packages/data` repos, then apps.

`docs.json` (193 paths) is the live generator input; root `swagger.json` (184 paths) is orphaned/stale.

---

## 5. Environment configuration

`backend/` runs with `.env` in the **backend directory** (`ConfigModule.forRoot({ envFilePath: '.env' })`),
validated strictly by `src/common/config/env.validation.ts`. Live template: **`backend/.env.example`**
(copy it to `backend/.env` and fill in real values).

Required backend keys (all validated, boot fails if missing):

- `NODE_ENV`, `API_PORT`, `WS_PORT`, `APP_NAME`, `LOG_LEVEL`
- `JWT_ACCESS_SECRET`, `JWT_REFRESH_SECRET`, `JWT_ACCESS_EXPIRATION`, `JWT_REFRESH_EXPIRATION`
- `DATABASE_URL` (postgres, e.g. `postgresql://user:pass@localhost:5432/otlob_db?schema=public`)
- `REDIS_URL` (`redis://:password@host:port`); optional `REDIS_CLUSTER_MODE`
- `SMTP_HOST`, `SMTP_PORT`, `SMTP_USER`, `SMTP_PASS`, `SMTP_NAME`
- `FIREBASE_PROJECT_ID`, `FIREBASE_CLIENT_EMAIL`, `FIREBASE_PRIVATE_KEY`
- `GOOGLE_CLIENT_IDS`, `APPLE_CLIENT_IDS` (comma-separated, for web/ios android variants)

Flutter apps load their own `.env` from the app working dir (`dotenv.load('.env')`); driver/vendor require
`API_URL` + `WS_URL` (fail fast in `EnvConfig.init`); customer falls back to `API_URL ?? http://10.0.2.2:3000`.

---

## 6. Adding a feature — convention checklist

**Backend first** (source of truth): new `src/features/<name>/` (controller/service/[repository]/[processor],
DTOs with class-validator, `@ApiStandardResponse(...)` + `_gen` classes, error constants, event/queue registry
entries, Redis keys `otlobegy:*`). Re-export new response models into `docs.json` by restarting backend.

Then Flutter, top-down: `packages/data` repo (+ export in `data.dart`, + provider in `providers.dart`)
→ app provider `@Riverpod(keepAlive: true)`/`@riverpod` with `.g.dart` (build_runner) → screen + route
(customer/driver: GoRouter; vendor: dashboard IndexedStack menu item gated by permission) → localization
(customer/driver: hand-written l10n + `ErrorUtils`; vendor: ARB + `gen-l10n` + `ErrorUtils` switch).

Realtime: subscribe `SocketEvent` via the app's socket service and `ref.invalidate`/refresh the provider
(mirror `global_order_listener.dart` / driver `notifications_provider.dart`).

**Definition of Done** (from `.agents/AGENTS.md`): backend correct → OpenAPI matches → generated api matches →
data consumes it → core reused → ui_kit stays presentation-only → all affected apps updated → no duplicated
logic → no hardcoded values that the backend owns → backend stays single source of truth.

---

## 7. Common commands

```bash
# Backend (from backend/)
npm run start:dev        # API
npm run start:worker:dev # Worker
npm run start:ws:dev     # WS
npm run lint; npm run build; npm test
npx prisma migrate dev   # schema → migration + client regen

# Flutter workspace (from root; melos)
dart run build_runner build -d   # codegen for .g.dart parts (per package/app dir)
flutter gen-l10n                 # vendor app only
melos run analyze                # dart analyze across workspace
melos run format
melos run build:android          # sequential APK builds (mind host RAM — see AGENTS.md §Flutter Build Constraints)
```