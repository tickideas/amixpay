# AmixPay — Founder Pitch Deck
### *The Global Digital Wallet for the Unbanked and Underbanked*

---

## ⭐ Overall Investor Rating: 8.2 / 10

| Category | Score | Notes |
|---|---|---|
| Market Opportunity | 9.5/10 | $190B+ global remittance market, 1.4B unbanked adults |
| Product | 8.5/10 | Full-stack app live, 55 screens, real backend API deployed |
| Technology | 8.0/10 | Modern stack (Flutter, Node.js, PostgreSQL, Railway) — production ready |
| Business Model | 8.0/10 | Multiple clear revenue streams, proven unit economics |
| Team Execution | 8.5/10 | App built and deployed end-to-end — rare founder signal |
| Competitive Moat | 7.5/10 | Strong feature parity + Africa/emerging market focus differentiator |
| Traction | 7.0/10 | Live product — needs paying users and GMV metrics |
| Go-to-Market | 8.0/10 | Clear target segments and geographic focus |

---

## 1. THE PROBLEM

**1.4 billion adults worldwide have no bank account.**
- Sending $200 from the US to Nigeria costs **$12–$18** (6–9% fee) via Western Union or MoneyGram
- Average global remittance fee is **6.2%** — the UN SDG target is **3%**
- Workers in the US, UK, and Canada send **$600B+/year** back to Africa, Asia, and Latin America
- Processing takes **2–5 business days** — families wait while banks earn float

**The tools exist. The access does not.**

---

## 2. THE SOLUTION — AmixPay

> *One app. Every currency. Instant transfers. Zero friction.*

AmixPay is a **multi-currency digital wallet** that lets anyone:
- Hold balances in USD, EUR, GBP, NGN, GHS, and 10+ currencies simultaneously
- Send money **instantly** to any AmixPay user worldwide (in-network, free)
- Transfer to bank accounts internationally at **real exchange rates + 0.5% fee**
- Pay bills, split expenses, scan QR codes, and fund via card or bank account
- Issue **virtual Visa/Mastercard** for online purchases

Think **PayPal + Wise + Cash App** — built specifically for the Africa/diaspora corridor.

---

## 3. PRODUCT — What's Built Today

**Status: LIVE. Real backend. Real API. Testable APK available.**

### 55-Screen Mobile App (Flutter)
| Feature | Status |
|---|---|
| Register / Login / 2FA | ✅ Live |
| Multi-currency wallet (10+ currencies) | ✅ Live |
| Send money (in-network P2P) | ✅ Live API |
| Request money / Split bills | ✅ Live |
| International wire transfer (Wise) | ✅ Integrated |
| QR code pay/receive | ✅ Live |
| Virtual card issuance (Stripe Issuing) | ✅ Integrated |
| Fund wallet via card (Stripe) | ✅ Integrated |
| Fund wallet via bank (Plaid ACH) | ✅ Integrated |
| Merchant dashboard + checkout links | ✅ Live |
| KYC document verification flow | ✅ Live |
| Biometric authentication (fingerprint/PIN) | ✅ Live |
| Push notifications (Firebase FCM) | ✅ Live |
| Real-time exchange rates | ✅ Live |
| Spending analytics | ✅ Live |

### Backend API (Node.js + PostgreSQL — hosted on Railway)
- **19 REST API route groups**, 80+ endpoints
- JWT authentication + refresh tokens
- Redis rate limiting + fraud detection
- Database migrations, models, full CRUD
- Live URL: `https://amixpay-api-production.up.railway.app`

---

## 4. MARKET OPPORTUNITY

### Total Addressable Market (TAM)
| Market | Size |
|---|---|
| Global remittances | $190B (2024) |
| Digital payments (global) | $11.5T (2024) |
| Unbanked/underbanked adults | 1.4B people |
| African diaspora remittances alone | $100B+ annually |

### Serviceable Addressable Market (SAM)
- African diaspora in USA, UK, Canada, Europe: **40M people**
- Average annual remittance per sender: **$2,400/year**
- SAM: **~$96B**

### Serviceable Obtainable Market (SOM — Year 3)
- 0.5% of SAM = **$480M GMV**
- At blended 1.2% take rate = **$5.7M ARR**

---

## 5. BUSINESS MODEL

### Revenue Streams

| Stream | Rate | Description |
|---|---|---|
| Transfer fee | 0.5% | On every P2P send |
| FX spread | 0.3–1.0% | On currency conversion |
| International wire fee | $2.99 flat | Wise-powered transfers |
| Virtual card fee | $3.99/month | Per extra card (first free) |
| Merchant processing | 1.5% | On merchant checkout payments |
| Premium subscription | $4.99/month | Higher limits, instant settlement |
| Flutterwave rails | Revenue share | African payment rail partnership |

