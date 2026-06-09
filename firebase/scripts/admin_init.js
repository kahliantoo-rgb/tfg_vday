const fs = require("fs");
const path = require("path");
const admin = require("firebase-admin");

const DEFAULT_KEY_PATHS = [
  path.resolve(__dirname, "../keys/serviceAccount.json"),
  path.resolve(__dirname, "../keys/tfg-sales-record-serviceAccount.json"),
  path.resolve(__dirname, "../keys/tfg-vday-record-staging-serviceAccount.json"),
];

function readKeyProjectId(keyPath) {
  try {
    const json = JSON.parse(fs.readFileSync(keyPath, "utf8"));
    return json.project_id || null;
  } catch (_) {
    return null;
  }
}

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

function resolveKeyPathForProject(projectId, argv = process.argv) {
  const fromArg = argv.find((a, i) => argv[i - 1] === "--key");
  if (fromArg) {
    return path.resolve(fromArg);
  }
  if (process.env.GOOGLE_APPLICATION_CREDENTIALS) {
    return path.resolve(process.env.GOOGLE_APPLICATION_CREDENTIALS);
  }
  for (const candidate of DEFAULT_KEY_PATHS) {
    if (!fs.existsSync(candidate)) {
      continue;
    }
    if (readKeyProjectId(candidate) === projectId) {
      return candidate;
    }
  }
  return null;
}

function initializeAdmin(projectId, argv = process.argv) {
  const keyPath = resolveKeyPathForProject(projectId, argv);
  if (keyPath) {
    const keyProjectId = readKeyProjectId(keyPath);
    if (keyProjectId && keyProjectId !== projectId) {
      throw new Error(
        `Service account key is for "${keyProjectId}" but --project is "${projectId}". ` +
          `Download the Admin SDK key for ${projectId} or pass --key PATH.`,
      );
    }
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

function credentialsHelp(projectId = "tfg-sales-record") {
  return (
    `Missing Firebase Admin credentials for project "${projectId}".\n\n` +
    "Option A — staff login (no service account key):\n" +
    "  npm run repair:product-images:client -- --email YOUR@email.com --password PASS\n\n" +
    "Option B — service account key:\n" +
    `  1. Open https://console.firebase.google.com/project/${projectId}/settings/serviceaccounts/adminsdk\n` +
    "  2. Generate new private key → save JSON\n" +
    "  3. Save as firebase\\keys\\tfg-sales-record-serviceAccount.json\n" +
    "  4. Run again\n\n" +
    "Or: set GOOGLE_APPLICATION_CREDENTIALS=C:\\path\\to\\production-key.json"
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
  resolveKeyPathForProject,
};
