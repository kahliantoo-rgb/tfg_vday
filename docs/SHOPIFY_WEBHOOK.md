# Shopify Webhook Integration

Shopify **orders/create** webhooks are imported into ERP as Firestore `orders` + `Order_item`, with `staff_notices` and `audit_logs`. Existing POS, PDF, receipt printing, deleted orders, and tenant flows are unchanged.

---

## Architecture

```
Shopify Store
    │ orders/create webhook (HMAC signed)
    ▼
Cloud Function: shopifyOrderCreated
    │ verify x-shopify-hmac-sha256
    ├─► orders (+ source, externalOrderId, externalOrderName)
    ├─► Order_item (line items)
    ├─► staff_notices (admin / florist recipients)
    └─► audit_logs (shopify_order_imported)
```

**Status mapping:** Shopify imports use existing ERP status `pending` / `orderstatus: pending`. Staff continue the normal flow: pending → processing → ready_to_delivery → …

---

## Configuration

### Staging (default company)

| Item | Value |
|------|-------|
| Firebase project | `tfg-vday-record-staging` |
| Company doc id | **`staging_company`** |
| Company name | TFG Staging Florist |
| Created by | `npm run bootstrap:staging` |

```bash
cd firebase

# 1. Ensure staging company exists
npm run bootstrap:staging

# 2. Write Functions config (company id)
npm run config:shopify:staging

# 3. Add Shopify signing secret when ready
node scripts/configure_shopify_webhook.js --env staging --secret "shpss_YOUR_SECRET"

# 4. Counters for ERP order ids (default_delivery_*)
npm run init:counters -- --project tfg-vday-record-staging
```

Committed reference: [`firebase/config/shopify.staging.json`](../firebase/config/shopify.staging.json)

### Production

```bash
cd firebase
node scripts/configure_shopify_webhook.js --env production \
  --company-id YOUR_PRODUCTION_COMPANIES_DOC_ID \
  --secret "shpss_YOUR_SECRET"
```

| Variable | Purpose |
|----------|---------|
| `SHOPIFY_WEBHOOK_SECRET` | HMAC secret from Shopify webhook settings |
| `SHOPIFY_DEFAULT_COMPANY_ID` | Firestore `Companies/{id}` for imported orders |

---

## Deploy

```bash
cd firebase
npm install
cd functions && npm install && cd ..
npm run test:shopify
npm run deploy:functions:staging
# smoke test, then:
npm run deploy:functions:production
firebase deploy --only firestore:indexes --project production
```

---

## Shopify Webhook URL

```
https://<region>-<project-id>.cloudfunctions.net/shopifyOrderCreated
```

```bash
firebase functions:list --project production
```

---

## Shopify Admin Setup

1. Shopify Admin → Settings → Notifications → Webhooks
2. Create webhook: **Order creation** · JSON
3. URL: function URL above
4. Copy signing secret → `SHOPIFY_WEBHOOK_SECRET`
5. Run `npm run init:counters` if counters missing

---

## Testing

### Postman / curl

```bash
SECRET="your-webhook-secret"
BODY='{"id":999001,"name":"#9001","order_number":9001,"total_price":"50.00","financial_status":"paid","customer":{"first_name":"Test","last_name":"Buyer"},"line_items":[{"name":"Rose Box","quantity":1,"price":"50.00"}]}'
HMAC=$(printf '%s' "$BODY" | openssl dgst -sha256 -hmac "$SECRET" -binary | base64)

curl -X POST "https://YOUR-FUNCTION-URL/shopifyOrderCreated" \
  -H "Content-Type: application/json" \
  -H "x-shopify-hmac-sha256: $HMAC" \
  -d "$BODY"
```

Invalid HMAC → **401**. Duplicate `id` → **200** with `"duplicate": true`.

### Firestore

| Collection | Verify |
|------------|--------|
| `orders` | `source`, `externalOrderId`, `status == pending` |
| `Order_item` | line items linked by `orderRef` |
| `staff_notices` | `type == shopify_order_imported`, `order_ref` |
| `audit_logs` | `action == shopify_order_imported` |

### ERP app

Dashboard → bell → **New Shopify Order** → tap → Order Detail.
