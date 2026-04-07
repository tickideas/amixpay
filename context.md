# AmixPay Mobile — Screen & Data Audit

> Generated: 2026-04-07  
> Scope: `apps/mobile/lib/features/` + `apps/mobile/lib/shared/`

---

## Summary

| Category | Count |
|---|---|
| REAL (live API data) | 14 |
| MIXED (API + hardcoded fallback/demo) | 10 |
| DEMO / PLACEHOLDER (entirely static/hardcoded) | 14 |

---

## REAL — Screens that call real API endpoints and display live data

These screens use proper repositories wired to `ApiClient` (Dio) and display server data.

### Auth flows
- **`login_screen.dart`** — Calls `POST /auth/login` via `authRepositoryProvider`. Shows real user session.
- **`register_screen.dart`** — Calls `POST /auth/register`. Detects demo mode only when the server is unreachable in debug builds.
- **`email_verification_screen.dart`** — Calls `POST /auth/verify-email` and `POST /auth/resend-verification`.
- **`splash_screen.dart`** — Reads `SecureStorage` + `authProvider` to decide routing. No hardcoded data.
- **`onboarding_screen.dart`** — Static marketing slides; no data layer interaction. Acceptable as pure UI.

### Profile / Settings
- **`profile_screen.dart`** — Reads `authProvider` (backed by `GET /users/me`). Displays real user name, KYC status, etc.
- **`edit_profile_screen.dart`** — Calls `PATCH /users/me` via `editProfileProvider`. Reads auth state.
- **`kyc_screen.dart`** — Posts to `POST /users/kyc/documents` via `multipart/form-data`.
- **`avatar_upload_screen.dart`** — Uploads via `avatarUploadProvider` (real endpoint).
- **`settings_screen.dart`** — Reads `settingsProvider` (local secure storage) + `authProvider`. No hardcoded data.
- **`notification_settings_screen.dart`** — Reads `settingsProvider`. No mock data.

### Payments
- **`confirm_send_screen.dart`** — Calls `POST /payments/send` via `paymentRepositoryProvider`. Real API.
- **`request_money_screen.dart`** — Form screen. Calls `POST /payment-requests`. No hardcoded content.
- **`send_success_screen.dart`** — Receives real transaction data as route args. No mocks.

---

## MIXED — Screens that call APIs but also have hardcoded demo content

These screens have real API integration but also inject static/fake data as fallback, placeholder, or alongside live data.

### Home
- **`home_screen.dart`**  
  - ✅ Balance pulled from `walletCurrenciesProvider` (SecureStorage + live wallet sync)  
  - ✅ Transactions from `transactionProvider` (persisted locally, populated on real sends/receives)  
  - ✅ Exchange rates from `exchangeRatesProvider` (calls `ip-api.com` + live rate service)  
  - ⚠️ Trust banner hardcodes `"2M+ Transfers"` — marketing copy, not a live stat  
  - ⚠️ Quick Send section shows a placeholder message until real recipients exist; no fake names pre-populated

### Wallet
- **`wallet_screen.dart`**  
  - ✅ Currencies from `walletCurrenciesProvider` (device locale default + user additions, persisted)  
  - ✅ USDT balance from `usdtBalanceProvider`  
  - ⚠️ Exchange rates are hardcoded in `_usdRates` map (static table, not live)  
  - ⚠️ Virtual card shows hardcoded `"•••• •••• •••• 9982"` — not fetched from a card API  

### Payments
- **`zelle_transfer_screen.dart`**  
  - ✅ Sends real payments via `paymentRepositoryProvider`  
  - ✅ Looks up AmixPay users by username via `GET /users/search`  
  - ⚠️ Falls back to `_demoNetworkUsers` list (contains `@sarah.k / Sarah Kim`, `@demo.user`) if API unreachable  

- **`payment_requests_screen.dart`**  
  - ✅ Fetches real requests via `paymentRepositoryProvider.getRequests()`  
  - ⚠️ Hardcoded fallback labels `"Bob Smith"` / `"Alice Johnson"` visible in empty/error state UI

- **`send_money_screen.dart`**  
  - ✅ Reads `walletCurrenciesProvider` for source wallet options  
  - ⚠️ FX rates (`_fxRates`) are a static map inside the widget, not fetched

### Transfers
- **`international_transfer_screen.dart`**  
  - ✅ Calls quote API via `transferQuoteProvider` (`GET /transfers/quote`)  
  - ⚠️ Account name lookup returns a randomly generated fake name from lists of `['James','Maria','Alex','Fatima','David'...]` + `['Johnson','Williams','Okonkwo'...]` — this is **not real** bank account validation

