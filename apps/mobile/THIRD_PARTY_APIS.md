# AmixPAY — Third-Party API Requirements for Publication

> Version 1.1.0 | Updated: March 2026
> This document lists every external API and service required to take AmixPAY
> from MVP demo to a fully production-ready, publicly published application.

---

## TIER 1 — LEGALLY REQUIRED (Cannot launch without these)

---

### 1. KYC / Identity Verification

| Provider | Purpose | Coverage | Cost |
|---|---|---|---|
| **Smile Identity** | Gov't ID + selfie check for Africa | Nigeria, Kenya, Ghana, South Africa, Uganda, Tanzania + 30 more | ~$0.50–$2.00 per check |
| **Onfido** | Global ID + liveness check | 195 countries, global diaspora users | ~$1.50–$3.00 per check |
| **Persona** | Configurable KYC flows | Global | ~$0.50–$2.00 per check |

**Recommendation:** Use **Smile Identity** for all African users (deeper government database access — NIMC, NHIF, Ghana NIA). Use **Onfido** for UK, EU, US, and other diaspora users.

**How to sign up:**
- Smile Identity: https://smileidentity.com → Book demo → Sandbox in 24h
- Onfido: https://onfido.com → Contact sales for Africa pricing
- Persona: https://withpersona.com → Self-serve sandbox

**Flutter integration:** REST API via Dio. SDKs available for both.

---

### 2. AML / Compliance Screening

| Provider | Purpose | Cost |
|---|---|---|
| **ComplyAdvantage** | Sanctions list, PEP screening, adverse media | ~$500/month base |
| **Refinitiv World-Check** | Global sanctions + watchlist screening | Enterprise pricing |
| **Comply Cube** | AML screening + enhanced due diligence | Pay-per-check from $0.20 |

**Why required:** International money transfers require screening against OFAC, UN, EU, and UK HMT sanctions lists. This is a legal obligation in every jurisdiction AmixPAY operates in.

**Recommendation:** Start with **Comply Cube** (pay-per-check, no minimum) then migrate to ComplyAdvantage at scale.

---

### 3. Regulatory Licenses (Not an API — but required before launch)

| License | Jurisdiction | Body | Timeline |
|---|---|---|---|
| Electronic Money Institution (EMI) | UK | FCA | 6–18 months, ~£10,000 application fee |
| Money Services Business (MSB) | USA | FinCEN + state MTL | 3–12 months per state |
| Payment Service Provider | EU/EEA | Central Bank of Ireland or DNB (Netherlands) | 6–12 months |
| Mobile Money Operator (MMO) | Nigeria | CBN | 12–24 months |
| Payment Service Provider | Kenya | CBK | 6–12 months |

**Shortcut:** Partner with a licensed EMI/PSP as a Technology Provider (white-label). Companies like **Railsr** (EU/UK), **Modulr** (UK), **Paystack** (Nigeria/Ghana/Kenya) allow you to launch under their license while building your own.

---

## TIER 2 — PAYMENT RAILS (Core business functionality)

---

### 4. Card Payments (Wallet Top-Up)

| Provider | Purpose | Coverage | Cost |
|---|---|---|---|
| **Stripe** | Card funding — Visa, Mastercard, Amex | 46 countries | 1.4% + £0.20 EU / 2.9% + $0.30 US |
| **Flutterwave** | Card + bank funding for Africa | 34 African countries | 1.4% local / 3.8% international |
| **Paystack** | Card funding for Nigeria, Ghana, Kenya | Nigeria, Ghana, Kenya, South Africa | 1.5% local (capped ₦2,000) |

**How to sign up:**
- Stripe: https://stripe.com → dashboard.stripe.com → 10-minute signup
- Flutterwave: https://flutterwave.com → Live in 48h after BVN/CAC verification
- Paystack: https://paystack.com → Live in 24h for Nigeria

**Flutter:** `flutter_stripe: ^11.0.0` for Stripe. REST via Dio for Flutterwave/Paystack.

---

### 5. Bank Account Linking (Open Banking / ACH)

| Provider | Purpose | Coverage | Cost |
|---|---|---|---|
| **Plaid** | Bank link + ACH pull | USA, Canada, UK (limited) | $0.30–$1.00 per Link session |
| **TrueLayer** | Open Banking bank link | UK, EU (30+ banks) | £0.10–£0.50 per connection |
| **Mono** | Bank statement + direct debit | Nigeria, Ghana, Kenya, South Africa | ₦50–₦200 per connection |
| **Stitch** | Open Banking | South Africa, Nigeria | ~$0.30 per connection |

