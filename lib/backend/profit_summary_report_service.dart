import '/backend/daily_sales_report_service.dart';
import '/backend/material_cost_snapshot_helpers.dart';
import '/backend/material_usage_report_service.dart';

class ProfitSummaryReportData {
  const ProfitSummaryReportData({
    required this.startDate,
    required this.endDate,
    required this.totalOrders,
    required this.totalSalesAmount,
    required this.materialUsageCost,
  });

  final DateTime startDate;
  final DateTime endDate;
  final int totalOrders;
  final double totalSalesAmount;
  final double materialUsageCost;

  bool get isSingleDay =>
      calendarDay(startDate) == calendarDay(endDate);
}

double totalMaterialUsageCost(
  List<MaterialUsageBreakdown> breakdown,
  Map<String, double> costByMaterialRefPath,
) {
  var total = 0.0;
  for (final row in breakdown) {
    final refPath = row.materialRefPath;
    if (refPath == null || refPath.isEmpty) {
      continue;
    }
    final unitCost = costByMaterialRefPath[refPath] ?? 0;
    total += row.totalQty * unitCost;
  }
  return total;
}

double parseExpenseInput(String raw) {
  final trimmed = raw.trim();
  if (trimmed.isEmpty) {
    return 0;
  }
  final cleaned = trimmed.replaceAll(RegExp(r'[^\d.-]'), '');
  if (cleaned.isEmpty) {
    return 0;
  }
  return double.tryParse(cleaned) ?? 0;
}

double calculateTotalExpenses({
  required double materialUsageCost,
  required double utilityExpense,
  required double staffSalaryClaim,
  required double adhocExpense,
}) =>
    materialUsageCost +
    utilityExpense +
    staffSalaryClaim +
    adhocExpense;

double calculateNetProfit({
  required double totalSalesAmount,
  required double materialUsageCost,
  required double utilityExpense,
  required double staffSalaryClaim,
  required double adhocExpense,
}) =>
    totalSalesAmount -
    calculateTotalExpenses(
      materialUsageCost: materialUsageCost,
      utilityExpense: utilityExpense,
      staffSalaryClaim: staffSalaryClaim,
      adhocExpense: adhocExpense,
    );

Future<ProfitSummaryReportData> buildProfitSummaryReportDataRange({
  required DateTime startDate,
  required DateTime endDate,
}) async {
  final range = normalizeSalesReportDateRange(
    startDate: startDate,
    endDate: endDate,
  );

  final salesReport = await buildDailySalesReportRange(
    startDate: range.start,
    endDate: range.end,
  );
  final paidOrders = await loadPaidOrdersForSalesReportRange(
    startDate: range.start,
    endDate: range.end,
  );

  return ProfitSummaryReportData(
    startDate: range.start,
    endDate: range.end,
    totalOrders: salesReport.totalOrders,
    totalSalesAmount: salesReport.totalSalesAmount,
    materialUsageCost: await resolveMaterialUsageCostForPaidOrders(paidOrders),
  );
}

Future<ProfitSummaryReportData> buildProfitSummaryReportData(DateTime day) =>
    buildProfitSummaryReportDataRange(startDate: day, endDate: day);
