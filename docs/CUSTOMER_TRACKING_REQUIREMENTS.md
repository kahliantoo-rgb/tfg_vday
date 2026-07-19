# Customer Order Tracking — Requirements

Last updated: 2026-07-18  
Status: MVP requirements captured (not implemented)

## Decisions (owner answers)

| # | Topic | Decision |
|---|--------|----------|
| 1 | Lookup | **Both**: order ID + phone last 4 digits, **and** WhatsApp short link |
| 2 | Visible fields | Status; delivery/pickup date & time slot; recipient name; delivery proof photos. **No amount / price** |
| 3 | Languages | **EN + ZH + MS** |
| 4 | Link send | **Delivery:** auto when `out_of_delivery`. **Pick Up:** auto when **Ready for Pickup** (`ready_to_delivery`) |
| 5 | Order types | **Delivery + Pick Up** (not Retail) |
| 6 | Branding | Existing **company name + logo** from company profile |
| 7 | Recipient name | **Masked** (e.g. `Ali***`) |

## Implied product rules

- Staff app stays staff-only; tracking is a **separate lightweight public page** + trusted backend (Cloud Function), not direct public Firestore reads.
- Hide: totals, payment, discounts, internal remarks, staff/driver PII beyond what’s needed for status.
- Short link should open tracking without typing; manual lookup remains a fallback.
- **Delivery** auto WhatsApp on `out_of_delivery`; **Pick Up** auto WhatsApp on Ready for Pickup (`ready_to_delivery`).
- Recipient display name is **masked**.

## Open points (confirm later)

1. Short-link TTL / revoke after N days?
2. Hosting path: e.g. `https://…/track` or company subdomain?
3. WhatsApp send: Business API vs staff device / existing channel?

## Suggested MVP scope

1. Public track page (EN/ZH/MS) + company logo/name  
2. CF: resolve by token **or** orderId + phone last4 → safe payload only (masked recipient, no amounts)  
3. Auto WhatsApp: Delivery → `out_of_delivery`; Pick Up → Ready for Pickup  
4. Show delivery proof when available  

## Non-goals (this phase)

- Customer self-order / cart / payment gateway  
- Live driver GPS map  
- Customer edit/cancel order  
- Discount voucher portal  
