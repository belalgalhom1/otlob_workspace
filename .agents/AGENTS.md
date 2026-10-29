# Otlob Monorepo Development Rules (Read Before Every Task)

You are working inside the Otlob monorepo.

Your primary objective is to preserve the architecture and ensure the backend remains the **single source of truth**. Never implement shortcuts, duplicate business logic, or introduce inconsistencies between layers.

For a how-it-works reference of the whole stack (backend processes, order lifecycle, events/queues/sockets, Flutter packages/apps, API regeneration workflow, env config), read `docs/ARCHITECTURE.md`.

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


---

# Mandatory Professional UI/UX and Visual Quality Standards

Treat visual quality as a core requirement, not an optional enhancement. Every new feature, screen, component, dashboard section, table, chart, dialog, and PDF report must look polished, consistent, modern, and production-ready.

Work with the mindset of a senior UI/UX designer and senior Flutter engineer. Do not simply make the feature functional; make it feel like a professionally designed commercial product.

### 1. Visual Hierarchy and Composition
- Establish a clear visual hierarchy so users can immediately distinguish page titles, section headings, important metrics, supporting information, and secondary actions.
- Use balanced layouts, consistent alignment, intentional whitespace, and predictable content grouping.
- Avoid crowded screens, oversized empty spaces, unnecessary decoration, and inconsistent component sizing.
- Make important financial figures and operational alerts easy to identify without making the interface visually noisy.
- Ensure that every element has a clear purpose and contributes to usability.

### 2. Spacing, Typography, and Letter Spacing
- Apply a consistent spacing system across the entire feature, including page margins, card padding, gaps between sections, spacing between text and icons, and distances between interactive elements.
- Pay close attention to typography: font family, font size, font weight, line height, letter spacing, text alignment, and text wrapping.
- Use letter spacing intentionally and sparingly. Do not apply arbitrary spacing between Arabic letters, because it can damage Arabic typography and readability.
- Ensure Arabic text is properly shaped and connected, with correct RTL direction and natural word spacing.
- Prevent clipped text, awkward line breaks, inconsistent baselines, overlapping labels, and misaligned numbers.
- Use tabular or consistently aligned numerals for financial figures where supported.

### 3. Icons and Interactive Elements
- Use a consistent icon library and visual style throughout the interface.
- Keep icon sizes, stroke weights, alignment, and spacing consistent.
- Ensure icons are properly centered and aligned with their labels.
- Maintain comfortable spacing between icons, text, buttons, and adjacent components.
- Avoid mixing unrelated icon styles, using random emoji as interface icons, or adding decorative icons without a clear purpose.
- Use clear labels for actions that might otherwise be ambiguous.
- Ensure buttons, dropdowns, filters, tables, dialogs, and export controls have consistent sizing and interaction states.

### 4. Design System Consistency
- Inspect and reuse the project's existing theme, colors, typography, spacing conventions, reusable components, and design tokens before introducing anything new.
- Follow the existing brand identity and color palette rather than inventing an unrelated visual style.
- Reuse shared components where appropriate and create reusable components for genuinely repeated patterns.
- Maintain consistent corner radii, borders, shadows, card treatments, and elevation.
- Use color meaningfully for financial states, warnings, success, and errors, while preserving sufficient contrast and accessibility.
- Avoid excessive gradients, shadows, borders, animations, or decorative effects.
- Do not redesign unrelated parts of the application merely to complete this task.

### 5. Professional Dashboard and Data Visualization
- Design KPI cards, charts, financial summaries, filters, and tables as a cohesive analytics experience.
- Choose appropriate chart types for the data and provide readable labels, legends, units, and tooltips where useful.
- Avoid misleading scales, unnecessary chart decoration, overcrowded labels, and colors that are difficult to distinguish.
- Make financial values, commission status, outstanding debt, earnings, and payouts visually distinct without confusing their meanings.
- Ensure tables have consistent row heights, column alignment, readable headers, clear totals, and usable horizontal or responsive layouts.
- Provide polished loading, empty, error, and permission-denied states.
- Do not display fake data, placeholder metrics, or decorative charts that imply information the backend does not provide.

### 6. Premium PDF Report Design
- Apply the same design discipline to exported PDF reports as to the application interface.
- Create a refined document layout with a clear hierarchy, balanced margins, consistent typography, professional tables, and well-organized financial summaries.
- Maintain consistent spacing between sections, headings, charts, tables, and explanatory notes.
- Ensure that Arabic letters remain connected and correctly aligned, and that mixed Arabic and English content renders correctly.
- Prevent clipped columns, overlapping text, awkward page breaks, orphaned headings, and unreadable transaction tables.
- Repeat table headers across pages where needed, align financial values consistently, and keep totals visually clear.
- Ensure the PDF remains professional when printed, not just when viewed on a screen.

### 7. Responsive Layout and Accessibility
- Verify that layouts work at the screen sizes and window widths supported by the existing application.
- Prevent overflow, broken layouts, clipped buttons, and overlapping content.
- Respect RTL and LTR direction wherever applicable.
- Maintain readable contrast, practical touch targets, and clear interaction feedback.
- Support long Arabic and English names, large currency amounts, and different date formats without breaking the layout.

### 8. Required Visual Review Before Completion
Do not finish immediately after writing the code.

After implementation:
1. Run the application or the relevant screen using the available development environment.
2. Inspect the actual rendered interface and exported PDF whenever the environment allows it.
3. Review spacing, alignment, typography, icon consistency, text overflow, chart readability, and overall visual balance.
4. Fix visible design defects rather than leaving them for the user.
5. Test different data lengths, empty states, loading states, error states, and RTL rendering.
6. Run the relevant formatting, analysis, tests, and build checks.
7. If visual inspection is not possible, clearly state that limitation instead of claiming that the interface was visually verified.

### Definition of Done (UI/UX)
The feature is complete only when both its functionality and its visual quality are acceptable.

The result must feel like a coherent, premium, production-ready application designed by an experienced product team—not a collection of quickly assembled widgets.

Prioritize clarity, consistency, spacing, typography, alignment, usability, and financial accuracy over unnecessary visual effects. Preserve the existing architecture and design system, and avoid unrelated refactoring.
