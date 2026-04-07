# AmixPay — Production Readiness & External Services Analysis

> Prepared: 7 April 2026
> Purpose: Team briefing on what's needed to go from current state → live product

---

## Table of Contents

1. [Current State Summary](#1-current-state-summary)
2. [The Money Flow — How It Has To Work](#2-the-money-flow--how-it-has-to-work)
3. [External Services Required](#3-external-services-required)
4. [Fee Analysis — What The Company Pays](#4-fee-analysis--what-the-company-pays)
5. [Fee Analysis — What Customers Pay](#5-fee-analysis--what-customers-pay)
6. [Recommended Provider Stack (Low-Cost)](#6-recommended-provider-stack-low-cost)
7. [Regulatory / Licensing Requirements](#7-regulatory--licensing-requirements)
8. [Country Coverage Matrix](#8-country-coverage-matrix)
9. [Gap Analysis — What's Missing in Code](#9-gap-analysis--whats-missing-in-code)
10. [Estimated Costs to Launch](#10-estimated-costs-to-launch)
11. [Phased Launch Strategy](#11-phased-launch-strategy)

---

## 1. Current State Summary

### What Works (Connected to Real APIs)
| Feature | Status | Notes |
|---------|--------|-------|
| User registration & login | ✅ Real | JWT auth, email verification working |
| Profile & KYC upload | ✅ Real | Documents upload to S3, but **no verification service** — humans must manually review |
| Multi-currency wallet (12 currencies) | ✅ Real | USD, EUR, GBP, JPY, CAD, AUD, CHF, CNY, NGN, KES, GHS, ZAR |
| P2P send between AmixPay users | ✅ Real | Debits sender, credits recipient, 0.5% fee |
| Payment requests | ✅ Real | Request money from another user, accept/decline |
| Exchange rates | ✅ Real | Open Exchange Rates API (free tier) |
| Wallet balance & ledger | ✅ Real | Double-entry bookkeeping with `ledger_entries` table |

### What's Partially Built (Code Exists but Not Production-Ready)
| Feature | Status | What's Missing |
|---------|--------|----------------|
| Card deposits (Stripe) | ⚠️ Skeleton | PaymentIntent code exists but mobile app uses simulated flow, no Stripe SDK in Flutter |
| International transfers (Wise) | ⚠️ Skeleton | API calls written but no Wise API key, no Wise approval, falls back to local quotes |
| Bank payouts (Flutterwave) | ⚠️ Skeleton | `initiatePayout()` written but never called from any flow |
| Bank connection (Plaid) | ⚠️ Skeleton | Link token code exists, but Plaid sandbox only, US/UK/CA only |
| Virtual cards (Stripe Issuing) | ⚠️ Skeleton | `createVirtualCard()` code exists, needs Stripe Issuing approval |
| Banking rails routing | ⚠️ Skeleton | `bankingRailService.js` has rail definitions (ACH, SEPA, FPS, SWIFT, NEFT, etc.) but no actual rail connections |

### What's Completely Fake / Not Built
| Feature | Status |
|---------|--------|
| Bank account name verification | ❌ Generates random fake names |
| USDT/crypto wallet | ❌ Local counter only, no blockchain |
| Bill payments | ❌ Hardcoded categories, no provider API |
| Merchant dashboard | ❌ 100% mock data |
| Admin/fraud dashboard | ❌ 100% mock data |
| Split bills | ❌ Hardcoded participants |
| Push notifications (FCM) | ❌ Token registered but API never sends |
| SMS/OTP (Twilio) | ❌ Logs to console only |
| 2FA (TOTP) | ❌ Verify call commented out |
| Scheduled transfer execution | ❌ CRUD exists, no cron/worker to run them |

### Bottom Line
**The app can register users, show balances, and move numbers between AmixPay wallets in the database.** No real money enters or leaves the system. Users cannot fund their wallets with real money, cannot withdraw to a bank account, and cannot spend with a card.

---

## 2. The Money Flow — How It Has To Work

```
┌─────────────────────────────────────────────────────────────────┐
│                    MONEY IN (Funding)                             │
│                                                                   │
│  User's Bank ──→ [Plaid Link] ──→ ACH/bank pull ──→ AmixPay     │
│  User's Card ──→ [Stripe]    ──→ Card charge    ──→ AmixPay     │
│  Mobile Money ──→ [Flutterwave] ──→ Collection  ──→ AmixPay     │
│  Bank Transfer ──→ [Virtual IBAN] ──→ Credit     ──→ AmixPay     │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│              INTERNAL (AmixPay Wallets)                           │
│                                                                   │
│  User A ──→ P2P Transfer ──→ User B                              │
│  (Database debit/credit — this part works today)                 │
│                                                                   │
│  Currency conversion between wallet balances                      │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                   MONEY OUT (Withdrawal/Spend)                   │
│                                                                   │
│  AmixPay ──→ [Wise API]        ──→ Bank account (international)  │
│  AmixPay ──→ [Flutterwave]     ──→ Bank account (Africa)         │
│  AmixPay ──→ [Stripe Issuing]  ──→ Virtual card (spend anywhere) │
│  AmixPay ──→ [ACH/SEPA rail]   ──→ Bank account (US/EU)         │
│  AmixPay ──→ [Mobile Money]    ──→ M-Pesa etc. (Africa)         │
└─────────────────────────────────────────────────────────────────┘
```

**Every arrow above requires a paid external service, an API integration, and in most cases a compliance/licensing relationship.**

---

## 3. External Services Required

### 3A. MONEY IN — Wallet Funding

| Service | Provider | Purpose | Countries | Status in Code |
|---------|----------|---------|-----------|----------------|
| **Card payments** | **Stripe** | Accept Visa/MC/Amex deposits | 46+ countries | Skeleton exists |
| **Bank linking (US/CA)** | **Plaid** | Connect bank accounts for ACH pulls | US, CA, UK | Skeleton exists |
| **Bank linking (EU)** | **Plaid** or **TrueLayer** | Open Banking for SEPA debits | EU/UK | Not built |
| **Mobile money collection** | **Flutterwave** | M-Pesa, MTN MoMo, etc. | NG, KE, GH, ZA, UG, TZ, etc. | Not built (only payout code) |
| **Bank transfer collection** | **Flutterwave** or **Stripe** | Direct bank transfer/pay-in | Africa, Global | Not built |
| **Crypto on-ramp** | **MoonPay** or **Transak** | Buy with crypto | Global | Not built (marked "coming soon") |

### 3B. MONEY OUT — Withdrawals & Payouts

| Service | Provider | Purpose | Countries | Status in Code |
|---------|----------|---------|-----------|----------------|
| **International bank transfers** | **Wise Platform API** | Send to 70+ countries via local rails | 70+ countries | Skeleton exists (sandbox only) |
| **Africa bank payouts** | **Flutterwave** | Send to bank accounts in Africa | NG, KE, GH, ZA, UG, TZ, +15 more | Skeleton exists |
| **Africa mobile money payouts** | **Flutterwave** | Send to M-Pesa, MTN MoMo, etc. | KE, GH, UG, TZ, CM, +10 more | Not built |
| **US domestic payouts** | **Stripe Connect** or **Plaid Transfer** | ACH credits to US banks | US | Not built |
| **EU domestic payouts** | **Wise** or **Stripe** | SEPA transfers | EU/UK | Not built |
| **Virtual card issuance** | **Stripe Issuing** or **Lithic** | Issue Visa/MC virtual cards | US (Stripe), broader via Lithic | Skeleton exists |

### 3C. SUPPORTING SERVICES

| Service | Provider Options | Purpose | Status in Code |
|---------|-----------------|---------|----------------|
| **KYC / Identity Verification** | Didit (FREE), Sumsub, Smile Identity | Verify user IDs, liveness check | ❌ Manual only — no service |
| **AML Screening** | Didit, Sumsub, ComplyAdvantage | Sanctions/PEP screening | ❌ Not built |
| **SMS / OTP** | Twilio, Vonage, Termii (Africa) | Phone verification | ❌ Console-only logging |
| **Email Transactional** | SendGrid, Resend, Postmark | Receipts, alerts, verification | ⚠️ Config exists, not tested |
| **Push Notifications** | Firebase (FCM) | Real-time alerts | ❌ Token exists, no sends |
| **Exchange Rates** | Open Exchange Rates | Live FX rates | ✅ Working |
| **Document Storage** | AWS S3 | KYC docs, receipts | ⚠️ Config exists |
| **Monitoring / APM** | Sentry, Datadog | Error tracking | ❌ None |
| **Fraud Detection** | Sardine, Unit21, or custom | Transaction monitoring | ❌ Basic fraud rules in code only |

---

## 4. Fee Analysis — What The Company Pays (Cost of Doing Business)

### 4A. Wallet Funding (Money In) — Fees AmixPay Absorbs or Passes Through

| Method | Provider | Fee to AmixPay | Notes |
|--------|----------|---------------|-------|
| **Credit/Debit Card** | Stripe | **2.9% + $0.30** per transaction | US cards. International cards: +1.5%. Currency conversion: +1% |
| **ACH bank debit (US)** | Stripe | **0.8%, max $5** | Takes 4-5 business days |
| **ACH instant (US)** | Stripe | **1.0%, max $10** | Same day |
| **SEPA debit (EU)** | Stripe | **0.8% + €0.30** | 6-8 business days |
| **Mobile Money (Africa)** | Flutterwave | **Varies by country** — see below | |
| └ Nigeria (cards) | Flutterwave | **2.0%** (1.4% + 0.6% platform) capped at NGN 2,000 | |
| └ Kenya (M-Pesa) | Flutterwave | **3.0%** | |
| └ Ghana (MoMo) | Flutterwave | **2.5%** | |
| └ South Africa (cards) | Flutterwave | **3.25%** | |
| **Bank transfer (manual)** | Direct deposit to company account | **~$0** | User sends to AmixPay's bank; slowest method |

### 4B. Withdrawals / Payouts (Money Out) — Fees AmixPay Pays

| Method | Provider | Fee | Notes |
|--------|----------|-----|-------|
| **International bank transfer** | Wise API | **~0.4%-0.8%** avg (varies by corridor) | Wise avg fee is 0.53% globally. Example: USD→NGN ~0.6%, USD→GBP ~0.35% |
| **Africa bank payout (Nigeria)** | Flutterwave | **NGN 10-50** per tx (tiered by amount) | NGN ≤5000 = NGN 10, ≤50K = NGN 25, >50K = NGN 50 |
| **Africa bank payout (Kenya)** | Flutterwave | **KES 100** flat | |
| **Africa bank payout (Ghana)** | Flutterwave | **GHS 10** flat | |
| **Africa bank payout (South Africa)** | Flutterwave | **ZAR 10** flat | |
| **Africa mobile money** | Flutterwave | **1-3%** varies by country | See Flutterwave transfer pricing above |
| **US payout (ACH)** | Stripe / Wise | **$0.25-$1.00** | |
| **EU payout (SEPA)** | Wise | **~€0.50-1.00** | |
| **UK payout (FPS)** | Wise | **~£0.30-0.50** | Free via FPS if Wise routes optimally |
| **SWIFT international wire** | Wise / Bank | **$15 + 0.1%** | Fallback for unsupported countries |
| **US payout (Flutterwave)** | Flutterwave | **$40 flat** | ⚠️ Very expensive — avoid for US |
| **EU payout (Flutterwave)** | Flutterwave | **€35 flat** | ⚠️ Very expensive — avoid for EU |

### 4C. Virtual Card Costs

| Item | Provider | Fee | Notes |
|------|----------|-----|-------|
| **Virtual card creation** | Stripe Issuing | **$0.10** per card | |
| **Per transaction** | Stripe Issuing | **$0.20 + 0.2%** of amount (US purchase) | |
| **International purchase** | Stripe Issuing | **$0.20 + 0.2%** + 1% intl fee | |
| **Monthly active card** | Stripe Issuing | **$0** | No monthly per-card fee |
| **Alternative: Lithic** | Lithic | **$0.00** card creation, **$0.10** per txn | Requires approval, good for startups |

### 4D. Supporting Service Costs (Monthly)

| Service | Provider | Monthly Cost | Notes |
|---------|----------|-------------|-------|
| **KYC Verification** | **Didit** | **$0 (core KYC is FREE)** | Unlimited ID verify + liveness + face match. AML screening: $0.27/check |
| **KYC Verification (alt)** | Sumsub | **$149/mo min** + $1.35/verification | More established, higher cost |
| **KYC Verification (alt)** | IDWise | **$1.00/verification** flat | Simple pricing, good global coverage |
| **AML Screening** | Didit | **$0.27/check** | PEP + sanctions lists |
| **SMS/OTP** | Twilio | **$0.0079/SMS** (US) | Africa: $0.03-0.10/SMS depending on country |
| **SMS/OTP (alt)** | **Termii** | **NGN 3.25/SMS** (~$0.002) | Much cheaper for Africa |
| **Email** | SendGrid | **Free tier: 100/day** | Paid: $19.95/mo for 50K emails |
| **Email (alt)** | **Resend** | **Free: 3K/mo**, then $20/mo for 50K | |
| **Push Notifications** | Firebase FCM | **FREE** | Unlimited push |
| **Exchange Rates** | Open Exchange Rates | **$12/mo** (hourly updates) | Free tier: 1000 req/mo |
| **Hosting (API + DB)** | Dokploy/VPS | **$20-50/mo** | Current plan |
| **Monitoring** | Sentry | **Free tier: 5K events/mo** | Developer plan: $26/mo |
| **Document Storage** | AWS S3 | **~$0.023/GB** | Negligible at early stage |

---

## 5. Fee Analysis — What Customers Pay

### Recommended Customer Fee Structure

| Transaction Type | Suggested Customer Fee | AmixPay Cost | AmixPay Margin |
|-----------------|----------------------|-------------|----------------|
| **Card funding** | **2.5% - 3.5%** | 2.9% + $0.30 (Stripe) | -0.4% to +0.6% (small amounts lose money) |
| **Bank funding (ACH)** | **FREE or $0.50** | 0.8%, max $5 | Subsidized for growth |
| **Mobile money funding** | **1.5% - 2.5%** | 2-3% (Flutterwave) | Break-even to slight loss |
| **P2P transfer (internal)** | **FREE or 0.5%** | ~$0 (database operation) | **Pure profit** |
| **International transfer** | **1.0% - 2.5%** (varies by corridor) | 0.4-0.8% (Wise) + rail fees | **0.5-1.5% profit** |
| **Africa payout (bank)** | **$1 - $3 flat** or **1%** | NGN 10-50 / KES 100 / GHS 10 | Margin varies |
| **Africa payout (mobile money)** | **1.5% - 2.5%** | 1-3% (Flutterwave) | Tight margins |
| **US/EU bank payout** | **FREE or $1** | $0.25-$1.00 | Break-even |
| **Virtual card creation** | **$1 - $2** | $0.10 (Stripe) | $0.90-$1.90 profit |
| **FX conversion spread** | **0.5% - 1.5% markup** on mid-market rate | 0.3-0.5% (Wise spread) | **0.2-1.0% profit** |

### Key Insight: Where AmixPay Makes Money
1. **FX spread** on international transfers (biggest margin)
2. **P2P internal transfers** (nearly zero cost)
3. **Virtual card issuance** (low cost, premium perceived value)
4. **International transfer fees** (markup over Wise cost)

### Key Insight: Where AmixPay Loses Money (or Breaks Even)
1. **Card funding for small amounts** (Stripe's $0.30 flat fee kills margins on <$20 transactions)
2. **Mobile money collection** (Flutterwave takes 2-3%)
3. **US/EU payouts via Flutterwave** ($35-$40 flat — must use Wise instead)

---

## 6. Recommended Provider Stack (Low-Cost)

### Tier 1 — Must Have for MVP Launch

| Need | Recommended Provider | Why | Monthly Cost |
|------|---------------------|-----|-------------|
| **Card deposits (global)** | **Stripe** | Best coverage, most reliable, code already exists | Pay-per-use |
| **International transfers** | **Wise Platform API** | 70+ countries, cheapest FX rates (0.53% avg), code skeleton exists | Pay-per-use |
| **Africa payouts** | **Flutterwave** | Best Africa coverage (20+ countries), bank + mobile money, code skeleton exists | Pay-per-use |
| **KYC / Identity** | **Didit** | **FREE unlimited core KYC** — ID verification, liveness, face match. Best for a startup | $0 |
| **SMS OTP** | **Termii** (Africa) + **Twilio** (Global) | Termii is 10x cheaper for African numbers | ~$20-50/mo |
| **Email** | **Resend** or **SendGrid** | Free tier covers early stage | $0-$20/mo |
| **Exchange rates** | **Open Exchange Rates** | Already integrated | $12/mo |
| **Push notifications** | **Firebase FCM** | Already set up, free | $0 |

**Estimated monthly infrastructure cost (pre-revenue): ~$50-100/mo + per-transaction fees**

### Tier 2 — Add After Initial Traction

| Need | Recommended Provider | Why |
|------|---------------------|-----|
| **Virtual cards** | **Stripe Issuing** (US) or **Lithic** | Issuing needs approval; Lithic is startup-friendly |
| **US bank funding (ACH)** | **Plaid** + **Stripe** (ACH Direct Debit) | Plaid for account linking, Stripe for the actual pull |
| **EU bank funding** | **TrueLayer** or **Plaid** | Open Banking SEPA debits |
| **AML Screening** | **Didit** ($0.27/check) or **ComplyAdvantage** | Required by regulators |
| **Monitoring** | **Sentry** | Free tier to start |

### Tier 3 — Scale Phase

| Need | Provider |
|------|----------|
| **Fraud detection** | Sardine, Unit21 |
| **Crypto on/off ramp** | MoonPay, Transak |
| **Bill payments** | Flutterwave Bills API |
| **Physical cards** | Stripe Issuing (physical) |

---

## 7. Regulatory / Licensing Requirements

### ⚠️ THIS IS THE BIGGEST BLOCKER — NOT TECHNOLOGY

A money transfer app **cannot legally operate** without proper licensing. This is non-negotiable.

### Option A: Get Your Own Licenses (Expensive, Slow)

| Jurisdiction | License Required | Cost | Timeline |
|-------------|-----------------|------|----------|
| **US — Federal** | MSB Registration (FinCEN) | ~$0 (free filing) | 1-2 weeks |
| **US — State** | Money Transmitter License (MTL) per state | **$5,000-$50,000 per state** + surety bonds ($25K-$1M per state) | 6-18 months per state |
| **US — Total for 50 states** | All MTLs | **$500K - $2M+** total (legal, bonds, applications) | 12-24 months |
| **UK** | FCA E-Money or Payment Institution license | **£5,000 application** + £50-100K compliance setup | 6-12 months |
| **EU** | EMI or PI license (one country, passported) | **€10,000-50,000** application + compliance | 6-18 months |
| **Nigeria** | CBN Payment Service Provider (PSP) license | ~$10K-$50K | 6-12 months |
| **Kenya** | CBK Payment Service Provider license | Variable | 6-12 months |

### Option B: Partner Under Someone Else's License (Recommended for Startups) ⭐

| Approach | How It Works | Cost | Timeline |
|----------|-------------|------|----------|
| **Banking-as-a-Service (BaaS)** | Partner with a licensed bank/EMI that lets you operate under their license. They handle compliance, you build the UX. | **Revenue share (10-30%) or monthly fee ($2K-$10K/mo)** | 1-3 months |
| **Wise Platform Partnership** | Wise handles the licensed money transmission. You use their API. They move the money. | **Built into Wise fees** (no additional license cost to you) | Apply → weeks to months |
| **Flutterwave Sub-merchant** | Operate under Flutterwave's licenses in Africa. | **Built into Flutterwave fees** | Apply → weeks |
| **Stripe Treasury + Connect** | Stripe provides BaaS infrastructure with partner banks. | **Stripe fees + partner bank fees** | Apply → approval required |

### Recommended Licensing Strategy

```
Phase 1 (Launch):
  → Use Wise Platform API for international transfers (operates under Wise's licenses)
  → Use Flutterwave for Africa (operates under their licenses)
  → Use Stripe for card processing (operates under Stripe's payment processor license)
  → Internal P2P transfers between your own users = may not require MTL in many jurisdictions
     (this is debatable — get legal advice for your specific structure)
  
Phase 2 (Growth):
  → Register as MSB with FinCEN (US federal — free, quick)
  → Get MTL in 3-5 key states (CA, TX, FL, NY, IL)
  → Apply for UK FCA registration
  
Phase 3 (Scale):
  → Complete US state-by-state licensing
  → EU EMI license
  → Individual African country licenses
```

### Critical Legal Note
**You MUST consult a fintech compliance lawyer before launching.** The regulatory landscape is complex and varies by country. Operating without proper licensing can result in criminal penalties, not just fines. Budget **$10,000-$50,000** for initial legal consultation and compliance setup.

---

## 8. Country Coverage Matrix

### With Wise + Flutterwave + Stripe combined:

| Region | Countries (Receive/Payout) | Via | Funding (Pay-in) |
|--------|---------------------------|-----|-------------------|
| **West Africa** | Nigeria 🇳🇬, Ghana 🇬🇭, Senegal 🇸🇳, Ivory Coast 🇨🇮, Cameroon 🇨🇲, Guinea-Bissau, Gabon | Flutterwave | Flutterwave (cards, mobile money, bank) |
| **East Africa** | Kenya 🇰🇪, Uganda 🇺🇬, Tanzania 🇹🇿, Rwanda 🇷🇼, Ethiopia 🇪🇹, Malawi 🇲🇼 | Flutterwave | Flutterwave (M-Pesa, mobile money) |
| **Southern Africa** | South Africa 🇿🇦, Zambia 🇿🇲 | Flutterwave | Flutterwave |
| **North America** | United States 🇺🇸, Canada 🇨🇦 | Wise | Stripe (cards), Plaid (ACH) |
| **UK** | United Kingdom 🇬🇧 | Wise | Stripe (cards) |
| **Europe** | All EU/EEA (27+ countries) | Wise (SEPA) | Stripe (cards) |
| **Asia Pacific** | India 🇮🇳, Australia 🇦🇺, Japan 🇯🇵, Singapore 🇸🇬, Malaysia 🇲🇾, Philippines 🇵🇭, Thailand 🇹🇭, Vietnam 🇻🇳, China 🇨🇳 | Wise | Stripe (cards) |
| **Middle East** | UAE 🇦🇪, Turkey 🇹🇷, Egypt 🇪🇬 | Wise + Flutterwave (Egypt) | Stripe |
| **Latin America** | Brazil 🇧🇷, Mexico 🇲🇽, Colombia 🇨🇴, Chile 🇨🇱, Argentina 🇦🇷, Peru 🇵🇪 | Wise | Stripe |

### Total Estimated Country Coverage: **80-100+ countries**
- **Wise** covers 70+ countries for payouts
- **Flutterwave** covers 20+ African countries
- **Stripe** processes cards from 46+ countries
- Combined with overlap: **~100 countries** for at least one direction of money flow

---

## 9. Gap Analysis — What's Missing in Code

### Critical Path Items (Must Fix Before Launch)

| # | Gap | Effort | Priority |
|---|-----|--------|----------|
| 1 | **Stripe Flutter SDK integration** — mobile app has no real Stripe SDK, just simulated success | 2-3 days | 🔴 Critical |
| 2 | **Wise API key + production approval** — need to apply as Wise Platform partner | External process | 🔴 Critical |
| 3 | **Flutterwave collection integration** — code only has payouts, need to add pay-in (card, bank, mobile money collection) | 3-5 days | 🔴 Critical |
| 4 | **KYC service integration** — connect Didit (or similar) for automated ID verification | 3-5 days | 🔴 Critical |
| 5 | **Webhook handlers** — Stripe, Flutterwave, and Wise webhooks need to be implemented to track payment status | 3-5 days | 🔴 Critical |
| 6 | **SMS OTP delivery** — wire Twilio/Termii for actual SMS sending | 1 day | 🔴 Critical |
| 7 | **2FA verification** — uncomment and test TOTP verification flow | 0.5 days | 🔴 Critical |
| 8 | **Remove all hardcoded/demo data** — fake names, demo transactions, mock users throughout the app | 2-3 days | 🔴 Critical |
| 9 | **Stripe Issuing approval + integration** — apply for Issuing access, implement card creation/management | External + 3-5 days | 🟡 High |
| 10 | **Bank account name verification** — replace fake name generator with real bank API (Flutterwave's account resolve API for Africa, Plaid for US) | 2 days | 🟡 High |
| 11 | **Transaction history from API** — mobile app uses local storage for transaction history, should fetch from server | 2 days | 🟡 High |
| 12 | **Push notification sending** — implement FCM send from API on payment events | 1-2 days | 🟡 High |
| 13 | **Admin dashboard** — build real admin API for user management, KYC review, fraud monitoring | 5-10 days | 🟡 High |
| 14 | **Withdraw/payout flow** — no UI or API flow for users to withdraw from wallet to their bank | 3-5 days | 🔴 Critical |
| 15 | **Wallet funding flow end-to-end** — connect card deposit → Stripe confirm → credit wallet (full loop with webhooks) | 3-5 days | 🔴 Critical |

### Development Effort Estimate
| Phase | Tasks | Estimated Time |
|-------|-------|---------------|
| **Fix critical blockers** | Items 1-8 above | **3-4 weeks** (1 developer) |
| **Complete core features** | Items 9-15 | **3-4 weeks** (1 developer) |
| **Testing & hardening** | Integration testing, security audit, load testing | **2-3 weeks** |
| **Total to production-ready** | | **8-11 weeks** (1 dev) or **4-6 weeks** (2 devs) |

---

## 10. Estimated Costs to Launch

### One-Time Costs

| Item | Low Estimate | High Estimate | Notes |
|------|-------------|---------------|-------|
| Legal / compliance consultation | $10,000 | $50,000 | Fintech lawyer, structure advice |
| Company incorporation (US) | $500 | $2,000 | LLC or Corp |
| FinCEN MSB registration | $0 | $0 | Free |
| Initial state MTLs (3-5 states) OR BaaS partnership | $5,000 | $50,000 | BaaS partnership is cheaper |
| Surety bonds (if own license) | $25,000 | $200,000 | Per state, varies |
| KYC/AML policy documents | $2,000 | $10,000 | Required by regulators |
| Security audit | $5,000 | $20,000 | Penetration testing |
| **Total one-time** | **$22,500** | **$332,000** | |

### Lean Launch (BaaS/Partnership Model)

| Item | Cost |
|------|------|
| Legal consultation | $10,000-$15,000 |
| Incorporation | $500-$1,000 |
| BaaS partner setup | $2,000-$5,000 |
| Security audit (basic) | $5,000 |
| **Total lean launch** | **~$20,000-$25,000** |

### Monthly Operating Costs (Pre-Revenue)

| Item | Monthly Cost |
|------|-------------|
| Hosting (VPS/Dokploy) | $30-$50 |
| Open Exchange Rates | $12 |
| SendGrid/Resend (email) | $0-$20 |
| Twilio/Termii (SMS) | $20-$50 |
| Sentry (monitoring) | $0-$26 |
| Didit KYC | $0 (free core) |
| Firebase | $0 |
| Domain + SSL | $15 |
| **Total monthly (pre-revenue)** | **~$80-$175/mo** |

### Monthly Operating Costs (With Transactions)
All payment processing fees are **per-transaction** — you only pay when money moves. No large monthly minimums with the recommended stack (Stripe, Wise, Flutterwave, Didit).

---

## 11. Phased Launch Strategy

### Phase 1: Internal Beta (Weeks 1-4)
**Goal:** Real money flows between test accounts
- [ ] Stripe card funding (live test mode → production)
- [ ] Internal P2P transfers (already works)
- [ ] Wire KYC (Didit)
- [ ] Wire SMS OTP (Termii/Twilio)
- [ ] Remove all hardcoded/demo data
- [ ] Fix 2FA
- **Licensing:** Begin legal consultation, determine structure

### Phase 2: Closed Launch — US ↔ Nigeria Corridor (Weeks 5-8)
**Goal:** 50-100 invited users sending money US → Nigeria
- [ ] Wise API partnership approval
- [ ] Flutterwave payout integration (Nigeria bank accounts)
- [ ] Webhook handlers for all providers
- [ ] Bank account verification (Flutterwave resolve API for Nigeria)
- [ ] Withdrawal flow UI + API
- [ ] Push notifications
- [ ] Admin dashboard (basic: user list, KYC review, transaction log)
- **Licensing:** FinCEN MSB registration + BaaS partnership (or begin MTL applications)

### Phase 3: Expand Corridors (Weeks 9-12)
**Goal:** Add UK, EU, Kenya, Ghana, South Africa corridors
- [ ] Enable Wise transfers to all 70+ countries
- [ ] Flutterwave payouts: Kenya, Ghana, South Africa, Uganda
- [ ] Mobile money payouts (M-Pesa, MTN MoMo)
- [ ] Plaid bank linking for US users
- [ ] Virtual card issuance (Stripe Issuing)
- **Licensing:** Apply for additional state MTLs, begin UK FCA process

### Phase 4: Public Launch (Week 13+)
**Goal:** App Store / Play Store submission
- [ ] Full security audit + penetration test
- [ ] Load testing
- [ ] App store assets and review process
- [ ] Marketing site
- [ ] Support / help desk system
- **Licensing:** Ongoing state expansions

---

## Summary for the Team

### The Honest Assessment
1. **The app shell is solid** — authentication, wallet system, ledger, P2P transfers work. The Flutter app looks good. The monorepo structure is clean.

2. **No real money flows today.** The biggest gap isn't code — it's the external service integrations and licensing.

3. **The cheapest path to launch is a partnership model** — use Wise's license for international transfers, Flutterwave's for Africa, and Stripe's for card processing. This avoids $500K+ in licensing costs.

4. **Monthly costs pre-revenue are very low** (~$100/mo) because the recommended stack (Didit, Firebase, Resend, Termii) has generous free tiers.

5. **The legal/compliance budget is the real cost** — plan $15,000-$25,000 minimum for legal advice and compliance setup.

6. **Development time to production: 8-11 weeks** with one developer, or 4-6 weeks with two.

7. **Focus the first corridor on US → Nigeria** — this is the highest-volume African remittance corridor and both Wise and Flutterwave serve it well.

### The Three Things That Must Happen First
1. **Hire a fintech compliance lawyer** — before writing any more code
2. **Apply for Wise Platform API access** — this takes weeks, start now
3. **Set up Flutterwave business account** — get API keys for production

Everything else is engineering that can happen in parallel.
