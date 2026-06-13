import 'package:flutter_test/flutter_test.dart';
import 'package:tfg_vday/backend/material_usage_report_service.dart';
import 'package:tfg_vday/backend/profit_summary_report_service.dart';

void main() {
  group('parseExpenseInput', () {
    test('parses currency-like values', () {
      expect(parseExpenseInput(''), 0);
      expect(parseExpenseInput('120'), 120);
      expect(parseExpenseInput('\$1,234.50'), 1234.5);
    });
  });

  group('calculateNetProfit', () {
    test('subtracts material and manual expenses from sales', () {
      expect(
        calculateNetProfit(
          totalSalesAmount: 1000,
          materialUsageCost: 200,
          utilityExpense: 50,
          staffSalaryClaim: 300,
          adhocExpense: 25,
        ),
        425,
      );
    });
  });

  group('totalMaterialUsageCost', () {
    test('multiplies usage qty by material unit cost', () {
      final total = totalMaterialUsageCost(
        const [
          MaterialUsageBreakdown(
            materialName: 'Rose',
            unit: 'stem',
            totalQty: 10,
            materialRefPath: 'materials/rose',
          ),
          MaterialUsageBreakdown(
            materialName: 'Wrap',
            unit: 'sheet',
            totalQty: 4,
            materialRefPath: 'materials/wrap',
          ),
        ],
        {
          'materials/rose': 2.5,
          'materials/wrap': 1,
        },
      );

      expect(total, 29);
    });
  });
}
