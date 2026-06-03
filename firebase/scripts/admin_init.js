const fs = require("fs");
const path = require("path");
const admin = require("firebase-admin");

const DEFAULT_KEY_PATHS = [
  path.resolve(__dirname, "../keys/serviceAccount.json"),
  path.resolve(__dirname, "../keys/tfg-sales-record-serviceAccount.json"),
];

function resolveKeyPath(argv = process.argv) {
  const fromArg = argv.find((a, i) => argv[i - 1] === "--key");
  if (fromArg) {
    return path.resolve(fromArg);
  }
  if (process.env.GOOGLE_APPLICATION_CREDENTIALS) {
    return path.resolve(process.env.GOOGLE_APPLICATION_CREDENTIALS);
  }
  for (const candidate of DEFAULT_KEY_PATHS) {
    if (fs.existsSync(candidate)) {
      return candidate;
    }
  }
  return null;
}

function initializeAdmin(projectId, argv = process.argv) {
  const keyPath = resolveKeyPath(argv);
  if (keyPath) {
    admin.initializeApp({
      credential: admin.credential.cert(
        JSON.parse(fs.readFileSync(keyPath, "utf8")),
      ),
      projectId,
    });
    return { mode: "serviceAccount", keyPath };
  }
  if (process.env.FIRESTORE_EMULATOR_HOST) {
    admin.initializeApp({ projectId });
    return { mode: "emulator" };
  }
  admin.initializeApp({ projectId });
  return { mode: "applicationDefault" };
}

function credentialsHelp() {
  return (
    "Missing Firebase Admin credentials.\n\n" +
    "Quick setup:\n" +
    "  1. Open https://console.firebase.google.com/project/tfg-sales-record/settings/serviceaccounts/adminsdk\n" +
    "  2. Click「Generate new private key」→ save JSON\n" +
    "  3. Put file here (either name works):\n" +
    "       firebase\\keys\\serviceAccount.json\n" +
    "       firebase\\keys\\tfg-sales-record-serviceAccount.json\n" +
    "  4. Run again:\n" +
    "       npm run init:counters:dry-run\n" +
    "       npm run init:counters\n\n" +
    "Or set env var (CMD):\n" +
    "  set GOOGLE_APPLICATION_CREDENTIALS=C:\\path\\to\\key.json\n" +
    "Or pass flag:\n" +
    "  node scripts\\init_counters.js --key C:\\path\\to\\key.json"
  );
}

function isCredentialsError(err) {
  const msg = err && err.message ? err.message : String(err);
  return msg.includes("Could not load the default credentials");
}

module.exports = {
  initializeAdmin,
  credentialsHelp,
  isCredentialsError,
  resolveKeyPath,
};
