# Staging environment

Production must **not** receive Firestore rule changes without a staging pass. This project uses two Firebase projects:

| Alias | Project ID | Purpose |
|-------|------------|---------|
| `staging` | `tfg-sales-record-staging` | Rules/hosting rehearsal, smoke tests |
| `production` | `tfg-sales-record` | Live peak operations |

Config: [`firebase/.firebaserc`](../firebase/.firebaserc)

---

## One-time setup

1. Firebase Console → **Add project** → `tfg-sales-record-staging`
2. Enable **Authentication**, **Firestore**, **Storage**, **Hosting** (mirror production)
3. Import rules/indexes from this repo (no prod data copy required for rules-only rehearsal)
4. Create test `users/{uid}`, `Companies`, and counters:

   ```bash
   cd firebase
   set GOOGLE_APPLICATION_CREDENTIALS=C:\path\to\staging-serviceAccount.json
   set FIREBASE_PROJECT=tfg-sales-record-staging
   npm run init:counters
   ```

5. Optional: point a staging Android build at the staging `google-services.json` (separate flavor — not in repo by default)

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
