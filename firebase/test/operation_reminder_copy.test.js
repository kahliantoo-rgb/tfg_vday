const test = require("node:test");
const assert = require("node:assert/strict");

const { buildTomorrowPrepCopy } = require("../functions/operation_reminder_copy");

test("buildTomorrowPrepCopy — no delivery", () => {
  const copy = buildTomorrowPrepCopy({ totalDelivery: 0, notStartedCount: 0 });
  assert.equal(copy.title, "Tomorrow's Preparation");
  assert.equal(copy.body, "No deliveries scheduled for tomorrow.");
  assert.equal(copy.deliveryCount, 0);
  assert.equal(copy.pendingCount, 0);
  assert.equal(copy.navTarget, "tomorrow_preparation");
});

test("buildTomorrowPrepCopy — one delivery pending", () => {
  const copy = buildTomorrowPrepCopy({ totalDelivery: 1, notStartedCount: 1 });
  assert.equal(copy.body, "1 delivery scheduled\n1 order pending preparation");
});

test("buildTomorrowPrepCopy — multiple deliveries pending", () => {
  const copy = buildTomorrowPrepCopy({ totalDelivery: 8, notStartedCount: 3 });
  assert.equal(
    copy.body,
    "8 deliveries scheduled\n3 orders pending preparation",
  );
});

test("buildTomorrowPrepCopy — all ready", () => {
  const copy = buildTomorrowPrepCopy({ totalDelivery: 8, notStartedCount: 0 });
  assert.equal(copy.body, "8 deliveries scheduled\nAll orders are ready.");
});

test("buildTomorrowPrepCopy — never uses programmer plural syntax", () => {
  const copy = buildTomorrowPrepCopy({ totalDelivery: 4, notStartedCount: 2 });
  assert.doesNotMatch(copy.body, /order\(s\)/);
  assert.doesNotMatch(copy.body, /not started/);
});
