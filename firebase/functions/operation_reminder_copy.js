const TOMORROW_PREP_TITLE = "Tomorrow's Preparation";
const TOMORROW_PREP_NAV_TARGET = "tomorrow_preparation";

/**
 * Builds tomorrow prep notification body copy (English).
 * Returns structured counts for client-side i18n.
 */
function buildTomorrowPrepCopy(summary) {
  const deliveryCount = summary.totalDelivery;
  const pendingCount = summary.notStartedCount;

  if (deliveryCount === 0) {
    return {
      title: TOMORROW_PREP_TITLE,
      body: "No deliveries scheduled for tomorrow.",
      deliveryCount: 0,
      pendingCount: 0,
      navTarget: TOMORROW_PREP_NAV_TARGET,
    };
  }

  const line1 =
    deliveryCount === 1
      ? "1 delivery scheduled"
      : `${deliveryCount} deliveries scheduled`;

  let line2;
  if (pendingCount === 0) {
    line2 = "All orders are ready.";
  } else if (pendingCount === 1) {
    line2 = "1 order pending preparation";
  } else {
    line2 = `${pendingCount} orders pending preparation`;
  }

  return {
    title: TOMORROW_PREP_TITLE,
    body: `${line1}\n${line2}`,
    deliveryCount,
    pendingCount,
    navTarget: TOMORROW_PREP_NAV_TARGET,
  };
}

module.exports = {
  TOMORROW_PREP_TITLE,
  TOMORROW_PREP_NAV_TARGET,
  buildTomorrowPrepCopy,
};
