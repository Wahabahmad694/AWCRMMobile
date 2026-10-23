# AWC implementation status

The missing business modules use the public Swagger contract at https://aw-crm-mu.vercel.app/api/docs/openapi.json, inspected on 2026-10-24. The running app starts from `lib/main.dart` and uses `RouteGenerator`, `AuthRepository`, and `AppDrawer`; `lib/app/app.dart` is an older, separate entry point.

## Integrated foundation

- `API_URL` defaults to `https://aw-crm-mu.vercel.app/api/v1`; override with `--dart-define=API_URL=...`.
- Full **Sign In and Account Management** integrated:
  - `POST /auth/login`: Email or phone + password authentication.
  - `POST /auth/register`: Account & initial organization creation.
  - `POST /auth/refresh`: Sequential rotation using Dio `QueuedInterceptor` (`AuthInterceptor`).
  - `POST /auth/logout`: Revocation & local token cleanup.
  - `GET /auth/me`: User profile, organization, and permissions.
  - `POST /auth/password/forgot`: Reset instructions dispatch.
  - `POST /auth/password/reset`: Password update with verification token.
  - `POST /auth/password/change`: In-app password change for authenticated users.
  - `GET /auth/sessions`: Active device & session list.
  - `DELETE /auth/sessions/{sessionId}`: Targeted session revocation.
- Dio `AuthInterceptor` attaches `Authorization: Bearer <access>` and `X-Organization-Id` headers.
- Rotating refresh tokens use secure storage on mobile and in-memory/session on web; access tokens remain in-memory.
- Structured errors retain `code`, `details`, `request_id`, and `Retry-After`. `ApiErrorBanner` displays request IDs and supports one-tap or long-press clipboard copying for support logs.
- Subscription read-only enforcement: suspended/expired subscriptions or 403 `subscription_required` display a prominent workspace banner and switch UI state to read-only.
- Idempotency & versioning: `generateIdempotencyKey()` (RFC 4122 v4 UUID) and `expected_version` support in API client.
- Integer paisa arithmetic (`parsePaisa`, `rupees`, `formatPkr`) and Karachi time zone date formatting (`formatKarachiDate`).

## Remaining work

- Implement typed business mutation forms for customers, products, inventory, orders, payments, targets, reports, expenses, activities, and team.
- Complete AI conversation protocol, in-app notifications polling (`/notifications/unread-count`), and file exports (`/exports/orders.csv`).
- Confirm CORS origin for local Flutter web and production hosting.

## Local run

For local web: `flutter run -d chrome --web-port 5000 --dart-define=API_URL=http://localhost:3000/api/v1` and allow `http://localhost:5000` in backend `CORS_ORIGINS`.

For Android emulator: `flutter run --dart-define=API_URL=http://10.0.2.2:3000/api/v1`.

The UI preview button remains available without a backend. Preview is clearly labeled and does not show fabricated business data.


## AWC launch and business modules

- Display name changed to AWC on mobile, desktop, and web. Package IDs and existing authentication storage keys are retained.
- The animated line splash restores the session while it plays. First-time signed-out users see one onboarding screen, then login. The onboarding flag survives sign-out; returning authenticated users go to their workspace.
- The active drawer includes Leads, Quotations, Returns, Credit notes, Cash and bank, and Imports.
- Leads: paginated search, source filters, details, create/edit, stage movement, conversion, archive/restore.
- Quotations: status filters, details, customer/lead selection, product or custom lines, dates, discounts/tax, create/edit, send/accept/reject, conversion, duplication.
- Returns: status filters, fulfilled-order selection, returnable quantities, reason/restocking/resolution, draft creation, completion and cancellation.
- Credit notes: status filters, details and applications, credit application to customer orders, voiding unused notes with a reason.
- Cash and bank: balances, account creation/editing, activation, paginated account book, transfer recording/history and dated daily summary.
- Imports has an explicit unavailable screen: the published Swagger contract has no import endpoints. No upload is sent to a guessed endpoint.
- New forms preserve their inputs after errors, send integer paisa amounts, use current record versions where required, and reuse an idempotency key for retries with unchanged payloads.
- Automated coverage uses mocked API responses; authenticated production mutations have not been exercised.
