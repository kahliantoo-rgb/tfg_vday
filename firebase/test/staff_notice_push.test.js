const test = require("node:test");
const assert = require("node:assert/strict");

const {
  staffNoticeTitle,
  staffNoticeBody,
} = require("../functions/staff_notice_push");

test("staffNoticeTitle maps notice types", () => {
  assert.equal(staffNoticeTitle("order_created"), "New order");
  assert.equal(staffNoticeTitle("driver_assigned"), "Delivery assigned");
  assert.equal(staffNoticeTitle("shopify_order_imported"), "New Shopify Order");
  assert.equal(staffNoticeTitle("tomorrow_prep_reminder"), "Tomorrow's Preparation");
  assert.equal(staffNoticeTitle("today_ops_reminder"), "Today production reminder");
  assert.equal(staffNoticeTitle("special_procurement_reminder"), "Special purchase reminder");
});

test("staffNoticeBody formats order notice", () => {
  const body = staffNoticeBody({
    type: "order_created",
    order_id: "ORD-100",
    delivery_date: new Date("2026-06-11T00:00:00Z"),
    item_summary: "2x Rose Bouquet",
  });
  assert.match(body, /Order ORD-100/);
  assert.match(body, /Delivery 11 Jun 2026/);
  assert.match(body, /2x Rose Bouquet/);
});

test("staffNoticeBody uses Shopify message when present", () => {
  const body = staffNoticeBody({
    type: "shopify_order_imported",
    message: "Shopify #1234 imported",
    order_id: "ORD-200",
  });
  assert.equal(body, "Shopify #1234 imported");
});
