# AGENTS.md

## Cursor Cloud specific instructions

This is a **Flutter** (Dart) app (`tfg_vday` / "EmberCore ERP") — an internal, staff-only florist
POS + order + delivery app — with a **Firebase** backend (Auth, Firestore, Storage, Cloud
Functions). Targets Web (PWA), Android, and iOS. See `README.md`, `docs/TECH_STACK.md`, and
`.github/workflows/ci.yml` for the authoritative toolchain and command reference.

### Toolchain (already provisioned in the VM)
- **Flutter stable** is installed at `~/flutter` and is on `PATH` via `~/.bashrc`
  (`export PATH="$HOME/flutter/bin:$PATH"`). If `flutter` is not found in a fresh non-login
  shell, re-source `~/.bashrc` or use the full path `~/flutter/bin/flutter`.
- **Java 21**, **Node**, and **Google Chrome** are preinstalled. Java is required by the Firebase
  emulators.
- The startup update script runs `flutter pub get` (root) and `npm install` in both `firebase/`
  and `firebase/functions/`. Dependencies are already installed on session start.

### Lint / test / build commands (standard — see `.github/workflows/ci.yml`)
- Lint (client): `flutter analyze --no-fatal-infos --no-fatal-warnings` (CI only fails on
  analyzer *errors*; the FlutterFlow-generated code produces thousands of infos/warnings — this
  is expected).
- Tests (client): `flutter test`.
- Backend rules/integration tests: `cd firebase && npm run test:firebase` (spins up the
  Firestore + Storage emulators via `firebase emulators:exec`; needs Java).
- Functions lint: `cd firebase/functions && npm run lint`.

### Known, pre-existing test caveat (not an environment problem)
- `test/order_whatsapp_import_helpers_test.dart` has one **date-dependent** test
  ("...May date and TFG carousel name") that hard-codes `2026-05-28`. Because a bare `28/5`
  with no year rolls forward to the next occurrence, it now resolves to `2027-05-28` and the
  test fails whenever the current date is past May 2026. All other tests pass
  (317/318 at time of writing). Do not "fix" this as part of environment setup.

### Running the app
- Dev mode is `flutter run -d chrome` (or `-d web-server --web-port <port>`). For staging Firebase
  add `--dart-define=APP_ENV=staging` (defaults to production).
- **Important:** the client is wired to the *live* Firebase projects (`tfg-sales-record` prod /
  `tfg-vday-record-staging` staging) — there is **no built-in emulator wiring** in
  `lib/backend/firebase/firebase_config.dart`, and web config keys are hard-coded there. Login is
  **staff-only** (email/password, admin-provisioned `users/{uid}` profile with a role); public
  "Sign up" only files a registration request pending admin approval. So you **cannot** log in and
  exercise core features without real staff credentials **unless** you run against the local
  Firebase Emulator Suite (below).

### Running fully locally against the Firebase Emulator Suite (self-contained demo)
This is the only way to log in and exercise core flows (POS, orders, customers) without live
credentials. It requires a few **non-obvious** workarounds specific to a sandboxed/headless VM
browser. These are temporary dev workarounds — do **not** commit changes to app source:

1. **Wire emulators.** Temporarily, in `initFirebase()` (after `Firebase.initializeApp`), connect
   `FirebaseFirestore.instance.useFirestoreEmulator('localhost', 8080)`,
   `FirebaseAuth.instance.useAuthEmulator('localhost', 9099)`, and
   `FirebaseStorage.instance.useStorageEmulator('localhost', 9199)` (gate behind a
   `--dart-define` so it stays inert by default).
2. **Start emulators.** `firebase.json` has no `auth` emulator entry, so add one (e.g. a temporary
   config file with `emulators.auth.port = 9099`) and run
   `npx firebase emulators:start --only auth,firestore,storage --project tfg-vday-record-staging`.
3. **Seed an admin.** Using `firebase-admin` (installed in `firebase/`) with
   `FIRESTORE_EMULATOR_HOST=127.0.0.1:8080` and `FIREBASE_AUTH_EMULATOR_HOST=127.0.0.1:9099`,
   create an Auth user, a `Companies/{id}` doc (`Company_name`, `is_active: true`), and a
   `users/{uid}` doc with `role: 'admin'` and `companyRef -> Companies/{id}`. Rules resolve the
   staff role by *reading the `users/{uid}` doc* (not custom claims), and an `admin` gets its
   permissions from the static role matrix, so no `role_permissions` doc is needed. Landing route
   for `admin` is the Sales Dashboard; `superadmin` lands on Company Selection.
4. **Browser gotchas when running the web build in this VM's Chrome:**
   - The `flutter_bluetooth_printer_web` plugin reads `navigator.bluetooth` during web bootstrap
     and throws `Null is not a subtype of JSObject` (blank page) when it is absent
     (headless/sandbox). Stub it (e.g. define a no-op `navigator.bluetooth` in `web/index.html`
     before the Flutter bootstrap).
   - `main()` awaits `Notification.requestPermission()`, which **hangs forever** in an automated
     Chrome with no one to answer the prompt (app stays blank). Launch Chrome with
     `--deny-permission-prompts` (or grant notifications) so it resolves.
   - Flutter web uses CanvasKit (WebGL). This VM's Chrome disables software WebGL by default;
     launch with `--enable-unsafe-swiftshader` (and `--in-process-gpu` to avoid GPU-IPC command
     buffer failures) or the UI never paints.
   - The DDC debug build (`flutter run -d web-server`) is flaky to render here (loads ~1700
     modules, often never runs `main`). A `flutter build web --profile` bundle served statically
     (e.g. `python3 -m http.server` from `build/web/`) is far more reliable for a demo. `flutter`
     compiles/serves fine either way.
   - When driving a sandbox Chrome, launch the real binary `/opt/google/chrome/chrome` with
     `--user-data-dir` + `--remote-debugging-port` (the `google-chrome` wrapper forces the
     default profile and just opens a tab in the already-running instance, ignoring your flags).

### Cloud Functions / deploy
- Two npm packages: `firebase/` (deploy + rules-test tooling) and `firebase/functions/` (the
  Cloud Functions runtime, Node 20). Each has its own `node_modules`.
- Shopify import needs `SHOPIFY_WEBHOOK_SECRET` / `SHOPIFY_DEFAULT_COMPANY_ID`; the core app works
  without functions.
