/// Invoice list, profile, edit, and confirm UI strings.
const Map<String, Map<String, String>> invoiceStrings = {
  'invoice.list.title': {
    'en': 'Invoice List',
    'zh': '发票列表',
    'ms': 'Senarai Invois',
  },
  'invoice.list.noPermission': {
    'en': 'You do not have permission to view invoices.',
    'zh': '您无权查看发票。',
    'ms': 'Anda tiada kebenaran melihat invois.',
  },
  'invoice.list.invoiceNumber': {
    'en': 'Invoice number',
    'zh': '发票号',
    'ms': 'Nombor invois',
  },
  'invoice.list.customer': {
    'en': 'Customer',
    'zh': '客户',
    'ms': 'Pelanggan',
  },
  'invoice.list.customerHint': {
    'en': 'Search customer name or ID (e.g. TFG01)',
    'zh': '搜索客户姓名或编号（如 TFG01）',
    'ms': 'Cari nama atau ID pelanggan (cth. TFG01)',
  },
  'invoice.list.month': {
    'en': 'Month',
    'zh': '月份',
    'ms': 'Bulan',
  },
  'invoice.list.allMonths': {
    'en': 'All months',
    'zh': '全部月份',
    'ms': 'Semua bulan',
  },
  'invoice.list.creditTerm': {
    'en': 'Credit term',
    'zh': '信用条款',
    'ms': 'Terma kredit',
  },
  'invoice.list.allTerms': {
    'en': 'All terms',
    'zh': '全部条款',
    'ms': 'Semua terma',
  },
  'invoice.list.showVoided': {
    'en': 'Show voided',
    'zh': '显示已作废',
    'ms': 'Tunjuk dibatalkan',
  },
  'invoice.list.loadError': {
    'en': 'Could not load invoices.',
    'zh': '无法加载发票。',
    'ms': 'Tidak dapat memuatkan invois.',
  },
  'invoice.list.empty': {
    'en': 'No invoices found.',
    'zh': '未找到发票。',
    'ms': 'Tiada invois dijumpai.',
  },
  'invoice.list.voidTitle': {
    'en': 'Void invoices?',
    'zh': '作废发票？',
    'ms': 'Batalkan invois?',
  },
  'invoice.list.voidBody': {
    'en': 'Void {count} invoice(s)? Linked orders can be invoiced again.',
    'zh': '作废 {count} 张发票？关联订单可重新开票。',
    'ms': 'Batalkan {count} invois? Pesanan berkaitan boleh diinvois semula.',
  },
  'invoice.list.voidButton': {
    'en': 'Void',
    'zh': '作废',
    'ms': 'Batalkan',
  },
  'invoice.list.voidedSnack': {
    'en': 'Invoice(s) voided.',
    'zh': '发票已作废。',
    'ms': 'Invois dibatalkan.',
  },
  'invoice.list.selectPending': {
    'en': 'Select pending invoice(s) to mark paid.',
    'zh': '请选择待付发票标记为已付。',
    'ms': 'Pilih invois tertunda untuk tandakan dibayar.',
  },
  'invoice.list.markedPaidSnack': {
    'en': 'Invoice(s) marked paid.',
    'zh': '发票已标记为已付。',
    'ms': 'Invois ditandakan dibayar.',
  },
  'invoice.list.markPaid': {
    'en': 'Mark paid',
    'zh': '标记已付',
    'ms': 'Tandakan dibayar',
  },
  'invoice.list.subtitleLine': {
    'en': '{date} · {amount} · {count} order(s)',
    'zh': '{date} · {amount} · {count} 个订单',
    'ms': '{date} · {amount} · {count} pesanan',
  },
  'invoice.status.pending': {
    'en': 'Pending',
    'zh': '待付',
    'ms': 'Tertunda',
  },
  'invoice.status.paid': {
    'en': 'Paid',
    'zh': '已付',
    'ms': 'Dibayar',
  },
  'invoice.status.voided': {
    'en': 'Voided',
    'zh': '已作废',
    'ms': 'Dibatalkan',
  },
  'invoice.profile.title': {
    'en': 'Invoice Profile',
    'zh': '发票详情',
    'ms': 'Profil Invois',
  },
  'invoice.profile.notFound': {
    'en': 'Invoice not found',
    'zh': '未找到发票',
    'ms': 'Invois tidak dijumpai',
  },
  'invoice.profile.loadError': {
    'en': 'Could not load invoice.',
    'zh': '无法加载发票。',
    'ms': 'Tidak dapat memuatkan invois.',
  },
  'invoice.profile.noPermission': {
    'en': 'You do not have permission to view this invoice.',
    'zh': '您无权查看此发票。',
    'ms': 'Anda tiada kebenaran melihat invois ini.',
  },
  'invoice.profile.dateLine': {
    'en': 'Date: {date}',
    'zh': '日期：{date}',
    'ms': 'Tarikh: {date}',
  },
  'invoice.profile.paidLine': {
    'en': 'Paid: {date}',
    'zh': '已付：{date}',
    'ms': 'Dibayar: {date}',
  },
  'invoice.profile.creditTermLine': {
    'en': 'Credit term: {term}',
    'zh': '信用条款：{term}',
    'ms': 'Terma kredit: {term}',
  },
  'invoice.profile.customerIdLine': {
    'en': 'Customer ID: {id}',
    'zh': '客户编号：{id}',
    'ms': 'ID Pelanggan: {id}',
  },
  'invoice.profile.phoneLine': {
    'en': 'Phone: {phone}',
    'zh': '电话：{phone}',
    'ms': 'Telefon: {phone}',
  },
  'invoice.profile.emailLine': {
    'en': 'Email: {email}',
    'zh': '邮箱：{email}',
    'ms': 'E-mel: {email}',
  },
  'invoice.profile.addressLine': {
    'en': 'Address: {address}',
    'zh': '地址：{address}',
    'ms': 'Alamat: {address}',
  },
  'invoice.profile.openCustomer': {
    'en': 'Open customer profile',
    'zh': '打开客户资料',
    'ms': 'Buka profil pelanggan',
  },
  'invoice.profile.noLineItems': {
    'en': 'No line items found.',
    'zh': '无明细行。',
    'ms': 'Tiada item baris dijumpai.',
  },
  'invoice.profile.ordersLine': {
    'en': 'Orders: {orders}',
    'zh': '订单：{orders}',
    'ms': 'Pesanan: {orders}',
  },
  'invoice.profile.discountLine': {
    'en': 'Discount ({label})',
    'zh': '折扣（{label}）',
    'ms': 'Diskaun ({label})',
  },
  'invoice.profile.editInvoice': {
    'en': 'Edit invoice',
    'zh': '编辑发票',
    'ms': 'Edit invois',
  },
  'invoice.profile.reprintPdf': {
    'en': 'Reprint invoice (PDF)',
    'zh': '重新打印发票（PDF）',
    'ms': 'Cetak semula invois (PDF)',
  },
  'invoice.profile.sharePdf': {
    'en': 'Share invoice PDF',
    'zh': '分享发票 PDF',
    'ms': 'Kongsi PDF invois',
  },
  'invoice.edit.title': {
    'en': 'Edit Invoice',
    'zh': '编辑发票',
    'ms': 'Edit Invois',
  },
  'invoice.confirm.title': {
    'en': 'Confirm Invoice',
    'zh': '确认发票',
    'ms': 'Sahkan Invois',
  },
  'invoice.confirm.assignedOnConfirm': {
    'en': 'Assigned when you confirm',
    'zh': '确认后分配编号',
    'ms': 'Ditetapkan apabila anda sahkan',
  },
  'invoice.confirm.createPrint': {
    'en': 'Create & print PDF',
    'zh': '创建并打印 PDF',
    'ms': 'Cipta & cetak PDF',
  },
  'invoice.confirm.createShare': {
    'en': 'Create & share PDF',
    'zh': '创建并分享 PDF',
    'ms': 'Cipta & kongsi PDF',
  },
  'invoice.snack.noLineItems': {
    'en':
        'Could not load order line items for this invoice. '
        'Pull down to refresh, or open Edit invoice.',
    'zh': '无法加载此发票的订单明细。请下拉刷新，或打开「编辑发票」。',
    'ms':
        'Tidak dapat memuatkan item baris pesanan untuk invois ini. '
        'Tarik ke bawah untuk muat semula, atau buka Edit invois.',
  },
  'invoice.snack.saveFailed': {
    'en': 'Failed to save invoice: {error}',
    'zh': '保存发票失败：{error}',
    'ms': 'Gagal menyimpan invois: {error}',
  },
  'invoice.snack.createFailed': {
    'en': 'Failed to create invoice: {error}',
    'zh': '创建发票失败：{error}',
    'ms': 'Gagal mencipta invois: {error}',
  },
  'invoice.label.invoiceNumber': {
    'en': 'Invoice number',
    'zh': '发票号',
    'ms': 'Nombor invois',
  },
  'invoice.label.customer': {
    'en': 'Customer',
    'zh': '客户',
    'ms': 'Pelanggan',
  },
  'invoice.label.items': {
    'en': 'Items',
    'zh': '项目',
    'ms': 'Item',
  },
  'invoice.label.discount': {
    'en': 'Discount',
    'zh': '折扣',
    'ms': 'Diskaun',
  },
  'invoice.label.discountOptional': {
    'en': 'Discount (optional)',
    'zh': '折扣（可选）',
    'ms': 'Diskaun (pilihan)',
  },
  'invoice.label.subtotal': {
    'en': 'Subtotal',
    'zh': '小计',
    'ms': 'Subjumlah',
  },
  'invoice.label.subtotalColon': {
    'en': 'Subtotal:',
    'zh': '小计：',
    'ms': 'Subjumlah:',
  },
  'invoice.label.total': {
    'en': 'Total',
    'zh': '合计',
    'ms': 'Jumlah',
  },
  'invoice.column.order': {
    'en': 'Order',
    'zh': '订单',
    'ms': 'Pesanan',
  },
  'invoice.column.product': {
    'en': 'Product',
    'zh': '产品',
    'ms': 'Produk',
  },
  'invoice.column.qty': {
    'en': 'Qty',
    'zh': '数量',
    'ms': 'Kuantiti',
  },
  'invoice.column.unitPrice': {
    'en': 'Unit price',
    'zh': '单价',
    'ms': 'Harga seunit',
  },
  'invoice.column.subtotal': {
    'en': 'Subtotal',
    'zh': '小计',
    'ms': 'Subjumlah',
  },
  'invoice.discount.hintPercent': {
    'en': 'e.g. 10',
    'zh': '例如 10',
    'ms': 'cth. 10',
  },
  'invoice.discount.hintAmount': {
    'en': 'e.g. 25.00',
    'zh': '例如 25.00',
    'ms': 'cth. 25.00',
  },
  'invoice.generate.title': {
    'en': 'Generate invoice',
    'zh': '生成发票',
    'ms': 'Jana invois',
  },
  'invoice.generate.printPdf': {
    'en': 'Print PDF',
    'zh': '打印 PDF',
    'ms': 'Cetak PDF',
  },
  'invoice.generate.sharePdf': {
    'en': 'Share PDF',
    'zh': '分享 PDF',
    'ms': 'Kongsi PDF',
  },
  'invoice.paymentProof.title': {
    'en': 'Payment proof',
    'zh': '付款凭证',
    'ms': 'Bukti bayaran',
  },
  'invoice.paymentProof.loadError': {
    'en': 'Could not load payment proof photo.',
    'zh': '无法加载付款凭证照片。',
    'ms': 'Tidak dapat memuatkan foto bukti bayaran.',
  },
  'invoice.paymentProof.empty': {
    'en': 'No payment proof uploaded.',
    'zh': '未上传付款凭证。',
    'ms': 'Tiada bukti bayaran dimuat naik.',
  },
  'invoice.paymentProof.uploadedAt': {
    'en': 'Uploaded {date}',
    'zh': '上传于 {date}',
    'ms': 'Dimuat naik {date}',
  },
  'invoice.paymentProof.tapEnlarge': {
    'en': 'Tap photo to enlarge',
    'zh': '点击照片放大',
    'ms': 'Ketik foto untuk besarkan',
  },
};
