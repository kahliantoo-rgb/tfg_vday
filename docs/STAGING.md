# Staging environment

Production must **not** receive Firestore rule changes without a staging pass. This project uses two Firebase projects:

| Alias | Project ID | Purpose |
|-------|------------|---------|
| `staging` | `tfg-vday-record-staging` | Rules/hosting rehearsal, smoke tests |
| `production` | `tfg-sales-record` | Live peak operations |

Config: [`firebase/.firebaserc`](../firebase/.firebaserc)

---

## One-time setup

1. Firebase Console → **Add project** → `tfg-vday-record-staging`
2. Enable **Authentication**, **Firestore**, **Storage**, **Hosting** (mirror production)
3. Import rules/indexes from this repo (no prod data copy required for rules-only rehearsal)
4. Create test `users/{uid}`, `Companies`, and counters:

   ```bash
   cd firebase
   set GOOGLE_APPLICATION_CREDENTIALS=C:\path\to\staging-serviceAccount.json
   npm run bootstrap:staging
   npm run init:counters -- --project tfg-vday-record-staging
   ```

   `bootstrap:staging` creates `Companies/staging_company`, order counters, and the
   Firestore profile for `staging.admin@tfg-vday.test` (Auth user must exist or is created).

5. **Staging clone app (Android)** — installs as **TFG Staging** next to production:

   | Item | Value |
   |------|-------|
   | Package | `com.tfg_staging` |
   | Firebase project | `tfg-vday-record-staging` |
   | Test login | `staging.admin@tfg-vday.test` / `StagingTest2026!` |

   **One-time:** Firebase Console → staging project → Add **Android** app (`com.tfg_staging`) → download `google-services.json` →  
   `android/app/src/staging/google-services.json`

   **Run:**

   ```powershell
   powershell -ExecutionPolicy Bypass -File scripts/run_staging_android.ps1
   # or
   flutter run --flavor staging --dart-define=APP_ENV=staging
   ```

   **Web staging (Firebase Hosting)** — use in phone/desktop browser, no APK transfer:

   | Item | Value |
   |------|-------|
   | URL | https://tfg-vday-record-staging.web.app |
   | Firebase Web app | `TFG Staging Web` (registered in staging project) |
   | Test login | `staging.admin@tfg-vday.test` / `StagingTest2026!` |

   **Build + deploy:**

   ```powershell
   powershell -ExecutionPolicy Bypass -File scripts/deploy_staging_web.ps1
   ```

   **Local preview only:**

   ```powershell
   flutter run -d chrome --dart-define=APP_ENV=staging
   ```

   **Android staging** (optional side-by-side APK): see `scripts/run_staging_android.ps1`.

6. `google-services.json` lives under `android/app/src/{production,staging}/` (not repo root).

7. **Shopify webhook (staging)** — imports attach to `Companies/staging_company`:

   | Item | Value |
   |------|-------|
   | Company doc id | `staging_company` |
   | Firebase project | `tfg-vday-record-staging` |

   ```bash
   cd firebase
   # optional: verify Companies doc (needs GOOGLE_APPLICATION_CREDENTIALS)
   npm run config:shopify:staging:verify

   # set Functions config (company id; add --secret when you have Shopify signing secret)
   npm run config:shopify:staging
   # or with secret:
   node scripts/configure_shopify_webhook.js --env staging --secret "shpss_YOUR_SECRET"

   npm run init:counters -- --project tfg-vday-record-staging
   npm run deploy:functions:staging
   ```

   See [SHOPIFY_WEBHOOK.md](SHOPIFY_WEBHOOK.md).

---

## Deploy workflow (rules + hosting)

**Always staging first:**

```bash
cd firebase

# 1. Emulator + unit tests (no credentials)
npm run test:firebase

# 2. Deploy to staging
npm run deploy:rules:staging
npm run deploy:hosting:staging    # after flutter build web → copy to firebase/public

# 3. Smoke on staging URL (see Firebase Console → Hosting)
#    - Login, Create Order, Retail + Delivery paths
#    - Driver page, permission-denied paths from SMOKE_TEST_LOG

# 4. Promote to production (tech lead only)
npm run deploy:rules:production
npm run deploy:hosting:production
```

Combined shortcuts:

```bash
npm run deploy:staging      # rules + hosting → staging
npm run deploy:production   # rules + hosting → production (run only after staging PASS)
```

---

## What stays production-only

| Item | Notes |
|------|-------|
| Real customer orders | Never copy prod Firestore to staging |
| Counter values | Staging uses its own `counter/{companyId}_*` docs |
| Crashlytics / Performance | Separate Firebase apps per project |
| Service accounts | Use staging key for staging scripts only |

---

## CI gate

GitHub Actions **does not** auto-deploy rules to production. The `firestore-rules` job runs `npm run test:firebase` on every push/PR. Production deploy remains a **manual** `deploy:production` after staging sign-off (record in [SMOKE_TEST_LOG.md](SMOKE_TEST_LOG.md)).
