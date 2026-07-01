/// Customer list, profile, and form UI strings.
const Map<String, Map<String, String>> customerStrings = {
  'customer.list.title': {
    'en': 'Customers',
    'zh': '客户',
    'ms': 'Pelanggan',
  },
  'customer.list.searchHint': {
    'en': 'Search name, phone, email, address',
    'zh': '搜索姓名、电话、邮箱、地址',
    'ms': 'Cari nama, telefon, e-mel, alamat',
  },
  'customer.list.broadcastLabel': {
    'en': 'Broadcast: {label}',
    'zh': '群发：{label}',
    'ms': 'Siaran: {label}',
  },
  'customer.list.broadcastAllFiltered': {
    'en': 'All filtered ({count})',
    'zh': '全部筛选结果（{count}）',
    'ms': 'Semua ditapis ({count})',
  },
  'customer.list.broadcastSelected': {
    'en': '{count} selected',
    'zh': '已选 {count} 个',
    'ms': '{count} dipilih',
  },
  'customer.list.selectAll': {
    'en': 'Select all',
    'zh': '全选',
    'ms': 'Pilih semua',
  },
  'customer.list.clear': {
    'en': 'Clear',
    'zh': '清除',
    'ms': 'Kosongkan',
  },
  'customer.list.broadcastMessage': {
    'en': 'Broadcast Message',
    'zh': '群发消息',
    'ms': 'Mesej Siaran',
  },
  'customer.list.broadcastTooltip': {
    'en': 'Broadcast',
    'zh': '群发',
    'ms': 'Siaran',
  },
  'customer.list.loadError': {
    'en': 'Could not load customers.',
    'zh': '无法加载客户。',
    'ms': 'Tidak dapat memuatkan pelanggan.',
  },
  'customer.list.empty': {
    'en': 'No customers yet',
    'zh': '暂无客户',
    'ms': 'Tiada pelanggan lagi',
  },
  'customer.list.addCustomer': {
    'en': 'Add Customer',
    'zh': '添加客户',
    'ms': 'Tambah Pelanggan',
  },
  'customer.profile.title': {
    'en': 'Customer Profile',
    'zh': '客户资料',
    'ms': 'Profil Pelanggan',
  },
  'customer.profile.notFound': {
    'en': 'Customer not found',
    'zh': '未找到客户',
    'ms': 'Pelanggan tidak dijumpai',
  },
  'customer.profile.loadError': {
    'en': 'Could not load customer.',
    'zh': '无法加载客户。',
    'ms': 'Tidak dapat memuatkan pelanggan.',
  },
  'customer.profile.noCreditPermission': {
    'en': 'You do not have permission to view credit customer details.',
    'zh': '您无权查看信用客户详情。',
    'ms': 'Anda tiada kebenaran melihat butiran pelanggan kredit.',
  },
  'customer.profile.creditCustomer': {
    'en': 'Credit customer',
    'zh': '信用客户',
    'ms': 'Pelanggan kredit',
  },
  'customer.profile.uenLine': {
    'en': 'UEN: {uen}',
    'zh': 'UEN：{uen}',
    'ms': 'UEN: {uen}',
  },
  'customer.profile.editProfile': {
    'en': 'Edit profile',
    'zh': '编辑资料',
    'ms': 'Edit profil',
  },
  'customer.profile.orderHistory': {
    'en': 'Order History',
    'zh': '订单历史',
    'ms': 'Sejarah Pesanan',
  },
  'customer.profile.clearSelection': {
    'en': 'Clear selection',
    'zh': '清除选择',
    'ms': 'Kosongkan pilihan',
  },
  'customer.profile.selectUnpaidForInvoice': {
    'en': 'Select unpaid for invoice',
    'zh': '选择未付订单开票',
    'ms': 'Pilih belum bayar untuk invois',
  },
  'customer.profile.noOrders': {
    'en': 'No orders found for this customer.',
    'zh': '该客户暂无订单。',
    'ms': 'Tiada pesanan untuk pelanggan ini.',
  },
  'customer.profile.noFilteredOrders': {
    'en': 'No {filter} orders.',
    'zh': '暂无{filter}订单。',
    'ms': 'Tiada pesanan {filter}.',
  },
  'customer.profile.createInvoice': {
    'en': 'Create invoice ({count})',
    'zh': '创建发票（{count}）',
    'ms': 'Cipta invois ({count})',
  },
  'customer.profile.orderLine': {
    'en': 'Order {orderId}',
    'zh': '订单 {orderId}',
    'ms': 'Pesanan {orderId}',
  },
  'customer.profile.prevVoidUnpaid': {
    'en': 'Previous invoice voided · Unpaid',
    'zh': '上一张发票已作废 · 未付',
    'ms': 'Invois terdahulu dibatalkan · Belum bayar',
  },
  'customer.profile.tapForDetails': {
    'en': 'Tap for order details',
    'zh': '点击查看订单详情',
    'ms': 'Ketik untuk butiran pesanan',
  },
  'customer.profile.totalSpending': {
    'en': 'Total spending',
    'zh': '总消费',
    'ms': 'Jumlah perbelanjaan',
  },
  'customer.profile.lastPurchase': {
    'en': 'Last purchase',
    'zh': '最近购买',
    'ms': 'Pembelian terakhir',
  },
  'customer.profile.selectOrder': {
    'en': 'Select at least one order.',
    'zh': '请至少选择一个订单。',
    'ms': 'Pilih sekurang-kurangnya satu pesanan.',
  },
  'customer.delete.title': {
    'en': 'Delete customer?',
    'zh': '删除客户？',
    'ms': 'Padam pelanggan?',
  },
  'customer.delete.body': {
    'en': 'Delete {name}{idSuffix}? Their customer number can be reused. '
        'Order history stays on past orders.',
    'zh': '删除{name}{idSuffix}？客户编号可重复使用，历史订单保留。',
    'ms': 'Padam {name}{idSuffix}? Nombor pelanggan boleh digunakan semula. '
        'Sejarah pesanan kekal pada pesanan lama.',
  },
  'customer.delete.idSuffix': {
    'en': ' ({id})',
    'zh': '（{id}）',
    'ms': ' ({id})',
  },
  'customer.delete.successWithId': {
    'en': 'Customer deleted. {id} is available again.',
    'zh': '客户已删除。{id} 可再次使用。',
    'ms': 'Pelanggan dipadam. {id} tersedia semula.',
  },
  'customer.delete.success': {
    'en': 'Customer deleted.',
    'zh': '客户已删除。',
    'ms': 'Pelanggan dipadam.',
  },
  'customer.delete.failed': {
    'en': 'Failed to delete customer: {error}',
    'zh': '删除客户失败：{error}',
    'ms': 'Gagal memadam pelanggan: {error}',
  },
  'customer.create.title': {
    'en': 'Create Customer',
    'zh': '创建客户',
    'ms': 'Cipta Pelanggan',
  },
  'customer.edit.title': {
    'en': 'Edit Customer',
    'zh': '编辑客户',
    'ms': 'Edit Pelanggan',
  },
  'customer.form.customerId': {
    'en': 'Customer ID',
    'zh': '客户编号',
    'ms': 'ID Pelanggan',
  },
  'customer.form.name': {
    'en': 'Name *',
    'zh': '姓名 *',
    'ms': 'Nama *',
  },
  'customer.form.nameHint': {
    'en': 'Customer full name',
    'zh': '客户全名',
    'ms': 'Nama penuh pelanggan',
  },
  'customer.form.phone': {
    'en': 'Phone *',
    'zh': '电话 *',
    'ms': 'Telefon *',
  },
  'customer.form.phoneHint': {
    'en': 'Local or international (e.g. 91234567, +65…, +1…)',
    'zh': '本地或国际号码（如 91234567、+65…、+1…）',
    'ms': 'Tempatan atau antarabangsa (cth. 91234567, +65…, +1…)',
  },
  'customer.form.email': {
    'en': 'Email (optional)',
    'zh': '邮箱（可选）',
    'ms': 'E-mel (pilihan)',
  },
  'customer.form.emailHint': {
    'en': 'customer@example.com',
    'zh': 'customer@example.com',
    'ms': 'customer@example.com',
  },
  'customer.form.billingAddress': {
    'en': 'Billing address (optional)',
    'zh': '账单地址（可选）',
    'ms': 'Alamat bil (pilihan)',
  },
  'customer.form.billingAddressHint': {
    'en': 'Street, unit number, postal code',
    'zh': '街道、门牌号、邮编',
    'ms': 'Jalan, nombor unit, poskod',
  },
  'customer.form.uen': {
    'en': 'UEN (optional)',
    'zh': 'UEN（可选）',
    'ms': 'UEN (pilihan)',
  },
  'customer.form.uenHint': {
    'en': 'Business registration number',
    'zh': '商业注册号',
    'ms': 'Nombor pendaftaran perniagaan',
  },
  'customer.form.creditCustomer': {
    'en': 'Credit customer',
    'zh': '信用客户',
    'ms': 'Pelanggan kredit',
  },
  'customer.form.creditCustomerSubtitle': {
    'en': 'Enable credit terms and consolidated invoicing',
    'zh': '启用信用条款及合并开票',
    'ms': 'Dayakan terma kredit dan invois gabungan',
  },
  'customer.form.creditTerms': {
    'en': 'Credit terms',
    'zh': '信用条款',
    'ms': 'Terma kredit',
  },
  'customer.form.importHint': {
    'en': 'Upload .xlsx or .csv with columns: Name, Phone, Email, '
        'Billing address, UEN, Credit customer, Credit term.',
    'zh': '上传 .xlsx 或 .csv，列：姓名、电话、邮箱、账单地址、UEN、信用客户、信用条款。',
    'ms': 'Muat naik .xlsx atau .csv dengan lajur: Name, Phone, Email, '
        'Billing address, UEN, Credit customer, Credit term.',
  },
  'customer.form.saveChanges': {
    'en': 'Save changes',
    'zh': '保存更改',
    'ms': 'Simpan perubahan',
  },
  'customer.snack.requiredFields': {
    'en': 'Name and phone are required. Check the highlighted fields.',
    'zh': '姓名和电话为必填项，请检查高亮字段。',
    'ms': 'Nama dan telefon diperlukan. Semak medan yang disorot.',
  },
  'customer.snack.noCreditPermission': {
    'en': 'Only Super Admin, Admin, Manager, or Account can '
        '{action} credit customers.',
    'zh': '仅超级管理员、管理员、经理或财务可{action}信用客户。',
    'ms': 'Hanya Super Admin, Admin, Manager, atau Account boleh '
        '{action} pelanggan kredit.',
  },
  'customer.snack.creditActionCreate': {
    'en': 'create',
    'zh': '创建',
    'ms': 'cipta',
  },
  'customer.snack.creditActionSet': {
    'en': 'set',
    'zh': '设置',
    'ms': 'tetapkan',
  },
  'customer.snack.updated': {
    'en': 'Customer profile updated',
    'zh': '客户资料已更新',
    'ms': 'Profil pelanggan dikemas kini',
  },
  'customer.snack.updateFailed': {
    'en': 'Failed to update customer: {error}',
    'zh': '更新客户失败：{error}',
    'ms': 'Gagal mengemas kini pelanggan: {error}',
  },
  'customer.snack.notSaved': {
    'en': 'Customer was not saved. Please try again.',
    'zh': '客户未保存，请重试。',
    'ms': 'Pelanggan tidak disimpan. Sila cuba lagi.',
  },
  'customer.snack.created': {
    'en': 'Customer created: {name}',
    'zh': '客户已创建：{name}',
    'ms': 'Pelanggan dicipta: {name}',
  },
  'customer.snack.createdWithId': {
    'en': 'Customer created: {name} ({id})',
    'zh': '客户已创建：{name}（{id}）',
    'ms': 'Pelanggan dicipta: {name} ({id})',
  },
  'customer.snack.createFailed': {
    'en': 'Failed to create customer: {error}',
    'zh': '创建客户失败：{error}',
    'ms': 'Gagal mencipta pelanggan: {error}',
  },
  'customer.validation.nameRequired': {
    'en': 'Name is required',
    'zh': '姓名为必填项',
    'ms': 'Nama diperlukan',
  },
  'customer.validation.duplicateName': {
    'en': 'Another customer already uses this name.',
    'zh': '已有客户使用此姓名。',
    'ms': 'Nama ini sudah digunakan oleh pelanggan lain.',
  },
  'customer.validation.duplicatePhone': {
    'en': 'Another customer already uses this phone number.',
    'zh': '已有客户使用此电话号码。',
    'ms': 'Nombor telefon ini sudah digunakan oleh pelanggan lain.',
  },
  'customer.validation.creditTermsRequired': {
    'en': 'Select credit terms for credit customers',
    'zh': '请为信用客户选择信用条款',
    'ms': 'Pilih terma kredit untuk pelanggan kredit',
  },
  'customer.validation.phoneRequired': {
    'en': 'Phone is required',
    'zh': '电话为必填项',
    'ms': 'Telefon diperlukan',
  },
  'customer.validation.phoneMinDigits': {
    'en': 'Enter at least {min} digits. For overseas numbers include '
        'country code (e.g. +65, +1, +44).',
    'zh': '至少输入 {min} 位数字。海外号码请含国家代码（如 +65、+1、+44）。',
    'ms': 'Masukkan sekurang-kurangnya {min} digit. Untuk nombor luar negara '
        'sertakan kod negara (cth. +65, +1, +44).',
  },
  'customer.validation.phoneTooLong': {
    'en': 'Phone number is too long (max {max} digits).',
    'zh': '电话号码过长（最多 {max} 位）。',
    'ms': 'Nombor telefon terlalu panjang (maks {max} digit).',
  },
  'customer.validation.emailInvalid': {
    'en': 'Enter a valid email address',
    'zh': '请输入有效的邮箱地址',
    'ms': 'Masukkan alamat e-mel yang sah',
  },
  'customer.autocomplete.hint': {
    'en': 'Search customer name or ID (e.g. TFG01)',
    'zh': '搜索客户姓名或编号（如 TFG01）',
    'ms': 'Cari nama atau ID pelanggan (cth. TFG01)',
  },
  'customer.autocomplete.walkIn': {
    'en': 'Walk-in / one-off customer (not linked to a customer profile)',
    'zh': '散客/一次性客户（不关联客户资料）',
    'ms': 'Pelanggan walk-in / sekali (tidak dipaut ke profil pelanggan)',
  },
  'customer.autocomplete.noMatch': {
    'en': 'No matching customer profile',
    'zh': '无匹配的客户资料',
    'ms': 'Tiada profil pelanggan sepadan',
  },
  'customer.autocomplete.addCustomer': {
    'en': 'Add customer',
    'zh': '添加客户',
    'ms': 'Tambah pelanggan',
  },
  'customer.autocomplete.useWalkIn': {
    'en': 'Use as walk-in / one-off customer',
    'zh': '作为散客/一次性客户',
    'ms': 'Guna sebagai pelanggan walk-in / sekali',
  },
  'customer.autocomplete.quickAddTitle': {
    'en': 'Add customer',
    'zh': '添加客户',
    'ms': 'Tambah pelanggan',
  },
  'customer.birthday.label': {
    'en': 'Birthday (optional)',
    'zh': '生日（可选）',
    'ms': 'Hari lahir (pilihan)',
  },
  'customer.birthday.pickDate': {
    'en': 'Pick date',
    'zh': '选择日期',
    'ms': 'Pilih tarikh',
  },

  // Import
  'customer.import.title': {
    'en': 'Import customers',
    'zh': '导入客户',
    'ms': 'Import pelanggan',
  },
  'customer.import.fileLine': {
    'en': 'File: {label}',
    'zh': '文件：{label}',
    'ms': 'Fail: {label}',
  },
  'customer.import.summaryLine': {
    'en': '{total} rows · {ready} ready · {errors} with errors',
    'zh': '{total} 行 · {ready} 可导入 · {errors} 有错误',
    'ms': '{total} baris · {ready} sedia · {errors} ralat',
  },
  'customer.import.creditAsRegular': {
    'en': 'Credit customer rows will be imported as regular customers.',
    'zh': '信用客户行将按普通客户导入。',
    'ms': 'Baris pelanggan kredit akan diimport sebagai pelanggan biasa.',
  },
  'customer.import.errorsSkipped': {
    'en': 'Rows with errors will be skipped.',
    'zh': '有错误的行将被跳过。',
    'ms': 'Baris dengan ralat akan dilangkau.',
  },
  'customer.import.preview': {
    'en': 'Preview',
    'zh': '预览',
    'ms': 'Pratonton',
  },
  'customer.import.previewRow': {
    'en': '{name} · {phone}{credit}',
    'zh': '{name} · {phone}{credit}',
    'ms': '{name} · {phone}{credit}',
  },
  'customer.import.previewCreditSuffix': {
    'en': ' · Credit',
    'zh': ' · 信用',
    'ms': ' · Kredit',
  },
  'customer.import.previewMore': {
    'en': '…and {count} more',
    'zh': '…还有 {count} 条',
    'ms': '…dan {count} lagi',
  },
  'customer.import.importing': {
    'en': 'Importing...',
    'zh': '导入中…',
    'ms': 'Mengimport...',
  },
  'customer.import.button': {
    'en': 'Import',
    'zh': '导入',
    'ms': 'Import',
  },
  'customer.import.fromFile': {
    'en': 'Import from Excel / CSV',
    'zh': '从 Excel / CSV 导入',
    'ms': 'Import dari Excel / CSV',
  },
  'customer.import.readFailed': {
    'en': 'Could not read the selected file.',
    'zh': '无法读取所选文件。',
    'ms': 'Tidak dapat membaca fail terpilih.',
  },
  'customer.import.failed': {
    'en': 'Import failed: {error}',
    'zh': '导入失败：{error}',
    'ms': 'Import gagal: {error}',
  },
  'customer.import.successOne': {
    'en': 'Created {count} customer.',
    'zh': '已创建 {count} 个客户。',
    'ms': 'Dicipta {count} pelanggan.',
  },
  'customer.import.successMany': {
    'en': 'Created {count} customers.',
    'zh': '已创建 {count} 个客户。',
    'ms': 'Dicipta {count} pelanggan.',
  },
  'customer.import.skippedDuplicates': {
    'en': ' Skipped {count} duplicate(s).',
    'zh': ' 跳过 {count} 个重复。',
    'ms': ' Langkau {count} pendua.',
  },
  'customer.import.failedCount': {
    'en': ' {count} failed.',
    'zh': ' {count} 个失败。',
    'ms': ' {count} gagal.',
  },

  // Broadcast
  'customer.broadcast.channelWhatsapp': {
    'en': 'WhatsApp Business',
    'zh': 'WhatsApp Business',
    'ms': 'WhatsApp Business',
  },
  'customer.broadcast.channelEmail': {
    'en': 'Email',
    'zh': '邮件',
    'ms': 'E-mel',
  },
  'customer.broadcast.title': {
    'en': 'Broadcast Message',
    'zh': '群发消息',
    'ms': 'Mesej Siaran',
  },
  'customer.broadcast.recipients': {
    'en': 'Recipients: {label}',
    'zh': '收件人：{label}',
    'ms': 'Penerima: {label}',
  },
  'customer.broadcast.subject': {
    'en': 'Subject',
    'zh': '主题',
    'ms': 'Subjek',
  },
  'customer.broadcast.subjectHint': {
    'en': 'e.g. Seasonal promotion',
    'zh': '例如：季节促销',
    'ms': 'cth. Promosi musim',
  },
  'customer.broadcast.emailBody': {
    'en': 'Email body',
    'zh': '邮件正文',
    'ms': 'Isi e-mel',
  },
  'customer.broadcast.message': {
    'en': 'Message',
    'zh': '消息',
    'ms': 'Mesej',
  },
  'customer.broadcast.emailBodyHint': {
    'en': 'e.g. Dear customer, ...',
    'zh': '例如：尊敬的客户…',
    'ms': 'cth. Pelanggan yang dihormati, ...',
  },
  'customer.broadcast.messageHint': {
    'en': 'e.g. Promotion text',
    'zh': '例如：优惠内容',
    'ms': 'cth. Teks promosi',
  },
  'customer.broadcast.photoOptional': {
    'en': 'Photo (optional)',
    'zh': '图片（可选）',
    'ms': 'Foto (pilihan)',
  },
  'customer.broadcast.previewLoadError': {
    'en': 'Could not load preview',
    'zh': '无法加载预览',
    'ms': 'Tidak dapat memuatkan pratonton',
  },
  'customer.broadcast.replacePhoto': {
    'en': 'Replace photo',
    'zh': '更换图片',
    'ms': 'Ganti foto',
  },
  'customer.broadcast.uploadPhoto': {
    'en': 'Upload photo',
    'zh': '上传图片',
    'ms': 'Muat naik foto',
  },
  'customer.broadcast.removePhoto': {
    'en': 'Remove',
    'zh': '移除',
    'ms': 'Buang',
  },
  'customer.broadcast.start': {
    'en': 'Start Broadcast',
    'zh': '开始群发',
    'ms': 'Mula Siaran',
  },
  'customer.broadcast.needContent': {
    'en': 'Please enter a message or upload a photo.',
    'zh': '请输入消息或上传图片。',
    'ms': 'Sila masukkan mesej atau muat naik foto.',
  },
  'customer.broadcast.noPhone': {
    'en': 'No customers with a valid phone number.',
    'zh': '没有有效电话号码的客户。',
    'ms': 'Tiada pelanggan dengan nombor telefon sah.',
  },
  'customer.broadcast.noPhoneToMessage': {
    'en': 'No customers with a valid phone number to message.',
    'zh': '没有可发送消息的有效电话客户。',
    'ms': 'Tiada pelanggan dengan telefon sah untuk dihantar.',
  },
  'customer.broadcast.noEmail': {
    'en': 'No customers with a valid email address.',
    'zh': '没有有效邮箱的客户。',
    'ms': 'Tiada pelanggan dengan e-mel sah.',
  },
  'customer.broadcast.noEmailToMessage': {
    'en': 'No customers with a valid email address to message.',
    'zh': '没有可发送消息的有效邮箱客户。',
    'ms': 'Tiada pelanggan dengan e-mel sah untuk dihantar.',
  },
  'customer.broadcast.whatsappWithPhoto': {
    'en': 'Will send to {count} customer(s) via WhatsApp Business with photo link.',
    'zh': '将通过 WhatsApp Business 向 {count} 位客户发送（含图片链接）。',
    'ms': 'Akan hantar kepada {count} pelanggan melalui WhatsApp Business dengan pautan foto.',
  },
  'customer.broadcast.whatsappPlain': {
    'en': 'Will send to {count} customer(s) via WhatsApp Business.',
    'zh': '将通过 WhatsApp Business 向 {count} 位客户发送。',
    'ms': 'Akan hantar kepada {count} pelanggan melalui WhatsApp Business.',
  },
  'customer.broadcast.emailBccWithPhoto': {
    'en': 'Will open email with {count} BCC recipient(s). '
        'Paste into body to embed photo inline (not attachment).',
    'zh': '将打开邮件，{count} 个密送收件人。'
        '粘贴到正文可内嵌图片（非附件）。',
    'ms': 'Akan buka e-mel dengan {count} penerima BCC. '
        'Tampal ke badan untuk benamkan foto (bukan lampiran).',
  },
  'customer.broadcast.emailBccPlain': {
    'en': 'Will open your email app with {count} recipient(s) in BCC.',
    'zh': '将打开邮件应用，{count} 个密送收件人。',
    'ms': 'Akan buka apl e-mel dengan {count} penerima dalam BCC.',
  },
  'customer.broadcast.whatsappOpenFailed': {
    'en': 'Could not open WhatsApp Business.',
    'zh': '无法打开 WhatsApp Business。',
    'ms': 'Tidak dapat membuka WhatsApp Business.',
  },
  'customer.broadcast.emailOpenFailed': {
    'en': 'Could not open your email app.',
    'zh': '无法打开邮件应用。',
    'ms': 'Tidak dapat membuka apl e-mel.',
  },
  'customer.broadcast.tooManyCopied': {
    'en': 'Too many recipients for one mail link. '
        'Copied {count} email address(es) to clipboard.',
    'zh': '收件人过多，无法用一个邮件链接。'
        '已复制 {count} 个邮箱到剪贴板。',
    'ms': 'Terlalu banyak penerima untuk satu pautan mel. '
        'Disalin {count} alamat e-mel ke papan keratan.',
  },
  'customer.broadcast.tooManyFilter': {
    'en': 'Too many recipients for one mail link. Try filtering fewer customers.',
    'zh': '收件人过多。请缩小客户筛选范围。',
    'ms': 'Terlalu banyak penerima. Cuba tapis lebih sedikit pelanggan.',
  },
  'customer.broadcast.stepTitle': {
    'en': 'Broadcast ({current}/{total})',
    'zh': '群发（{current}/{total}）',
    'ms': 'Siaran ({current}/{total})',
  },
  'customer.broadcast.skip': {
    'en': 'Skip',
    'zh': '跳过',
    'ms': 'Langkau',
  },
  'customer.broadcast.openWhatsapp': {
    'en': 'Open WhatsApp Business',
    'zh': '打开 WhatsApp Business',
    'ms': 'Buka WhatsApp Business',
  },
  'customer.broadcast.finished': {
    'en': 'Broadcast finished for {count} customers.',
    'zh': '已完成 {count} 位客户的群发。',
    'ms': 'Siaran selesai untuk {count} pelanggan.',
  },
  'customer.broadcast.emailOpenedWithPhoto': {
    'en': 'Opened email with {count} BCC recipient(s). '
        'Paste (Ctrl+V / Cmd+V) into the body to embed the photo inline.',
    'zh': '已打开邮件，{count} 个密送。'
        '在正文粘贴（Ctrl+V / Cmd+V）可内嵌图片。',
    'ms': 'E-mel dibuka dengan {count} BCC. '
        'Tampal (Ctrl+V / Cmd+V) ke badan untuk benamkan foto.',
  },
  'customer.broadcast.emailOpenedWithLink': {
    'en': 'Opened email with {count} BCC recipient(s). Photo link included in the body.',
    'zh': '已打开邮件，{count} 个密送。正文含图片链接。',
    'ms': 'E-mel dibuka dengan {count} BCC. Pautan foto disertakan dalam badan.',
  },
  'customer.broadcast.emailOpenedPlain': {
    'en': 'Opened email app with {count} recipient(s) in BCC.',
    'zh': '已打开邮件应用，{count} 个密送收件人。',
    'ms': 'Apl e-mel dibuka dengan {count} penerima dalam BCC.',
  },
  'customer.autocomplete.quickAddName': {
    'en': 'Name',
    'zh': '姓名',
    'ms': 'Nama',
  },
  'customer.autocomplete.quickAddPhone': {
    'en': 'Phone',
    'zh': '电话',
    'ms': 'Telefon',
  },
};
