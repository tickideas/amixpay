# Removed Features — Testing Phase Cleanup

> Date: 2026-04-07
> Purpose: Track screens and features removed during testing-phase cleanup.
> All removed code was 100% placeholder/demo with no real API integration.
> Re-add these features incrementally when their backend APIs are production-ready.

---

## Screens Removed (100% Placeholder)

### Admin Module
| File | What it showed | Why removed |
|------|---------------|-------------|
| `features/admin/presentation/admin_dashboard_screen.dart` | Fake admin panel with mock users (`Sarah Connor`, `sarah.c@email.com`) and hardcoded stats | No admin API exists |
| `features/admin/presentation/fraud_alerts_screen.dart` | Hardcoded fraud alerts (`john.doe@email.com $8,500`, `mary.jane@email.com $12,000`, etc.) | No fraud detection API exists |

### Merchant Module
| File | What it showed | Why removed |
|------|---------------|-------------|
| `features/merchants/presentation/merchant_dashboard_screen.dart` | Fake revenue stats, hardcoded payer `John Smith` | Backend has routes but screens didn't call them |
| `features/merchants/presentation/merchant_payments_screen.dart` | Hardcoded payment list (`Alice Johnson $45.80`, `Bob Smith $12.00`) | No real data |
| `features/merchants/presentation/checkout_link_screen.dart` | Static form generating fake checkout links | No checkout link API integration |

### Crypto Module
| File | What it showed | Why removed |
|------|---------------|-------------|
| `features/crypto/presentation/usdt_wallet_screen.dart` | Local-only USDT balance (starts at 0), hardcoded tx history (`Deposit +100.00 USDT`, `Send to 0x4a2b...`) | No blockchain/crypto API exists |

### Bills Module
| File | What it showed | Why removed |
|------|---------------|-------------|
| `features/bills/presentation/bill_payments_screen.dart` | Hardcoded bill categories and quick amounts | No bill payment provider API |

### Splits Module
| File | What it showed | Why removed |
|------|---------------|-------------|
| `features/splits/presentation/split_bill_screen.dart` | Hardcoded participants (`@alice`, `@bob`, `@charlie`) | Backend has routes but screens used local data only |
| `features/splits/presentation/split_detail_screen.dart` | Hardcoded shares (`Alice (You) $5.55`, `Bob Smith $5.55`) | No real data |

### Banking Module
| File | What it showed | Why removed |
|------|---------------|-------------|
| `features/banking/presentation/bank_connection_screen.dart` | Fake account name lookups (`GB_301500_12345678: Sarah Mitchell`, random name generation) | No real bank validation API; could mislead users |

---

## Routes Removed

```
/admin                → AdminDashboardScreen
/admin/fraud          → FraudAlertsScreen
/merchant             → MerchantDashboardScreen
/merchant/payments    → MerchantPaymentsScreen
/merchant/checkout    → CheckoutLinkScreen
/crypto/usdt          → UsdtWalletScreen
/bills                → BillPaymentsScreen
/splits/new           → SplitBillScreen
/splits/:id           → SplitDetailScreen
/banking/connect      → BankConnectionScreen
```

---

## Demo Data Stripped from Mixed Screens

### home_screen.dart
- Removed `"2M+ Transfers"` hardcoded marketing stat

### wallet_screen.dart
- Removed hardcoded `_usdRates` static exchange rate table → now uses live `exchangeRatesProvider`
- Removed hardcoded virtual card number `"•••• •••• •••• 9982"`

### transactions_hub_screen.dart
- Removed hardcoded `_txns` list containing fake transactions (`Amara Johnson`, etc.)
- Now shows only real transactions from `transactionProvider`

### spending_analytics_screen.dart
- Removed `_demoCats` fallback with fabricated amounts (`Food $320`, `Shopping $520`, etc.)
- Now shows empty state when no real transactions exist

### zelle_transfer_screen.dart
- Removed `_demoNetworkUsers` fallback list (`@sarah.k / Sarah Kim`, `@demo.user`)

### international_transfer_screen.dart
- Removed fake account name generator (random names from static arrays)

### transfer_confirm_screen.dart
- Removed mock transfer ID generation → uses server-assigned ID

### transfer_status_screen.dart
- Removed hardcoded `recipientName: 'John Smith'` fallback

### payment_requests_screen.dart
- Removed hardcoded `"Bob Smith"` / `"Alice Johnson"` labels in empty/error states

### send_money_screen.dart
- Removed static `_fxRates` map → uses live exchange rates

---

## Features Fixed / Wired Up

### notifications_screen.dart
- **Before:** Used hardcoded list (`"Bob sent you $50.00"`, `"You sent $25.00 to Alice"`)
- **After:** Wired to `notificationsRepositoryProvider` → `GET /notifications`

### two_factor_screen.dart
- **Before:** 2FA verify call was commented out — 2FA login was broken
- **After:** Uncommented and wired to `POST /auth/2fa/challenge`

### scheduled_transfers_screen.dart
- **Before:** Initialized from empty `_demoScheduled` list, never fetched from API
- **After:** Loads from `scheduledRepositoryProvider` → `GET /scheduled` on screen mount

---

## Re-adding Features Checklist

When ready to re-add a feature, ensure:
1. [ ] Backend API endpoints are implemented and tested
2. [ ] Repository layer in Flutter calls real endpoints
3. [ ] Screen uses the repository (no hardcoded data)
4. [ ] Route is added back to `app_router.dart`
5. [ ] Navigation entry added to relevant screen (settings, home, etc.)

### Priority order for re-adding:
1. **Merchants** — API routes exist (`/v1/merchants`), just need screen wiring
2. **Splits** — API routes exist (`/v1/splits`), just need screen wiring
3. **Scheduled Transfers** — Already wired in this cleanup
4. **Admin/Fraud** — API routes exist (`/v1/admin/fraud`), need proper admin role check
5. **Bills** — Needs third-party bill payment provider integration
6. **Crypto/USDT** — Needs blockchain API integration
7. **Banking** — Needs real bank account validation API (e.g., Plaid)