**How to sign up:**
- Plaid: https://plaid.com → Sandbox immediate, production 2–4 weeks
- TrueLayer: https://truelayer.com → Developer portal self-serve
- Mono: https://mono.co → Nigerian startup-friendly, fast approval

---

### 6. International Transfers (Wire / SWIFT / Local Rails)

| Provider | Purpose | Coverage | Cost |
|---|---|---|---|
| **Wise Business (formerly TransferWise)** | International transfers at mid-market rate | 80+ countries | 0.4%–1.5% of transfer |
| **Currencycloud** | FX + international payout API | 180 countries, 35 currencies | 0.3%–0.8% FX spread |
| **Banking Circle** | SWIFT + SEPA + local payments | Europe + global | Volume-based pricing |
| **Nium** | Multi-currency payout + receipt | 100+ countries | Volume-based |

**Recommendation:** Start with **Wise Business API** — fastest to integrate, best rates, transparent pricing, and same-day delivery to most corridors.

**How to sign up:**
- Wise Business API: https://wise.com/business/api → Sandbox in 1 day, live in 2–4 weeks
- Currencycloud: https://currencycloud.com → Enterprise sales process

---

### 7. Mobile Money (Critical for Africa)

| Provider | Purpose | Coverage | Cost |
|---|---|---|---|
| **M-Pesa API (Safaricom Daraja)** | Mobile money send/receive | Kenya, Tanzania, Ghana, Mozambique, Egypt | Free API, transaction fees apply |
| **MTN MoMo API** | MTN Mobile Money | 16 African countries | 1%–2% per transaction |
| **Airtel Money API** | Airtel mobile payments | 14 African countries | 1%–2% per transaction |
| **Flutterwave** | Aggregates M-Pesa, MTN, Airtel, Airtime | All of Africa | 1.4% + fixed |

**Recommendation:** Use **Flutterwave** as a single aggregator — it handles M-Pesa, MTN MoMo, Airtel Money, bank transfers, and airtime top-ups in one API. Reduces integration from 4 APIs to 1.

**How to sign up:** https://developer.flutterwave.com

---

## TIER 3 — EXCHANGE RATES & FINANCIAL DATA

---

### 8. Live Exchange Rates

| Provider | Purpose | Free Tier | Paid |
|---|---|---|---|
| **Open Exchange Rates** | Real-time FX rates, 170+ currencies | 1,000 req/month | $12/month (unlimited) |
| **Fixer.io** | ECB-based rates, 170 currencies | 100 req/month | €10/month |
| **ExchangeRate-API** | Simple REST, 160+ currencies | 1,500 req/month | $10/month |
| **Wise Rate API** | Mid-market rates for Wise corridors | Free | Free |

**Recommendation:** **Open Exchange Rates** (established, 10+ years, used by Wise competitors). Replace `YOUR_OPEN_EXCHANGE_RATES_APP_ID` in `exchange_rate_service.dart` with your key.

**How to sign up:** https://openexchangerates.org → Free tier active immediately.

---

## TIER 4 — NOTIFICATIONS & COMMUNICATIONS

---

### 9. Push Notifications

| Provider | Purpose | Cost |
|---|---|---|
| **Firebase Cloud Messaging (FCM)** | Android + iOS push | Free (Google) |
| **Apple Push Notification Service (APNs)** | iOS push (via FCM) | Free (Apple Developer $99/year) |

**Setup required:**
1. Create Firebase project at https://console.firebase.google.com
2. Add Android app → download `google-services.json` → place in `android/app/`
3. Add iOS app → download `GoogleService-Info.plist` → place in `ios/Runner/`
4. Uncomment Firebase lines in `lib/main.dart`

---

### 10. SMS Verification & OTP

| Provider | Purpose | Cost |
|---|---|---|
| **Twilio Verify** | Phone OTP + 2FA SMS | $0.05/SMS + $0.05/verification |
| **Vonage (Nexmo)** | SMS OTP | $0.0065–$0.05/SMS |
| **Termii** | Africa-focused SMS (Nigeria, Ghana, Kenya) | ₦4–₦10 per SMS |
| **African's Talking** | SMS + USSD for Africa | $0.004–$0.05/SMS |

**Recommendation:** **Twilio** for global users + **Termii** for Nigeria/Ghana/Kenya (better delivery rates, cheaper).

---

### 11. Email (Transactional)

