# Otlob Monorepo Development Rules (Read Before Every Task)

You are working inside the Otlob monorepo.

Your primary objective is to preserve the architecture and ensure the backend remains the **single source of truth**. Never implement shortcuts, duplicate business logic, or introduce inconsistencies between layers.

---

# Architecture (Strict Dependency Hierarchy)

The project follows this dependency chain and it must never be violated:

```text
Backend (Ultimate Source of Truth)
        ↓
OpenAPI (/docs-json)
        ↓
packages/api (Generated)
        ↓
packages/data
        ↓
packages/core
        ↓
packages/ui_kits
        ↓
Flutter Applications
    • Customer App
    • Driver App
    • Vendor Admin App
```

Every layer depends only on the layer above it.

No lower layer should redefine or duplicate logic owned by a higher layer.

---

# Backend is the Ultimate Source of Truth

Before implementing any feature, bug fix, or refactor, fully analyze the backend.

Inspect everything related to the feature, including:

* Prisma schema
* Models
* DTOs
* Controllers
* Services
* Guards
* Permissions
* Roles
* Enums
* Validation rules
* Business logic
* State machines
* Sockets/events
* Response constants
* Existing APIs
* Existing tests (if present)

Never assume how something works.

If the backend already defines behavior, the frontend must follow it exactly.

If something is missing, implement it in the backend first rather than inventing frontend behavior.

---

# Perform a Complete Impact Analysis First

Do **not** immediately start modifying files.

Before writing code:

1. Analyze the complete feature.
2. Determine every affected backend module.
3. Determine every affected generated API model.
4. Determine every affected repository.
5. Determine every affected provider/service.
6. Determine every affected UI.
7. Determine every affected application.
8. Verify whether reusable infrastructure already exists.

Think through the entire dependency chain before making changes.

Never patch only one file when multiple layers must remain synchronized.

---

# API Generation Workflow

The backend already exposes the OpenAPI specification:

https://api.otlob-egy.online/docs-json

Do **not** manually generate Swagger.

Whenever backend DTOs, endpoints, enums, or response models change:

Stop and ask me to restart the backend.

Do not regenerate packages/api until I confirm the backend has restarted.

After confirmation:

1. Regenerate packages/api from /docs-json.
2. Apply our known generator patches (if required).
3. Regenerate generated files.
4. Continue updating dependent packages.

Never skip this workflow.

---

# packages/api

packages/api is generated from OpenAPI.

Never manually implement business logic here.

Never manually create DTOs that already exist in the generated API.

If a generated model exists:

* Use it.
* Do not manually decode JSON.
* Do not use raw Map<String, dynamic>.
* Do not duplicate models.

Only apply our required generator compatibility patches when necessary.

---

# packages/data

packages/data is responsible for:

* repositories
* remote data sources
* local data sources
* caching
* mapping generated API models into domain models

Business rules should not live here unless they are directly related to data persistence or transformation.

---

# packages/core

packages/core contains shared application infrastructure.

Examples include:

* authentication
* permissions
* networking
* localization
* routing
* storage
* shared providers
* reusable services
* utilities
* common business helpers

Before creating anything new:

Search packages/core first.

If functionality already exists:

Reuse it.

Do not duplicate it.

---

# packages/ui_kits

packages/ui_kits contains reusable presentation components only.

It should never contain:

* networking
* repositories
* business logic
* backend rules
* feature-specific logic

Keep it presentation-only.

---

# Flutter Applications

There are only three Flutter applications:

* Customer App
* Driver App
* Vendor Admin App

The Vendor Admin App is shared by multiple backend roles.

Do not treat Vendor and Admin as separate applications.

The backend determines access using roles and permissions.

Supported backend roles include:

* CUSTOMER
* DRIVER
* ADMIN
* SUPER_ADMIN
* VENDOR_MEMBER

The Vendor Admin App must adapt automatically based on backend roles and permissions.

Never hardcode role behavior inside Flutter.

---

# Roles & Permissions

The backend is the authority for:

* roles
* permissions
* vendor member roles
* authorization
* feature availability

Flutter may hide or disable UI for better UX, but authorization always belongs to the backend.

Always inspect backend guards and permissions before implementing frontend behavior.

---

# Hardcoded Values

Assume every hardcoded value is incorrect until proven otherwise.

Always search the backend first.

Examples include:

* fees
* taxes
* commissions
* maintenance mode
* feature flags
* approval settings
* coin settings
* version requirements
* limits
* distances
* delivery settings
* ride settings
* custom delivery settings
* order timeouts
* dispatch settings

If the backend owns the value:

Remove the hardcoded value.

---

# API Responses

Backend response constants are the canonical source for API response codes and localized error messages.

Before introducing new response handling in Flutter:

Inspect packages/core.

If packages/core already provides API error handling, localization, or response mapping:

Reuse it.

Do not create duplicate response constants or duplicate translation layers.

Only update Flutter if new backend responses require support.

---

# Existing Infrastructure First

Never build new infrastructure before checking for existing implementations.

Always search for:

* providers
* repositories
* services
* controllers
* mixins
* extensions
* utilities
* widgets
* generated API methods
* generated DTOs

Prefer extending existing architecture instead of creating parallel implementations.

---

# Feature Implementation Rules

For every feature:

* Follow backend behavior exactly.
* Use generated API models.
* Update packages/data if needed.
* Update packages/core only when shared functionality changes.
* Update packages/ui_kits only for reusable UI.
* Update Flutter applications last.

Never skip layers.

Never duplicate logic.

Never introduce inconsistent behavior between apps.

---

# Code Quality

Always:

* Reuse existing code before writing new code.
* Keep implementations consistent across the monorepo.
* Prefer composition over duplication.
* Keep changes minimal and architectural.
* Maintain backward compatibility unless intentionally changing the backend contract.
* Follow existing naming conventions.
* Follow existing project patterns instead of inventing new ones.

---

# Definition of Done

A task is **not complete** until you verify:

* Backend implementation is correct.
* OpenAPI contract matches the backend.
* Generated API matches the OpenAPI contract.
* packages/data correctly consumes the generated API.
* packages/core reuses existing shared infrastructure.
* packages/ui_kits remains presentation-only.
* Customer App is updated if affected.
* Driver App is updated if affected.
* Vendor Admin App is updated if affected.
* No duplicated business logic exists.
* No unnecessary hardcoded values remain.
* The backend remains the single source of truth throughout the entire stack.


# Flutter Build Constraints (Memory Management)
When assisting with or debugging Flutter builds (lutter build apk, ppbundle, etc.) in this workspace:
- Be aware that the host machine has limited physical memory (~3.7GB available).
- Ensure ndroid/gradle.properties uses conservative JVM arguments to prevent OOM kills (e.g., org.gradle.jvmargs=-Xmx2G -XX:MaxMetaspaceSize=1G -XX:ReservedCodeCacheSize=512m).
- If a build fails with a "daemon disappeared" or JVM crash log, instruct the user to run ./gradlew --stop to kill zombie daemons before retrying.