- **`transfer_confirm_screen.dart`**  
  - ✅ Submits to `POST /transfers` (real API intended)  
  - ⚠️ Comment: `"// Generate a mock transfer ID"` — transfer ID is locally generated, not server-assigned

- **`transfer_status_screen.dart`**  
  - ✅ Has `FutureProvider` that loads transfer info  
  - ⚠️ Fallback `recipientName: 'John Smith'` hardcoded when API call fails

### Analytics
- **`spending_analytics_screen.dart`**  
  - ✅ Reads `transactionProvider` for real transactions; builds category breakdown  
  - ⚠️ When no transactions exist, shows `_demoCats` with fabricated amounts: `Food $320, Shopping $520, Transfers $1200, etc.`  
  - ⚠️ Line chart trend also falls back to demo data when all values are zero

### Funding
- **`add_funds_screen.dart`**  
  - ✅ Bank funding: calls `POST /funding/bank-accounts/link-token` (Plaid) and `POST /funding/deposit` (Stripe)  
  - ⚠️ Demo/test card path has no real Stripe SDK — shows a simulated "success" flow

---

## DEMO / PLACEHOLDER — Entirely static/hardcoded

These screens show only fake or static data with no real API integration.

### Admin
- **`admin_dashboard_screen.dart`**  
  - ❌ Entirely hardcoded. `_mockAlerts` list, `_mockUsers` list.  
  - No API calls. Mock users include: `'Sarah Connor'`, `'sarah.c@email.com'`.

- **`fraud_alerts_screen.dart`**  
  - ❌ Hardcoded `final List<_FraudAlert> _alerts = [...]` with fake users:  
    - `john.doe@email.com` — \$8,500 VELOCITY_1HR  
    - `mary.jane@email.com` — \$12,000 LARGE_AMOUNT  
    - `bob.smith@email.com` — €950 NEW_RECIPIENT  
    - `alice.w@email.com` — £4,200 VELOCITY_5MIN  
    - `charlie.b@email.com`, `diana.p@email.com`  
  - No API calls anywhere in this file.

### Notifications
- **`notifications_screen.dart`**  
  - ❌ Hardcoded `final List<_Notification> _items = [...]`  
    - `"Bob sent you $50.00"`, `"You sent $25.00 to Alice"`  
  - Does NOT use `notificationsRepositoryProvider` (which exists and is wired to `GET /notifications`).

### Merchants
- **`merchant_dashboard_screen.dart`**  
  - ❌ Hardcoded transaction: `payer: 'John Smith'`, hardcoded revenue stats. No API calls.

- **`merchant_payments_screen.dart`**  
  - ❌ Hardcoded list: `Alice Johnson — $45.80`, `Bob Smith — $12.00`, etc. No API calls.

- **`checkout_link_screen.dart`**  
  - ❌ Static form. Generates a fake checkout link with no backend integration.

### Crypto
- **`usdt_wallet_screen.dart`**  
  - ❌ USDT balance is a local `StateNotifier` starting at `0.00`. No crypto API.  
  - ❌ Transaction history hardcoded: `'Deposit +100.00 USDT'`, `'Send to 0x4a2b... -50.00 USDT'`, `'Convert to NGN -200.00 USDT'`  
  - ⚠️ Has a `"// Simulate deposit button (demo only)"` comment

### Banking
- **`bank_connection_screen.dart`**  
  - ❌ Account name lookup is entirely fake. Hardcoded specific lookups: `'GB_301500_12345678': 'Sarah Mitchell'`, `'AU_062000_12345678': 'Emily Johnson'`, plus random name generation from static name arrays.  
  - No real bank validation API.

### Bills
- **`bill_payments_screen.dart`**  
  - ❌ `_billCategories` and `_quickAmounts` are hardcoded lists. No API calls for bill providers or payments. Static form only.

### Splits
- **`split_bill_screen.dart`**  
  - ❌ Hardcoded `_items` bill list and `_participants = ['@alice', '@bob', '@charlie']`. No API.

- **`split_detail_screen.dart`**  
  - ❌ Hardcoded shares: `Alice (You) — $5.55 paid`, `Bob Smith — $5.55 paid`. No API.

### Scheduled Transfers
- **`scheduled_transfers_screen.dart`**  
  - ⚠️ Has `scheduledRepositoryProvider` (real API: `GET /scheduled`), but initializes from `_demoScheduled` which is an empty list `<ScheduledTransfer>[]`  
  - The `_transfers` list is `List.from(_demoScheduled)` — effectively local state, not loaded from API on screen mount

