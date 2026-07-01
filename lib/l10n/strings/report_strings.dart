/// Report pages (sales, material usage, profit summary).
const Map<String, Map<String, String>> reportStrings = {
  'report.dateRange': {
    'en': 'Date range',
    'zh': '日期范围',
    'ms': 'Julat tarikh',
  },
  'report.dateRangeToday': {
    'en': 'Date range (Today)',
    'zh': '日期范围（今天）',
    'ms': 'Julat tarikh (Hari ini)',
  },
  'report.dateFrom': {
    'en': 'From',
    'zh': '从',
    'ms': 'Dari',
  },
  'report.dateTo': {
    'en': 'To',
    'zh': '至',
    'ms': 'Hingga',
  },
  'report.selectStartDate': {
    'en': 'Select start date',
    'zh': '选择开始日期',
    'ms': 'Pilih tarikh mula',
  },
  'report.selectEndDate': {
    'en': 'Select end date',
    'zh': '选择结束日期',
    'ms': 'Pilih tarikh akhir',
  },
  'report.totalOrders': {
    'en': 'Total orders',
    'zh': '订单总数',
    'ms': 'Jumlah pesanan',
  },
  'report.totalSales': {
    'en': 'Total sales',
    'zh': '销售总额',
    'ms': 'Jumlah jualan',
  },
  'report.products': {
    'en': 'Products',
    'zh': '产品',
    'ms': 'Produk',
  },
  'report.noProductsSold': {
    'en': 'No products sold in this date range.',
    'zh': '此日期范围内无产品销售。',
    'ms': 'Tiada produk dijual dalam julat tarikh ini.',
  },
  'report.productName': {
    'en': 'Product name',
    'zh': '产品名称',
    'ms': 'Nama produk',
  },
  'report.totalAmount': {
    'en': 'Total amount',
    'zh': '总金额',
    'ms': 'Jumlah amaun',
  },
  'report.paymentMethods': {
    'en': 'Payment methods',
    'zh': '付款方式',
    'ms': 'Kaedah bayaran',
  },
  'report.noPaidOrders': {
    'en': 'No paid orders in this date range.',
    'zh': '此日期范围内无已付款订单。',
    'ms': 'Tiada pesanan berbayar dalam julat tarikh ini.',
  },
  'report.paymentRowTotal': {
    'en': '{label} total',
    'zh': '{label} 合计',
    'ms': 'Jumlah {label}',
  },
  'report.paymentOneOrder': {
    'en': '{count} order',
    'zh': '{count} 笔订单',
    'ms': '{count} pesanan',
  },
  'report.paymentManyOrders': {
    'en': '{count} orders',
    'zh': '{count} 笔订单',
    'ms': '{count} pesanan',
  },
  'report.sales.title': {
    'en': 'Sales Report',
    'zh': '销售报表',
    'ms': 'Laporan Jualan',
  },
  'report.materialUsage.title': {
    'en': 'Material Usage',
    'zh': '物料用量',
    'ms': 'Penggunaan Bahan',
  },
  'report.materialUsage.subtitle': {
    'en': 'Estimated from paid orders × product recipes.',
    'zh': '根据已付款订单 × 产品配方估算。',
    'ms': 'Anggaran daripada pesanan berbayar × resipi produk.',
  },
  'report.materialUsage.paidOrders': {
    'en': 'Paid orders',
    'zh': '已付款订单',
    'ms': 'Pesanan berbayar',
  },
  'report.materialUsage.materialsUsed': {
    'en': 'Materials used',
    'zh': '已用物料',
    'ms': 'Bahan digunakan',
  },
  'report.materialUsage.materials': {
    'en': 'Materials',
    'zh': '物料',
    'ms': 'Bahan',
  },
  'report.materialUsage.materialCol': {
    'en': 'Material',
    'zh': '物料',
    'ms': 'Bahan',
  },
  'report.materialUsage.noUsage': {
    'en': 'No material usage for this date range. '
        'Add recipes to products or check paid orders.',
    'zh': '此日期范围内无物料用量。请为产品添加配方或检查已付款订单。',
    'ms': 'Tiada penggunaan bahan untuk julat tarikh ini. '
        'Tambah resipi pada produk atau semak pesanan berbayar.',
  },
  'report.materialUsage.soldWithoutRecipe': {
    'en': 'Sold without recipe',
    'zh': '已售但无配方',
    'ms': 'Dijual tanpa resipi',
  },
  'report.materialUsage.noRecipeHint': {
    'en': 'These products were sold but have no recipe linked yet.',
    'zh': '这些产品已售出但尚未关联配方。',
    'ms': 'Produk ini dijual tetapi belum dipautkan resipi.',
  },
  'report.materialUsage.soldCount': {
    'en': '{count} sold',
    'zh': '售出 {count}',
    'ms': '{count} dijual',
  },
  'report.profit.title': {
    'en': 'Profit Summary',
    'zh': '利润汇总',
    'ms': 'Ringkasan Untung',
  },
  'report.profit.manualExpenses': {
    'en': 'Manual expenses',
    'zh': '手动费用',
    'ms': 'Perbelanjaan manual',
  },
  'report.profit.manualHint': {
    'en': 'Enter amounts for this period. Material cost is calculated automatically.',
    'zh': '输入本期间金额。物料成本自动计算。',
    'ms': 'Masukkan amaun untuk tempoh ini. Kos bahan dikira secara automatik.',
  },
  'report.profit.utility': {
    'en': 'Utility expense',
    'zh': '水电杂费',
    'ms': 'Perbelanjaan utiliti',
  },
  'report.profit.staffSalary': {
    'en': 'Total staff salary claim',
    'zh': '员工薪资申报总额',
    'ms': 'Jumlah tuntutan gaji staf',
  },
  'report.profit.adhoc': {
    'en': 'Adhoc expense',
    'zh': '临时费用',
    'ms': 'Perbelanjaan ad hoc',
  },
  'report.profit.adhocRemark': {
    'en': 'Adhoc remark',
    'zh': '临时费用备注',
    'ms': 'Catatan ad hoc',
  },
  'report.profit.adhocRemarkHint': {
    'en': 'Optional note for adhoc expense',
    'zh': '临时费用备注（可选）',
    'ms': 'Nota pilihan untuk perbelanjaan ad hoc',
  },
  'report.profit.summary': {
    'en': 'Summary',
    'zh': '汇总',
    'ms': 'Ringkasan',
  },
  'report.profit.materialCost': {
    'en': 'Material usage cost',
    'zh': '物料用量成本',
    'ms': 'Kos penggunaan bahan',
  },
  'report.profit.staffSalaryShort': {
    'en': 'Staff salary claim',
    'zh': '员工薪资申报',
    'ms': 'Tuntutan gaji staf',
  },
  'report.profit.totalExpenses': {
    'en': 'Total expenses',
    'zh': '费用合计',
    'ms': 'Jumlah perbelanjaan',
  },
  'report.profit.netProfit': {
    'en': 'Net profit',
    'zh': '净利润',
    'ms': 'Untung bersih',
  },
};
