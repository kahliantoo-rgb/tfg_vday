const test = require("node:test");
const assert = require("node:assert/strict");

const {
  calendarDay,
  isOperationReminderRecipient,
  isDeliveryOrder,
  needsProduction,
  resolveTargetDaysForTomorrowPrep,
  summarizeDeliveryOrders,
  buildTomorrowPrepMessage,
  buildTodayOpsMessage,
} = require("../functions/operation_reminders");

test("isOperationReminderRecipient excludes drivers and inactive users", () => {
  assert.equal(
    isOperationReminderRecipient({ uid: "u1", role: "florist", is_active: true }),
    true,
  );
  assert.equal(
    isOperationReminderRecipient({ uid: "u1", role: "account", is_active: true }),
    true,
  );
  assert.equal(
    isOperationReminderRecipient({ uid: "u1", role: "driver", is_active: true }),
    false,
  );
  assert.equal(
    isOperationReminderRecipient({ uid: "", role: "manager", is_active: true }),
    false,
  );
  assert.equal(
    isOperationReminderRecipient({ uid: "u1", role: "manager", is_active: false }),
    false,
  );
});

test("resolveTargetDaysForTomorrowPrep expands Friday to weekend + Monday", () => {
  const friday = calendarDay(new Date(2026, 5, 12));
  assert.equal(friday.getDay(), 5);
  const days = resolveTargetDaysForTomorrowPrep(friday);
  assert.equal(days.length, 3);
  assert.equal(days[0].getDate(), 13);
  assert.equal(days[1].getDate(), 14);
  assert.equal(days[2].getDate(), 15);
});

test("summarizeDeliveryOrders counts not-started delivery orders", () => {
  const orders = [
    {
      ref: { path: "orders/o1" },
      data: {
        orderType: "Delivery",
        pickup_delivery: "Delivery",
        status: "pending",
      },
    },
    {
      ref: { path: "orders/o2" },
      data: {
        orderType: "Delivery",
        pickup_delivery: "Delivery",
        status: "processing",
      },
    },
    {
      ref: { path: "orders/o3" },
      data: {
        orderType: "Delivery",
        pickup_delivery: "Delivery",
        status: "ready_to_delivery",
      },
    },
    {
      ref: { path: "orders/o4" },
      data: {
        orderType: "Retail",
        pickup_delivery: "Retail",
        Order_Id: "TFG-JUN26-WI0001",
        status: "completed",
      },
    },
  ];

  const summary = summarizeDeliveryOrders(orders);
  assert.equal(summary.totalDelivery, 3);
  assert.equal(summary.notStartedCount, 2);
});

test("buildTomorrowPrepMessage uses professional SaaS copy", () => {
  const message = buildTomorrowPrepMessage({
    summary: {
      totalDelivery: 4,
      notStartedCount: 3,
    },
  });

  assert.equal(message.body, "4 deliveries scheduled\n3 orders pending preparation");
  assert.equal(message.title, "Tomorrow's Preparation");
  assert.equal(message.deliveryCount, 4);
  assert.equal(message.pendingCount, 3);
});

test("buildTodayOpsMessage returns null when nothing to remind", () => {
  const today = calendarDay(new Date(2026, 5, 15));
  const message = buildTodayOpsMessage({
    targetDay: today,
    summary: {
      totalDelivery: 2,
      notStartedCount: 0,
    },
  });
  assert.equal(message, null);
});

test("needsProduction ignores completed and cancelled orders", () => {
  assert.equal(needsProduction({ status: "pending" }), true);
  assert.equal(needsProduction({ orderstatus: "processing" }), true);
  assert.equal(needsProduction({ status: "completed" }), false);
  assert.equal(needsProduction({ orderstatus: "cancelled" }), false);
});

test("isDeliveryOrder excludes pickup and retail", () => {
  assert.equal(
    isDeliveryOrder({ orderType: "Delivery", pickup_delivery: "Delivery" }),
    true,
  );
  assert.equal(
    isDeliveryOrder({ orderType: "Delivery", pickup_delivery: "Pick Up" }),
    false,
  );
  assert.equal(
    isDeliveryOrder({
      orderType: "Retail",
      pickup_delivery: "Retail",
      Order_Id: "TFG-JUN26-WI0001",
    }),
    false,
  );
});