| Provider | Purpose | Free Tier | Paid |
|---|---|---|---|
| **SendGrid** | Transactional email | 100/day free | $19.95/month (50k emails) |
| **Mailgun** | Developer-friendly | 100/day free | $35/month |
| **Amazon SES** | Cheapest at scale | 62k/month free | $0.10/1,000 emails |

---

## TIER 5 — INFRASTRUCTURE & SECURITY

---

### 12. Cloud Infrastructure

| Service | Purpose | Provider | Monthly Cost (MVP) |
|---|---|---|---|
| **App Hosting** | Node.js API server | AWS ECS Fargate / Railway / Render | $20–$50 |
| **Database** | PostgreSQL | AWS RDS / Supabase / Neon | $15–$50 |
| **Cache** | Redis (rate limits, sessions, FX cache) | AWS ElastiCache / Upstash | $7–$20 |
| **Storage** | KYC documents, avatars | AWS S3 | $0.023/GB |
| **CDN** | API caching + DDoS | Cloudflare (free tier) | Free |

**Recommendation for MVP:** **Railway.app** — deploys Node.js + PostgreSQL + Redis in 10 minutes, no DevOps required, ~$20/month flat.

---

### 13. Document Storage (KYC)

| Provider | Purpose | Cost |
|---|---|---|
| **AWS S3** | Encrypted document storage | $0.023/GB + $0.0004/request |
| **Cloudinary** | Image + document management | Free 25GB → $89/month |

**Critical:** KYC documents must be encrypted at rest (AES-256) and access-logged for regulatory compliance. AWS S3 with SSE-S3 encryption and CloudTrail logging satisfies FCA and CBN requirements.

---

### 14. Fraud Detection

| Provider | Purpose | Cost |
|---|---|---|
| **Stripe Radar** | Card fraud ML (built into Stripe) | 0.05% of transaction |
| **Sardine** | Transaction fraud + device intelligence | Volume pricing |
| **Seon** | Fraud scoring + email/phone intelligence | $0.10–$0.50 per check |

---

### 15. App Distribution (Investor & Beta)

| Platform | Purpose | Cost |
|---|---|---|
| **Google Play Store** | Android production publish | $25 one-time |
| **Apple App Store** | iOS production publish | $99/year |
| **Firebase App Distribution** | Internal investor/tester APK distribution | Free |
| **TestFlight** | iOS beta testing | Free (requires Apple Developer account) |

---

## COMPLETE INTEGRATION TIMELINE

| Phase | Duration | APIs | Cost to unlock |
|---|---|---|---|
| **Phase 1: Investor Demo** | Now | Firebase App Distribution only | Free |
| **Phase 2: Closed Beta** | 4–6 weeks | Stripe, Open Exchange Rates, Firebase FCM, Twilio | ~$100/month |
| **Phase 3: Nigeria/Kenya Launch** | 8–12 weeks | Paystack/Flutterwave, Smile Identity, M-Pesa, Termii | ~$500/month |
| **Phase 4: UK/EU Launch** | 16–24 weeks | FCA EMI license OR Modulr partnership, TrueLayer, Onfido, Wise API | ~$2,000/month + licensing |
| **Phase 5: US Launch** | 24–36 weeks | Plaid, Stripe US, FinCEN MSB + state MTLs | ~$3,000/month + compliance |

---

## ESTIMATED MONTHLY API COST AT SCALE

| Users | Monthly API Cost | Breakdown |
|---|---|---|
| 1,000 active users | ~$200–$400 | Stripe fees + KYC + SMS |
| 10,000 active users | ~$1,500–$3,000 | + Wise API fees + infrastructure |
| 100,000 active users | ~$12,000–$25,000 | + Enterprise contracts + compliance |

---

## QUICK START — MINIMUM TO GO LIVE (Nigeria focus)

1. **Paystack** → card funding and bank transfers (Nigeria/Ghana/Kenya)
2. **Flutterwave** → mobile money (M-Pesa, MTN MoMo, Airtime)
3. **Smile Identity** → KYC for African government IDs
4. **Firebase FCM** → push notifications (free)
5. **Termii** → SMS OTP (Nigeria-optimised delivery)
6. **Open Exchange Rates** → live FX rates ($12/month)
7. **Railway.app** → API hosting (~$20/month)

**Total minimum to go live in Nigeria/Kenya:** ~$50–$100/month operational cost + one-time Paystack/Flutterwave approval process (typically 2–5 business days).

---

*Document maintained by AmixPAY Engineering. Last updated: March 2026.*
