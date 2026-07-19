/// Order module UI strings.
const Map<String, Map<String, String>> orderStrings = {
  // Titles
  'order.list.title': {
    'en': 'Order List',
    'zh': '订单列表',
    'ms': 'Senarai Pesanan',
  },
  'order.detail.title': {
    'en': 'Order Detail',
    'zh': '订单详情',
    'ms': 'Butiran Pesanan',
  },
  'order.detail.sectionDetails': {
    'en': 'Order Details',
    'zh': '订单信息',
    'ms': 'Butiran Pesanan',
  },
  'order.detail.sectionShipping': {
    'en': 'Shipping Information',
    'zh': '配送信息',
    'ms': 'Maklumat Penghantaran',
  },
  'order.detail.sectionItems': {
    'en': 'Order Items',
    'zh': '订单产品',
    'ms': 'Item Pesanan',
  },
  'order.detail.sectionTimeline': {
    'en': 'Order Timeline',
    'zh': '订单进度',
    'ms': 'Garis Masa Pesanan',
  },
  'order.partial.title': {
    'en': 'Partial delivery',
    'zh': '部分送达',
    'ms': 'Penghantaran Separa',
  },
  'order.statusSheet.title': {
    'en': 'Update Order Status',
    'zh': '更新订单状态',
    'ms': 'Kemas Kini Status Pesanan',
  },

  // Field labels
  'order.field.orderId': {
    'en': 'Order ID:',
    'zh': '订单号：',
    'ms': 'ID Pesanan:',
  },
  'order.field.deliveryDate': {
    'en': 'Delivery Date:',
    'zh': '配送日期：',
    'ms': 'Tarikh Penghantaran:',
  },
  'order.field.deliveryTime': {
    'en': 'Delivery Time Slot:',
    'zh': '配送时段：',
    'ms': 'Slot Masa Penghantaran:',
  },
  'order.field.method': {
    'en': 'Method:',
    'zh': '方式：',
    'ms': 'Kaedah:',
  },
  'order.field.customer': {
    'en': 'Customer:',
    'zh': '客户：',
    'ms': 'Pelanggan:',
  },
  'order.field.total': {
    'en': 'Total Amount:',
    'zh': '总金额：',
    'ms': 'Jumlah:',
  },
  'order.field.recipient': {
    'en': "Recipient's name:",
    'zh': '收件人：',
    'ms': 'Nama penerima:',
  },
  'order.field.address': {
    'en': 'Delivery Address:',
    'zh': '配送地址：',
    'ms': 'Alamat Penghantaran:',
  },
  'order.field.postal': {
    'en': 'Postal code:',
    'zh': '邮编：',
    'ms': 'Poskod:',
  },
  'order.field.phone': {
    'en': 'Recipient phone:',
    'zh': '收件人电话：',
    'ms': 'Telefon penerima:',
  },

  // List columns
  'order.col.orderId': {
    'en': 'Order ID',
    'zh': '订单号',
    'ms': 'ID Pesanan',
  },
  'order.col.customer': {
    'en': 'Customer',
    'zh': '客户',
    'ms': 'Pelanggan',
  },
  'order.col.recipient': {
    'en': 'Recipient',
    'zh': '收件人',
    'ms': 'Penerima',
  },
  'order.col.address': {
    'en': 'Address',
    'zh': '地址',
    'ms': 'Alamat',
  },
  'order.col.deliveryDate': {
    'en': 'Delivery date',
    'zh': '配送日期',
    'ms': 'Tarikh penghantaran',
  },
  'order.col.pd': {
    'en': 'P/D',
    'zh': '取/送',
    'ms': 'P/D',
  },
  'order.col.driver': {
    'en': 'Driver',
    'zh': '司机',
    'ms': 'Pemandu',
  },
  'order.col.product': {
    'en': 'Product',
    'zh': '产品',
    'ms': 'Produk',
  },
  'order.col.status': {
    'en': 'Status',
    'zh': '状态',
    'ms': 'Status',
  },

  // Type chips
  'order.type.all': {
    'en': 'All',
    'zh': '全部',
    'ms': 'Semua',
  },
  'order.type.retail': {
    'en': 'Retail',
    'zh': '零售',
    'ms': 'Runcit',
  },
  'order.type.delivery': {
    'en': 'Delivery',
    'zh': '配送',
    'ms': 'Penghantaran',
  },
  'order.type.pickUp': {
    'en': 'PickUp',
    'zh': '自取',
    'ms': 'Ambil Sendiri',
  },
  'order.type.pickupLabel': {
    'en': 'Pickup',
    'zh': '自取',
    'ms': 'Ambil',
  },

  // Status display
  'order.status.all': {
    'en': 'All statuses',
    'zh': '全部状态',
    'ms': 'Semua status',
  },
  'order.status.pending': {
    'en': 'Pending',
    'zh': '待处理',
    'ms': 'Menunggu',
  },
  'order.status.processing': {
    'en': 'Processing',
    'zh': '处理中',
    'ms': 'Memproses',
  },
  'order.status.readyToShip': {
    'en': 'Ready to Ship',
    'zh': '待派送',
    'ms': 'Sedia Dihantar',
  },
  'order.status.readyForPickup': {
    'en': 'Ready for Pickup',
    'zh': '待自取',
    'ms': 'Sedia Diambil',
  },
  'order.status.outOfDelivery': {
    'en': 'Out for Delivery',
    'zh': '派送中',
    'ms': 'Dalam Penghantaran',
  },
  'order.status.completed': {
    'en': 'Completed',
    'zh': '已完成',
    'ms': 'Selesai',
  },
  'order.status.pickedUp': {
    'en': 'Picked Up',
    'zh': '已自取',
    'ms': 'Telah Diambil',
  },
  'order.status.cancelled': {
    'en': 'Cancelled',
    'zh': '已取消',
    'ms': 'Dibatalkan',
  },

  // Timeline
  'order.timeline.confirmed': {
    'en': 'Order Confirmed',
    'zh': '订单已确认',
    'ms': 'Pesanan Disahkan',
  },
  'order.timeline.processing': {
    'en': 'Processing',
    'zh': '处理中',
    'ms': 'Memproses',
  },
  'order.timeline.ready': {
    'en': 'Ready for Delivery',
    'zh': '待派送',
    'ms': 'Sedia Penghantaran',
  },
  'order.timeline.readyPickup': {
    'en': 'Ready for Pickup',
    'zh': '待自取',
    'ms': 'Sedia Diambil',
  },
  'order.timeline.out': {
    'en': 'Out for Delivery',
    'zh': '派送中',
    'ms': 'Dalam Penghantaran',
  },
  'order.timeline.completed': {
    'en': 'Completed',
    'zh': '已完成',
    'ms': 'Selesai',
  },
  'order.timeline.pickedUp': {
    'en': 'Picked Up',
    'zh': '已自取',
    'ms': 'Telah Diambil',
  },

  // Actions
  'order.action.barTitle': {
    'en': 'Actions',
    'zh': '操作',
    'ms': 'Tindakan',
  },
  'order.action.editCustomerAddress': {
    'en': 'Edit customer & address',
    'zh': '编辑客户与地址',
    'ms': 'Edit pelanggan & alamat',
  },
  'order.action.editProducts': {
    'en': 'Edit products',
    'zh': '编辑产品',
    'ms': 'Edit produk',
  },
  'order.action.editAddress': {
    'en': 'Edit Address',
    'zh': '编辑地址',
    'ms': 'Edit Alamat',
  },
  'order.action.assignDriver': {
    'en': 'Assign Driver',
    'zh': '指派司机',
    'ms': 'Tugaskan Pemandu',
  },
  'order.driver.assigned': {
    'en': 'Assigned',
    'zh': '已指派',
    'ms': 'Ditugaskan',
  },
  'order.driver.unassigned': {
    'en': 'Unassigned',
    'zh': '未指派',
    'ms': 'Belum ditugaskan',
  },
  'order.driver.assignedDriver': {
    'en': 'Driver',
    'zh': '司机',
    'ms': 'Pemandu',
  },
  'order.action.printReceipt': {
    'en': 'Print invoice or receipt',
    'zh': '打印发票或收据',
    'ms': 'Cetak invois atau resit',
  },
  'order.action.productionMenu': {
    'en': 'Production menu',
    'zh': '生产菜单',
    'ms': 'Menu pengeluaran',
  },
  'order.action.sendPurchaseReminder': {
    'en': 'Send special purchase reminder',
    'zh': '发送特殊采购提醒',
    'ms': 'Hantar peringatan pembelian khas',
  },
  'order.purchaseReminder.confirmTitle': {
    'en': 'Send purchase reminder?',
    'zh': '发送采购提醒？',
    'ms': 'Hantar peringatan pembelian?',
  },
  'order.purchaseReminder.confirmBody': {
    'en':
        'Notify all staff (except drivers) to buy flowers/materials for this order.',
    'zh': '通知全员（不含司机）为此订单采购花材/材料。',
    'ms':
        'Maklumkan semua staf (kecuali pemandu) untuk membeli bunga/bahan pesanan ini.',
  },
  'order.purchaseReminder.send': {
    'en': 'Send',
    'zh': '发送',
    'ms': 'Hantar',
  },
  'order.purchaseReminder.sent': {
    'en': 'Purchase reminder sent to {count} staff',
    'zh': '已向 {count} 位员工发送采购提醒',
    'ms': 'Peringatan pembelian dihantar kepada {count} staf',
  },
  'order.purchaseReminder.noRecipients': {
    'en': 'No staff recipients found for this company',
    'zh': '未找到可接收提醒的员工',
    'ms': 'Tiada penerima staf untuk syarikat ini',
  },
  'order.purchaseReminder.failed': {
    'en': 'Could not send purchase reminder',
    'zh': '发送采购提醒失败',
    'ms': 'Gagal menghantar peringatan pembelian',
  },
  'order.action.updateStatus': {
    'en': 'Update Status',
    'zh': '更新状态',
    'ms': 'Kemas Kini Status',
  },
  'order.action.deliveryOrder': {
    'en': 'Delivery Order',
    'zh': '配送单',
    'ms': 'Pesanan Penghantaran',
  },
  'order.action.whatsappCustomer': {
    'en': 'WhatsApp Business',
    'zh': 'WhatsApp Business',
    'ms': 'WhatsApp Business',
  },
  'order.whatsapp.phoneInvalid': {
    'en': 'Customer phone number is missing or invalid.',
    'zh': '客户电话号码缺失或无效。',
    'ms': 'Nombor telefon pelanggan tiada atau tidak sah.',
  },
  'order.whatsapp.businessOpenFailed': {
    'en': 'Could not open WhatsApp Business.',
    'zh': '无法打开 WhatsApp Business。',
    'ms': 'Tidak dapat membuka WhatsApp Business.',
  },
  'order.whatsapp.pasteDialogTitle': {
    'en': 'WhatsApp Business',
    'zh': 'WhatsApp Business',
    'ms': 'WhatsApp Business',
  },
  'order.whatsapp.pasteDialogHintEmpty': {
    'en': 'Clipboard is empty. Paste the WhatsApp Business message here, then tap OK.',
    'zh': '剪贴板为空。请粘贴 WhatsApp Business 消息，然后点确定。',
    'ms': 'Papan keratan kosong. Tampal mesej WhatsApp Business di sini, kemudian ketik OK.',
  },
  'order.whatsapp.pasteDialogHintReview': {
    'en': 'Review the message below, edit if needed, then tap OK.',
    'zh': '请核对下方消息，如需可编辑，然后点确定。',
    'ms': 'Semak mesej di bawah, sunting jika perlu, kemudian ketik OK.',
  },
  'order.whatsapp.importSuccess': {
    'en': 'Order imported. Review delivery details, then payment.',
    'zh': '订单已导入。请核对配送资料，然后付款。',
    'ms': 'Pesanan diimport. Semak butiran penghantaran, kemudian bayaran.',
  },
  'order.whatsapp.parseFailed': {
    'en':
        'Could not read an order from the message. Paste a WhatsApp Business message with customer or product details.',
    'zh': '无法从消息读取订单。请粘贴包含客户或商品信息的 WhatsApp Business 消息。',
    'ms':
        'Tidak dapat membaca pesanan daripada mesej. Tampal mesej WhatsApp Business dengan butiran pelanggan atau produk.',
  },
  'order.action.startProcessing': {
    'en': 'Start Processing',
    'zh': '开始处理',
    'ms': 'Mula Memproses',
  },
  'order.action.readyToShip': {
    'en': 'Ready to Ship',
    'zh': '标记待派送',
    'ms': 'Sedia Dihantar',
  },

  // Bulk list actions
  'order.bulk.noneSelected': {
    'en': 'Select orders below to apply bulk actions',
    'zh': '在下方勾选订单以进行批量操作',
    'ms': 'Pilih pesanan di bawah untuk tindakan pukal',
  },
  'order.bulk.selectedCount': {
    'en': '{count} selected',
    'zh': '已选 {count} 笔',
    'ms': '{count} dipilih',
  },
  'order.bulk.selectFirst': {
    'en': 'Select at least one order first.',
    'zh': '请先勾选至少一笔订单。',
    'ms': 'Pilih sekurang-kurangnya satu pesanan dahulu.',
  },
  'order.bulk.assignDriver': {
    'en': 'Assign driver',
    'zh': '指派司机',
    'ms': 'Tugaskan pemandu',
  },
  'order.bulk.assignDriverTitle': {
    'en': 'Assign driver to selected orders',
    'zh': '为所选订单指派司机',
    'ms': 'Tugaskan pemandu kepada pesanan terpilih',
  },
  'order.bulk.assignDriverConfirm': {
    'en': 'Assign to all selected',
    'zh': '指派给全部所选',
    'ms': 'Tugaskan kepada semua terpilih',
  },
  'order.bulk.assignDriverDenied': {
    'en': 'You do not have permission to assign drivers.',
    'zh': '您没有指派司机的权限。',
    'ms': 'Anda tiada kebenaran menugaskan pemandu.',
  },
  'order.bulk.assignDriverFailed': {
    'en': 'Could not assign driver: {error}',
    'zh': '指派司机失败：{error}',
    'ms': 'Gagal menugaskan pemandu: {error}',
  },
  'order.bulk.driverAssigned': {
    'en': 'Driver assigned to {count} orders',
    'zh': '已为 {count} 笔订单指派司机',
    'ms': 'Pemandu ditugaskan kepada {count} pesanan',
  },
  'order.bulk.pickDriver': {
    'en': 'Select a driver.',
    'zh': '请选择司机。',
    'ms': 'Pilih pemandu.',
  },
  'order.bulk.noDrivers': {
    'en': 'No drivers found for this company.',
    'zh': '未找到本公司的司机。',
    'ms': 'Tiada pemandu untuk syarikat ini.',
  },
  'order.bulk.updateStatus': {
    'en': 'Update status',
    'zh': '更改状态',
    'ms': 'Kemas kini status',
  },
  'order.bulk.updateStatusTitle': {
    'en': 'Update status for selected orders',
    'zh': '更改所选订单状态',
    'ms': 'Kemas kini status pesanan terpilih',
  },
  'order.bulk.updateStatusDenied': {
    'en': 'You do not have permission to update order status.',
    'zh': '您没有更改订单状态的权限。',
    'ms': 'Anda tiada kebenaran mengemas kini status pesanan.',
  },
  'order.bulk.updateStatusFailed': {
    'en': 'Could not update status: {error}',
    'zh': '更改状态失败：{error}',
    'ms': 'Gagal mengemas kini status: {error}',
  },
  'order.bulk.statusApplied': {
    'en': '{count} orders set to {status}',
    'zh': '已将 {count} 笔订单设为 {status}',
    'ms': '{count} pesanan ditetapkan kepada {status}',
  },

  // Filters & search
  'order.filter.statusHint': {
    'en': 'Status (all)',
    'zh': '状态（全部）',
    'ms': 'Status (semua)',
  },
  'order.filter.dateStart': {
    'en': 'Start:',
    'zh': '开始：',
    'ms': 'Mula:',
  },
  'order.filter.dateEnd': {
    'en': 'End:',
    'zh': '结束：',
    'ms': 'Akhir:',
  },
  'order.search.hint': {
    'en': 'Search name, address, product, order ID...',
    'zh': '搜索姓名、地址、产品、订单号…',
    'ms': 'Cari nama, alamat, produk, ID pesanan...',
  },
  'order.list.empty': {
    'en': 'No orders match your filters.',
    'zh': '没有符合筛选条件的订单。',
    'ms': 'Tiada pesanan sepadan dengan penapis.',
  },

  // Delete / export messages
  'order.delete.selectFirst': {
    'en': 'Select one or more orders to delete.',
    'zh': '请先选择要删除的订单。',
    'ms': 'Pilih satu atau lebih pesanan untuk dipadam.',
  },
  'order.delete.title': {
    'en': 'Delete selected orders?',
    'zh': '删除所选订单？',
    'ms': 'Padam pesanan terpilih?',
  },
  'order.delete.body': {
    'en':
        'Delete {count} order(s)?\n\nThey will be archived to deleted_orders for audit and removed from the order list.\n\n{preview}',
    'zh': '删除 {count} 个订单？\n\n将归档至 deleted_orders 供审计，并从列表中移除。\n\n{preview}',
    'ms':
        'Padam {count} pesanan?\n\nIa akan diarkibkan ke deleted_orders untuk audit dan dikeluarkan dari senarai.\n\n{preview}',
  },
  'order.delete.reasonLabel': {
    'en': 'Delete reason (optional)',
    'zh': '删除原因（可选）',
    'ms': 'Sebab padam (pilihan)',
  },
  'order.delete.success': {
    'en': 'Deleted {count} order(s). Archived to deleted_orders.',
    'zh': '已删除 {count} 个订单，已归档至 deleted_orders。',
    'ms': '{count} pesanan dipadam. Diarkibkan ke deleted_orders.',
  },
  'order.delete.failed': {
    'en': 'Delete failed: {error}',
    'zh': '删除失败：{error}',
    'ms': 'Padam gagal: {error}',
  },
  'order.export.noMatch': {
    'en': 'No orders match the current filters.',
    'zh': '当前筛选条件下没有订单。',
    'ms': 'Tiada pesanan sepadan dengan penapis semasa.',
  },
  'order.export.success': {
    'en': 'Exported {count} order(s). Check Downloads or Files app.',
    'zh': '已导出 {count} 个订单，请查看下载或文件应用。',
    'ms': '{count} pesanan dieksport. Semak Muat Turun atau aplikasi Fail.',
  },
  'order.export.failed': {
    'en': 'Export failed: {error}',
    'zh': '导出失败：{error}',
    'ms': 'Eksport gagal: {error}',
  },

  // Product line summary
  'order.product.qtyDeliveredPartial': {
    'en': 'Qty {qty} ({delivered} delivered)',
    'zh': '数量 {qty}（已送 {delivered}）',
    'ms': 'Kuantiti {qty} ({delivered} dihantar)',
  },
  'order.product.qtyAllDelivered': {
    'en': 'Qty {qty} (delivered)',
    'zh': '数量 {qty}（已送完）',
    'ms': 'Kuantiti {qty} (dihantar)',
  },
  'order.product.qtyOnly': {
    'en': 'Qty {qty}',
    'zh': '数量 {qty}',
    'ms': 'Kuantiti {qty}',
  },

  // Partial delivery
  'order.partial.notFound': {
    'en': 'Order not found',
    'zh': '找不到订单',
    'ms': 'Pesanan tidak dijumpai',
  },
  'order.partial.progress': {
    'en': 'Delivery progress',
    'zh': '配送进度',
    'ms': 'Kemajuan penghantaran',
  },
  'order.partial.runs': {
    'en': 'Delivery runs',
    'zh': '配送批次',
    'ms': 'Pusingan penghantaran',
  },
  'order.partial.recorded': {
    'en': 'Recorded',
    'zh': '已记录',
    'ms': 'Direkod',
  },
  'order.partial.deliverToday': {
    'en': 'Deliver today',
    'zh': '今日送达',
    'ms': 'Hantar hari ini',
  },
  'order.partial.noProducts': {
    'en': 'No products on this order.',
    'zh': '此订单没有产品。',
    'ms': 'Tiada produk pada pesanan ini.',
  },
  'order.partial.deliveredOf': {
    'en': 'Delivered {done} / {total}',
    'zh': '已送 {done} / {total}',
    'ms': 'Dihantar {done} / {total}',
  },
  'order.partial.fullyDelivered': {
    'en': 'Fully delivered',
    'zh': '已全部送达',
    'ms': 'Dihantar sepenuhnya',
  },
  'order.partial.allQty': {
    'en': 'All {qty}',
    'zh': '全部 {qty}',
    'ms': 'Semua {qty}',
  },
  'order.partial.nextDateOptional': {
    'en': 'Next delivery date (optional)',
    'zh': '下次配送日期（可选）',
    'ms': 'Tarikh penghantaran seterusnya (pilihan)',
  },
  'order.partial.keepSchedule': {
    'en': 'Keep current schedule',
    'zh': '保持当前安排',
    'ms': 'Kekalkan jadual semasa',
  },
  'order.partial.confirm': {
    'en': 'Confirm partial delivery',
    'zh': '确认部分送达',
    'ms': 'Sahkan penghantaran separa',
  },
  'order.partial.selectQty': {
    'en': 'Select at least one product quantity to deliver.',
    'zh': '请至少选择一个产品的送达数量。',
    'ms': 'Pilih sekurang-kurangnya satu kuantiti produk untuk dihantar.',
  },
  'order.partial.printSelectQty': {
    'en': 'Select at least one item quantity to print.',
    'zh': '请至少选择一个产品数量再打印。',
    'ms': 'Pilih sekurang-kurangnya satu kuantiti item untuk cetak.',
  },
  'order.partial.allCompleted': {
    'en': 'All items delivered. Order completed.',
    'zh': '全部产品已送达，订单已完成。',
    'ms': 'Semua item dihantar. Pesanan selesai.',
  },
  'order.partial.recordedCount': {
    'en': 'Recorded {count} item(s).',
    'zh': '已记录 {count} 个产品。',
    'ms': '{count} item direkod.',
  },
  'order.partial.stillRemaining': {
    'en': '{remaining} still to deliver.',
    'zh': '尚有 {remaining} 待送。',
    'ms': '{remaining} masih perlu dihantar.',
  },
  'order.partial.progressSummary': {
    'en': '{delivered} of {ordered} delivered{remainingSuffix}',
    'zh': '已送 {delivered} / {ordered}{remainingSuffix}',
    'ms': '{delivered} daripada {ordered} dihantar{remainingSuffix}',
  },
  'order.partial.remainingSuffix': {
    'en': ' · {remaining} left',
    'zh': ' · 剩 {remaining}',
    'ms': ' · {remaining} lagi',
  },
  'order.partial.itemRemaining': {
    'en': 'Delivered {done} / {total} · Remaining {remaining}',
    'zh': '已送 {done} / {total} · 剩 {remaining}',
    'ms': 'Dihantar {done} / {total} · Baki {remaining}',
  },
  'order.partial.runItems': {
    'en': '{label} · {count} item(s)',
    'zh': '{label} · {count} 项',
    'ms': '{label} · {count} item',
  },

  // Driver assignments
  'order.driver.title': {
    'en': 'Driver Assignments',
    'zh': '司机派单',
    'ms': 'Tugasan Pemandu',
  },
  'order.driver.noPermission': {
    'en': 'You do not have permission to view driver assignments.',
    'zh': '您没有查看司机派单的权限。',
    'ms': 'Anda tiada kebenaran untuk melihat tugasan pemandu.',
  },
  'order.driver.noDrivers': {
    'en': 'No active drivers found for this company.',
    'zh': '该公司暂无在职司机。',
    'ms': 'Tiada pemandu aktif untuk syarikat ini.',
  },
  'order.driver.filterFromDate': {
    'en': 'Filter from date',
    'zh': '筛选开始日期',
    'ms': 'Tapis dari tarikh',
  },
  'order.driver.filterToDate': {
    'en': 'Filter to date',
    'zh': '筛选结束日期',
    'ms': 'Tapis hingga tarikh',
  },
  'order.driver.allDeliveryDates': {
    'en': 'All delivery dates',
    'zh': '全部配送日期',
    'ms': 'Semua tarikh penghantaran',
  },
  'order.driver.dateFrom': {
    'en': 'From {date}',
    'zh': '从 {date}',
    'ms': 'Dari {date}',
  },
  'order.driver.dateUntil': {
    'en': 'Until {date}',
    'zh': '至 {date}',
    'ms': 'Hingga {date}',
  },
  'order.driver.dateOnwards': {
    'en': 'Onwards',
    'zh': '往后',
    'ms': 'Seterusnya',
  },
  'order.driver.fromTodayOnwards': {
    'en': 'From today onwards',
    'zh': '从今天起',
    'ms': 'Dari hari ini',
  },
  'order.driver.resetToToday': {
    'en': 'Today',
    'zh': '今天',
    'ms': 'Hari ini',
  },
  'order.driver.deliveryDateLabel': {
    'en': 'Delivery date',
    'zh': '配送日期',
    'ms': 'Tarikh penghantaran',
  },
  'order.driver.dateFromLabel': {
    'en': 'From',
    'zh': '从',
    'ms': 'Dari',
  },
  'order.driver.dateToLabel': {
    'en': 'To',
    'zh': '至',
    'ms': 'Hingga',
  },
  'order.driver.clearDates': {
    'en': 'Clear dates',
    'zh': '清除日期',
    'ms': 'Kosongkan tarikh',
  },
  'order.driver.noRouteAddresses': {
    'en': 'No delivery addresses to route.',
    'zh': '没有可规划的配送地址。',
    'ms': 'Tiada alamat penghantaran untuk laluan.',
  },
  'order.driver.routeLimited': {
    'en': 'Opening first {count} stops in Google Maps.',
    'zh': '在 Google 地图中打开前 {count} 个站点。',
    'ms': 'Membuka {count} hentian pertama dalam Google Maps.',
  },
  'order.driver.mapsOpenFailed': {
    'en': 'Could not open Google Maps.',
    'zh': '无法打开 Google 地图。',
    'ms': 'Tidak dapat membuka Google Maps.',
  },
  'order.driver.loadOrdersFailed': {
    'en': 'Could not load orders: {error}',
    'zh': '无法加载订单：{error}',
    'ms': 'Tidak dapat memuatkan pesanan: {error}',
  },
  'order.driver.noOrdersForFilters': {
    'en': 'No orders assigned to this driver for the selected filters.',
    'zh': '当前筛选条件下该司机无派单。',
    'ms': 'Tiada pesanan ditugaskan kepada pemandu ini untuk penapis dipilih.',
  },
  'order.driver.assignedCount': {
    'en': 'Assigned orders ({count})',
    'zh': '已派订单（{count}）',
    'ms': 'Pesanan ditugaskan ({count})',
  },
  'order.driver.suggestedRoute': {
    'en': 'Suggested route',
    'zh': '建议路线',
    'ms': 'Laluan dicadangkan',
  },
  'order.driver.noAddressesOnOrders': {
    'en': 'Assigned orders have no delivery addresses.',
    'zh': '已派订单没有配送地址。',
    'ms': 'Pesanan ditugaskan tiada alamat penghantaran.',
  },
  'order.driver.openInMaps': {
    'en': 'Open in Google Maps',
    'zh': '在 Google 地图中打开',
    'ms': 'Buka dalam Google Maps',
  },

  // Deleted orders archive
  'order.deleted.title': {
    'en': 'Deleted Orders',
    'zh': '已删订单',
    'ms': 'Pesanan Dipadam',
  },
  'order.deleted.noPermission': {
    'en': 'You do not have permission to view deleted orders.',
    'zh': '您没有查看已删订单的权限。',
    'ms': 'Anda tiada kebenaran untuk melihat pesanan dipadam.',
  },
  'order.deleted.loadFailed': {
    'en': 'Failed to load deleted orders.',
    'zh': '加载已删订单失败。',
    'ms': 'Gagal memuatkan pesanan dipadam.',
  },
  'order.deleted.noMatch': {
    'en': 'No deleted orders match your filters.',
    'zh': '没有符合筛选条件的已删订单。',
    'ms': 'Tiada pesanan dipadam sepadan dengan penapis anda.',
  },
  'order.deleted.badge': {
    'en': 'DELETED',
    'zh': '已删除',
    'ms': 'DIPADAM',
  },
  'order.deleted.analyticsTotal': {
    'en': 'Total Deleted',
    'zh': '删除总数',
    'ms': 'Jumlah Dipadam',
  },
  'order.deleted.analyticsRevenue': {
    'en': 'Deleted Revenue',
    'zh': '删除金额',
    'ms': 'Hasil Dipadam',
  },
  'order.deleted.analyticsTopProduct': {
    'en': 'Top Deleted Product',
    'zh': '删除最多产品',
    'ms': 'Produk Paling Dipadam',
  },
  'order.deleted.analyticsTopDeleter': {
    'en': 'Most Active Deleter',
    'zh': '删除最多员工',
    'ms': 'Pemadam Paling Aktif',
  },
  'order.deleted.searchHint': {
    'en': 'Search Order ID or Customer',
    'zh': '搜索订单号或客户',
    'ms': 'Cari ID Pesanan atau Pelanggan',
  },
  'order.deleted.deletedFrom': {
    'en': 'Deleted from',
    'zh': '删除自',
    'ms': 'Dipadam dari',
  },
  'order.deleted.deletedTo': {
    'en': 'Deleted to',
    'zh': '删除至',
    'ms': 'Dipadam hingga',
  },
  'order.deleted.fromDate': {
    'en': 'From {date}',
    'zh': '从 {date}',
    'ms': 'Dari {date}',
  },
  'order.deleted.toDate': {
    'en': 'To {date}',
    'zh': '至 {date}',
    'ms': 'Hingga {date}',
  },
  'order.deleted.deletedByAll': {
    'en': 'Deleted by: All',
    'zh': '删除人：全部',
    'ms': 'Dipadam oleh: Semua',
  },
  'order.deleted.statusAll': {
    'en': 'Status: All',
    'zh': '状态：全部',
    'ms': 'Status: Semua',
  },
  'order.deleted.clearFilters': {
    'en': 'Clear filters',
    'zh': '清除筛选',
    'ms': 'Kosongkan penapis',
  },
  'order.deleted.colOrderId': {
    'en': 'Order ID',
    'zh': '订单号',
    'ms': 'ID Pesanan',
  },
  'order.deleted.colCustomer': {
    'en': 'Customer',
    'zh': '客户',
    'ms': 'Pelanggan',
  },
  'order.deleted.colOrderDate': {
    'en': 'Order Date',
    'zh': '订单日期',
    'ms': 'Tarikh Pesanan',
  },
  'order.deleted.colTotal': {
    'en': 'Total',
    'zh': '总额',
    'ms': 'Jumlah',
  },
  'order.deleted.colDeletedDate': {
    'en': 'Deleted Date',
    'zh': '删除日期',
    'ms': 'Tarikh Dipadam',
  },
  'order.deleted.colDeletedBy': {
    'en': 'Deleted By',
    'zh': '删除人',
    'ms': 'Dipadam Oleh',
  },
  'order.deleted.colReason': {
    'en': 'Reason',
    'zh': '原因',
    'ms': 'Sebab',
  },
  'order.deleted.colStatus': {
    'en': 'Status',
    'zh': '状态',
    'ms': 'Status',
  },
  'order.deleted.details': {
    'en': 'Details',
    'zh': '详情',
    'ms': 'Butiran',
  },
  'order.deleted.restore': {
    'en': 'Restore',
    'zh': '恢复',
    'ms': 'Pulihkan',
  },
  'order.deleted.deleteForever': {
    'en': 'Delete forever',
    'zh': '永久删除',
    'ms': 'Padam selama-lamanya',
  },
  'order.deleted.restoreTitle': {
    'en': 'Restore order?',
    'zh': '恢复订单？',
    'ms': 'Pulihkan pesanan?',
  },
  'order.deleted.restoreBody': {
    'en': 'Restore {orderId} to Active Orders?\n\nThe order will reappear in the order list.',
    'zh': '将 {orderId} 恢复至有效订单？\n\n订单将重新出现在订单列表中。',
    'ms': 'Pulihkan {orderId} ke Pesanan Aktif?\n\nPesanan akan muncul semula dalam senarai.',
  },
  'order.deleted.restoreSuccess': {
    'en': 'Order restored to Active Orders.',
    'zh': '订单已恢复至有效订单。',
    'ms': 'Pesanan dipulihkan ke Pesanan Aktif.',
  },
  'order.deleted.restoreFailed': {
    'en': 'Failed to restore order.',
    'zh': '恢复订单失败。',
    'ms': 'Gagal memulihkan pesanan.',
  },
  'order.deleted.permanentTitle': {
    'en': 'Permanently delete?',
    'zh': '永久删除？',
    'ms': 'Padam kekal?',
  },
  'order.deleted.permanentBody': {
    'en': 'This action cannot be undone.\n\nThe archived order will be removed permanently.',
    'zh': '此操作无法撤销。\n\n归档订单将被永久删除。',
    'ms': 'Tindakan ini tidak boleh dibatalkan.\n\nPesanan arkib akan dipadam kekal.',
  },
  'order.deleted.permanentButton': {
    'en': 'Delete permanently',
    'zh': '永久删除',
    'ms': 'Padam kekal',
  },
  'order.deleted.permanentSuccess': {
    'en': 'Archived order permanently deleted.',
    'zh': '归档订单已永久删除。',
    'ms': 'Pesanan arkib dipadam kekal.',
  },
  'order.deleted.permanentFailed': {
    'en': 'Failed to permanently delete order.',
    'zh': '永久删除失败。',
    'ms': 'Gagal memadam pesanan kekal.',
  },
  'order.deleted.pageInfo': {
    'en': 'Page {page} of {totalPages} ({count} orders)',
    'zh': '第 {page} / {totalPages} 页（{count} 笔订单）',
    'ms': 'Halaman {page} daripada {totalPages} ({count} pesanan)',
  },
  'order.deleted.detailTitle': {
    'en': 'Deleted Order Details',
    'zh': '已删订单详情',
    'ms': 'Butiran Pesanan Dipadam',
  },
  'order.deleted.detailShortTitle': {
    'en': 'Deleted Order',
    'zh': '已删订单',
    'ms': 'Pesanan Dipadam',
  },
  'order.deleted.missingRef': {
    'en': 'Missing archive reference.',
    'zh': '缺少归档引用。',
    'ms': 'Rujukan arkib tiada.',
  },
  'order.deleted.banner': {
    'en': 'This order was deleted and is not in Active Orders.',
    'zh': '此订单已删除，不在有效订单中。',
    'ms': 'Pesanan ini dipadam dan tiada dalam Pesanan Aktif.',
  },
  'order.deleted.originalStatus': {
    'en': 'Original status',
    'zh': '原状态',
    'ms': 'Status asal',
  },
  'order.deleted.deletedLabel': {
    'en': 'Deleted',
    'zh': '删除时间',
    'ms': 'Dipadam',
  },
  'order.deleted.deleteReason': {
    'en': 'Delete reason',
    'zh': '删除原因',
    'ms': 'Sebab padam',
  },
  'order.deleted.restoredLabel': {
    'en': 'Restored',
    'zh': '恢复时间',
    'ms': 'Dipulihkan',
  },
  'order.deleted.restoredBy': {
    'en': 'Restored by',
    'zh': '恢复人',
    'ms': 'Dipulihkan oleh',
  },
  'order.deleted.activityLog': {
    'en': 'Activity Log',
    'zh': '活动记录',
    'ms': 'Log Aktiviti',
  },
  'order.deleted.noActivity': {
    'en': 'No activity recorded.',
    'zh': '暂无活动记录。',
    'ms': 'Tiada aktiviti direkod.',
  },
  'order.deleted.restoreOrder': {
    'en': 'Restore Order',
    'zh': '恢复订单',
    'ms': 'Pulihkan Pesanan',
  },
  'order.deleted.permanentlyDelete': {
    'en': 'Permanently Delete',
    'zh': '永久删除',
    'ms': 'Padam Kekal',
  },
  'order.deleted.restoreBodyShort': {
    'en': 'This order will reappear in Active Orders after restore.',
    'zh': '恢复后此订单将重新出现在有效订单中。',
    'ms': 'Pesanan ini akan muncul semula dalam Pesanan Aktif selepas dipulihkan.',
  },
  'order.deleted.restoreSnack': {
    'en': 'Order restored.',
    'zh': '订单已恢复。',
    'ms': 'Pesanan dipulihkan.',
  },
  'order.deleted.permanentBodyShort': {
    'en': 'This action cannot be undone.',
    'zh': '此操作无法撤销。',
    'ms': 'Tindakan ini tidak boleh dibatalkan.',
  },

  // Production menu preview
  'order.production.title': {
    'en': 'Production Menu',
    'zh': '生产单',
    'ms': 'Menu Pengeluaran',
  },
  'order.production.notFound': {
    'en': 'Order not found.',
    'zh': '未找到订单。',
    'ms': 'Pesanan tidak dijumpai.',
  },
  'order.production.printThermal': {
    'en': 'Print thermal',
    'zh': '热敏打印',
    'ms': 'Cetak termal',
  },
  'order.production.sheetTitle': {
    'en': 'Production sheet',
    'zh': '生产单',
    'ms': 'Helaian pengeluaran',
  },
  'order.production.sheetHint': {
    'en': 'Separate from customer receipt — for shop floor use.',
    'zh': '与客户收据分开 — 供车间使用。',
    'ms': 'Berasingan dari resit pelanggan — untuk penggunaan bengkel.',
  },
  'order.production.orderLabel': {
    'en': 'Order',
    'zh': '订单',
    'ms': 'Pesanan',
  },
  'order.production.dateLabel': {
    'en': 'Date',
    'zh': '日期',
    'ms': 'Tarikh',
  },
  'order.production.customerLabel': {
    'en': 'Customer',
    'zh': '客户',
    'ms': 'Pelanggan',
  },
  'order.production.productsInOrder': {
    'en': 'Products in this order',
    'zh': '本订单产品',
    'ms': 'Produk dalam pesanan ini',
  },
  'order.production.noLineItems': {
    'en': 'No line items.',
    'zh': '无明细行。',
    'ms': 'Tiada item baris.',
  },
  'order.production.materialsRequired': {
    'en': 'Materials required',
    'zh': '所需物料',
    'ms': 'Bahan diperlukan',
  },
  'order.production.noRecipeMaterials': {
    'en': 'No recipe materials found. Add recipes on products first.',
    'zh': '未找到配方物料，请先为产品添加配方。',
    'ms': 'Tiada bahan resipi dijumpai. Tambah resipi pada produk dahulu.',
  },
  'order.production.noRecipeLinked': {
    'en': 'No recipe linked',
    'zh': '未关联配方',
    'ms': 'Tiada resipi dipautkan',
  },
  'order.production.webPrintHint': {
    'en': 'Web printing needs Chrome or Edge on HTTPS, and a BLE thermal printer. '
        'Tap the Bluetooth icon above to pair.',
    'zh': '网页打印需 HTTPS 下的 Chrome 或 Edge，以及 BLE 热敏打印机。'
        '点击上方蓝牙图标配对。',
    'ms': 'Cetakan web memerlukan Chrome atau Edge pada HTTPS, dan pencetak termal BLE. '
        'Ketik ikon Bluetooth di atas untuk ganding.',
  },
  'order.production.materialCol': {
    'en': 'Material',
    'zh': '物料',
    'ms': 'Bahan',
  },
  'order.production.costCol': {
    'en': 'Cost',
    'zh': '成本',
    'ms': 'Kos',
  },
  'order.production.totalMaterialCost': {
    'en': 'Total material cost',
    'zh': '物料总成本',
    'ms': 'Jumlah kos bahan',
  },
};