### Transactions
- **`transactions_hub_screen.dart`**  
  - ⚠️ Reads `transactionProvider` for real transactions  
  - ❌ Also maintains hardcoded `_txns` list with `'Send to Amara'`, `recipient: 'Amara Johnson'`  
  - These demo transactions are merged with real ones: `// Append demo transactions that don't share an ID with real ones`

### Other Static Screens
- **`transaction_detail_screen.dart`** — Fallback `counterparty: 'John Smith'` when route args missing. Mostly read-only display.
- **`privacy_policy_screen.dart`** — Static legal text. Expected.
- **`terms_of_service_screen.dart`** — Static legal text. Expected.
- **`two_factor_screen.dart`** — `verify2fa` call is commented out (`// await ref.read(authRepositoryProvider).verifyTwoFactor(`). Currently non-functional.

---

## Repository Audit

| Repository | Endpoints | Real or Mock? |
|---|---|---|
| `auth_repository.dart` | `/auth/login`, `/auth/register`, `/auth/verify-email`, `/auth/logout`, `/users/me` | ✅ REAL — demo fallback only in `kDebugMode` when server is unreachable |
| `wallet_repository.dart` | `GET /wallets`, `POST /wallets/currencies`, `GET /wallets/transactions` | ✅ REAL |
| `payment_repository.dart` | `POST /payments/send`, `POST /payment-requests`, `GET /payment-requests` | ✅ REAL |
| `funding_repository.dart` | `POST /funding/bank-accounts/link-token` (Plaid), `POST /funding/deposit` (Stripe) | ✅ REAL |
| `notifications_repository.dart` | `GET /notifications`, `PATCH /notifications/:id/read`, `POST /notifications/read-all` | ✅ REAL — but **not used by notifications_screen.dart** |
| `referral_repository.dart` | `GET /referrals/my-code`, `GET /referrals`, `POST /referrals/apply` | ✅ REAL |
| `savings_repository.dart` | `GET /savings`, `POST /savings`, `POST /savings/:id/deposit` | ✅ REAL |
| `scheduled_repository.dart` | `GET /scheduled`, `POST /scheduled`, `PATCH /scheduled/:id`, `DELETE /scheduled/:id` | ✅ REAL — but scheduled_transfers_screen.dart doesn't call it on mount |
| `user_cards_provider.dart` | None — local `SecureStorage` only | ❌ LOCAL — no card issuance API |
| `saved_cards_provider.dart` | None — local `SecureStorage` only | ❌ LOCAL — no Stripe saved cards API |
| `wallet_provider.dart` (shared) | Delegates to `wallet_repository.dart` | ✅ REAL |
| `auth_provider.dart` (shared) | Delegates to `auth_repository.dart` | ✅ REAL |
| `transaction_provider.dart` (shared) | Local `SecureStorage` (populated by send/receive flows) | ⚠️ LOCAL — no independent API fetch |
| `settings_provider.dart` (shared) | Local `SecureStorage` only | ⚠️ LOCAL — not synced to backend |

---

## Key Issues to Address

1. **`notifications_screen.dart`** uses its own hardcoded list instead of `notificationsRepositoryProvider` — easy fix, the repository is already implemented.

2. **`transactions_hub_screen.dart`** appends hardcoded `_txns` (including `Amara Johnson`) to live data — demo data will appear in production.

3. **`fraud_alerts_screen.dart`** and **`admin_dashboard_screen.dart`** are 100% mock data — no admin API layer exists.

4. **`usdt_wallet_screen.dart`** has a local-only balance counter with hardcoded history — no crypto/blockchain API.

5. **`bank_connection_screen.dart`** generates fake account names — no real bank name lookup API. This could mislead users into thinking their bank account was verified.

6. **`two_factor_screen.dart`** — the actual 2FA verification call is commented out, making 2FA non-functional.

7. **`split_bill_screen.dart`** and **`split_detail_screen.dart`** — no splits API exists at all.

8. **`merchant_dashboard_screen.dart`** and **`merchant_payments_screen.dart`** — no merchant API; merchants see completely fake data.

9. **`wallet_screen.dart`** — exchange rates (`_usdRates`) are a hardcoded static table, not live rates. The real rate service is only used in `home_screen.dart`.

10. **`user_cards_provider.dart`** — card management is entirely local (SecureStorage), with hardcoded card number `9982`. No card issuance or management API.