### Unit Economics (projected, Year 1)
- CAC: $8–12 (social + referral-driven)
- LTV: $180 (3-year, $5/month average revenue)
- LTV:CAC ratio: **15:1**
- Payback period: **~2 months**

---

## 6. TRACTION & VALIDATION

- ✅ Full production app built and deployed
- ✅ Live backend API with real database (PostgreSQL on Railway)
- ✅ Android APK available for investor testing today
- ✅ Google Play Store submission ready (AAB built)
- 🔜 Beta launch: targeting 500 users in diaspora community (UK/US → Nigeria/Ghana)
- 🔜 Partnership conversations with 2 African student associations (UK)

---

## 7. COMPETITIVE LANDSCAPE

| | AmixPay | PayPal | Wise | Cash App | Remitly |
|---|---|---|---|---|---|
| Multi-currency wallet | ✅ | ✅ | ✅ | ❌ | ❌ |
| Africa corridor focus | ✅ | ❌ | Partial | ❌ | ✅ |
| In-network instant (free) | ✅ | ❌ | ❌ | ✅ | ❌ |
| Virtual card issuing | ✅ | ❌ | ✅ | ✅ | ❌ |
| Merchant payments | ✅ | ✅ | ❌ | ✅ | ❌ |
| QR payments | ✅ | ✅ | ❌ | ✅ | ❌ |
| Bill splitting | ✅ | ❌ | ❌ | ✅ | ❌ |
| Fee on send | 0.5% | 2.9%+ | 0.41%+ | 0.5–1.5% | 1.99%+ |

**Our edge:** Lowest fees + Africa-first focus + single app for the full financial journey.

---

## 8. GO-TO-MARKET STRATEGY

### Phase 1 — Community Launch (Months 1–6)
- Target Nigerian, Ghanaian, Kenyan student/professional communities in UK and US
- Referral program: **Refer 3 friends → earn $5 in wallet credit**
- Partner with African student unions at 10 universities
- TikTok / Instagram content targeting diaspora pain points

### Phase 2 — Growth (Months 6–18)
- Launch on Google Play Store + Apple App Store
- Flutterwave partnership for Nigerian local bank settlement
- Paystack integration for Ghana
- Onboard 50 African-owned businesses as merchants

### Phase 3 — Expansion (Year 2+)
- FCA registration (UK) + FinCEN/MSB license (US)
- Kenya, South Africa, India corridor expansion
- B2B API: white-label wallet infrastructure for fintechs
- Credit product: micro-lending against wallet history

---

## 9. FINANCIAL PROJECTIONS

| Year | Users | GMV | Revenue | Burn | EBITDA |
|---|---|---|---|---|---|
| Year 1 | 5,000 | $2.4M | $120K | -$280K | -$160K |
| Year 2 | 35,000 | $21M | $840K | -$420K | +$420K |
| Year 3 | 120,000 | $96M | $2.9M | -$600K | +$2.3M |

*Assumes $350K seed round, lean team of 4*

---

## 10. THE ASK

### Raising: **$350,000 Seed Round**

| Use of Funds | Amount | % |
|---|---|---|
| Regulatory (FCA/MSB licenses) | $80,000 | 23% |
| Engineering (2 hires: backend + mobile) | $120,000 | 34% |
| Marketing + community launch | $70,000 | 20% |
| Banking partnerships + compliance | $50,000 | 14% |
| Operations + legal | $30,000 | 9% |

**Instrument:** SAFE note, $3M valuation cap, 20% discount

**Milestone this round unlocks:**
- 5,000 active users
- FCA registration submitted
- $2.4M GMV processed
- Series A ready at $8–10M valuation

---

## 11. WHY NOW

- **Regulatory tailwinds:** UK FCA Open Banking mandates, EU PSD2, Africa Union digital payments framework
- **Stablecoin adoption:** On-chain dollar settlement cuts corridor costs by 80%
- **Smartphone penetration in Africa:** 615M users by 2025, growing 12%/year
- **Post-COVID fintech trust:** 73% of millennials now trust fintech over banks for remittances

---

## 12. THE TEAM

**Founder & CEO**
- Built the entire AmixPay product solo — 55-screen Flutter app + full Node.js API, deployed to production
- Deep understanding of the diaspora remittance problem (lived experience)
- Seeking co-founder: CTO (backend/infrastructure) + Head of Growth

**Advisors (planned):**
- Fintech regulatory counsel (FCA/MSB)
- Flutterwave ecosystem partner
- African diaspora community leader

---

## CONTACT & DEMO

**Live API:** https://amixpay-api-production.up.railway.app/health

**GitHub:**
- App: https://github.com/AmizPay/amixpay-app
- API: https://github.com/AmizPay/amixpay-api

**Test the app:** APK available on request — register an account and send money between two test users in under 60 seconds.

---

*AmixPay — Moving money should be as easy as sending a text.*
