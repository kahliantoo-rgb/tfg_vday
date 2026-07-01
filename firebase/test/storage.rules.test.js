/**
 * Cloud Storage security rules tests (claims-based; no Firestore bridge).
 *
 * Run: npm run test:storage-rules (from firebase/)
 */
require("firebase/compat/app");
require("firebase/compat/firestore");
require("firebase/compat/storage");

const fs = require("fs");
const path = require("path");
const { describe, it, before, after, beforeEach } = require("node:test");
const {
  initializeTestEnvironment,
  assertFails,
  assertSucceeds,
} = require("@firebase/rules-unit-testing");

const PROJECT_ID = "demo-tfg-vday-storage";
const STORAGE_RULES = fs.readFileSync(
  path.resolve(__dirname, "../storage.rules"),
  "utf8",
);
const BUCKET = `gs://${PROJECT_ID}.appspot.com`;

let testEnv;

before(async () => {
  testEnv = await initializeTestEnvironment({
    projectId: PROJECT_ID,
    storage: { rules: STORAGE_RULES },
  });
});

after(async () => {
  await testEnv.cleanup();
});

beforeEach(async () => {
  await testEnv.clearStorage();
});

function staffContext(uid, claims = {}) {
  return testEnv.authenticatedContext(uid, {
    sub: uid,
    ...claims,
  });
}

function storageRef(uid, objectPath, claims) {
  const ctx = uid
    ? staffContext(uid, claims)
    : testEnv.unauthenticatedContext();
  return ctx.storage(BUCKET).ref(objectPath);
}

function uploadBytes(storageReference, bytes) {
  return storageReference.put(bytes, { contentType: "image/jpeg" });
}

describe("storage rules (claims-based)", () => {
  it("allows public read on delivery proof path", async () => {
    const objectPath = "delivery_proof_images/orderA/proof.jpg";
    await testEnv.withSecurityRulesDisabled(async (context) => {
      const bytes = new Uint8Array([0xff, 0xd8, 0xff, 0x00]);
      await context.storage(BUCKET).ref(objectPath).put(bytes, {
        contentType: "image/jpeg",
      });
    });
    await assertSucceeds(storageRef(null, objectPath).getDownloadURL());
  });

  it("denies unauthenticated write to delivery proof path", async () => {
    const bytes = new Uint8Array([0xff, 0xd8, 0xff, 0x00]);
    await assertFails(
      uploadBytes(
        storageRef(null, "delivery_proof_images/orderA/proof.jpg"),
        bytes,
      ),
    );
  });

  it("denies authenticated write without staff role claims", async () => {
    const bytes = new Uint8Array([0xff, 0xd8, 0xff, 0x00]);
    await assertFails(
      uploadBytes(
        storageRef("unknownUser", "delivery_proof_images/orderA/proof.jpg"),
        bytes,
      ),
    );
  });

  it("allows account staff to upload invoice payment proof (tenant path)", async () => {
    const bytes = new Uint8Array([0xff, 0xd8, 0xff, 0x00]);
    await assertSucceeds(
      uploadBytes(
        storageRef(
          "accountUser",
          "invoice_payment_proof_images/companyA/inv1/proof.jpg",
          { role: "account", companyId: "companyA" },
        ),
        bytes,
      ),
    );
  });

  it("denies account staff invoice proof for another company", async () => {
    const bytes = new Uint8Array([0xff, 0xd8, 0xff, 0x00]);
    await assertFails(
      uploadBytes(
        storageRef(
          "accountUser",
          "invoice_payment_proof_images/companyB/inv1/proof.jpg",
          { role: "account", companyId: "companyA" },
        ),
        bytes,
      ),
    );
  });

  it("allows florist staff to upload product image", async () => {
    const bytes = new Uint8Array([0xff, 0xd8, 0xff, 0x00]);
    await assertSucceeds(
      uploadBytes(
        storageRef(
          "floristUser",
          "product_images/product123/photo.jpg",
          { role: "florist", companyId: "companyA" },
        ),
        bytes,
      ),
    );
  });

  it("allows driver with assigned order claim to upload delivery proof", async () => {
    const bytes = new Uint8Array([0xff, 0xd8, 0xff, 0x00]);
    await assertSucceeds(
      uploadBytes(
        storageRef(
          "driverUser",
          "delivery_proof_images/orderA/proof.jpg",
          {
            role: "driver",
            companyId: "companyA",
            assignedOrderIds: ["orderA"],
          },
        ),
        bytes,
      ),
    );
  });

  it("denies driver without assigned order claim", async () => {
    const bytes = new Uint8Array([0xff, 0xd8, 0xff, 0x00]);
    await assertFails(
      uploadBytes(
        storageRef(
          "driverUser",
          "delivery_proof_images/orderB/proof.jpg",
          {
            role: "driver",
            companyId: "companyA",
            assignedOrderIds: ["orderA"],
          },
        ),
        bytes,
      ),
    );
  });

  it("allows user-scoped write under users/{uid}/", async () => {
    const bytes = new Uint8Array([0x01, 0x02]);
    await assertSucceeds(
      uploadBytes(storageRef("userA", "users/userA/avatar.jpg"), bytes),
    );
  });

  it("denies write to unknown top-level path", async () => {
    const bytes = new Uint8Array([0x01, 0x02]);
    await assertFails(
      uploadBytes(storageRef("userA", "random_bucket_path/file.bin"), bytes),
    );
  });
});
