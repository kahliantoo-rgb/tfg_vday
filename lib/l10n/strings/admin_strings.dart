/// Admin pages (user list, role permissions).
const Map<String, Map<String, String>> adminStrings = {
  'admin.userList.title': {
    'en': 'User List',
    'zh': '员工列表',
    'ms': 'Senarai Staf',
  },
  'admin.userList.noPermission': {
    'en': 'You do not have permission to view users.',
    'zh': '您没有查看员工的权限。',
    'ms': 'Anda tiada kebenaran untuk melihat staf.',
  },
  'admin.userList.loadFailed': {
    'en': 'Failed to load users.',
    'zh': '加载员工失败。',
    'ms': 'Gagal memuatkan staf.',
  },
  'admin.userList.noUsers': {
    'en': 'No users found.',
    'zh': '未找到员工。',
    'ms': 'Tiada staf dijumpai.',
  },
  'admin.userList.updateFailed': {
    'en': 'Update failed: {error}',
    'zh': '更新失败：{error}',
    'ms': 'Kemas kini gagal: {error}',
  },
  'admin.userList.deleteTitle': {
    'en': 'Delete user?',
    'zh': '删除员工？',
    'ms': 'Padam staf?',
  },
  'admin.userList.deleteBody': {
    'en': 'Delete profile for {name}?\n\n'
        'This removes the Firestore profile only. '
        'The Firebase Auth account remains.',
    'zh': '删除 {name} 的资料？\n\n'
        '仅删除 Firestore 资料，Firebase Auth 账户仍保留。',
    'ms': 'Padam profil {name}?\n\n'
        'Ini hanya memadam profil Firestore. '
        'Akaun Firebase Auth kekal.',
  },
  'admin.userList.deleted': {
    'en': 'User deleted.',
    'zh': '员工已删除。',
    'ms': 'Staf dipadam.',
  },
  'admin.userList.deleteFailed': {
    'en': 'Delete failed: {error}',
    'zh': '删除失败：{error}',
    'ms': 'Padam gagal: {error}',
  },
  'admin.userList.cannotEditRoles': {
    'en': 'You cannot edit staff roles.',
    'zh': '您无法编辑员工角色。',
    'ms': 'Anda tidak boleh mengedit peranan staf.',
  },
  'admin.userList.updated': {
    'en': 'User updated.',
    'zh': '员工已更新。',
    'ms': 'Staf dikemas kini.',
  },
  'admin.userList.addRole': {
    'en': 'Add role',
    'zh': '添加角色',
    'ms': 'Tambah peranan',
  },
  'admin.userList.addStaff': {
    'en': 'Add staff',
    'zh': '添加员工',
    'ms': 'Tambah staf',
  },
  'admin.userList.rolePermissionsTooltip': {
    'en': 'Role permissions — temporarily enable extra access for a role',
    'zh': '角色权限 — 临时为某角色开启额外权限',
    'ms': 'Kebenaran peranan — benarkan akses tambahan sementara',
  },
  'admin.userList.colName': {
    'en': 'Name',
    'zh': '姓名',
    'ms': 'Nama',
  },
  'admin.userList.colRole': {
    'en': 'Role',
    'zh': '角色',
    'ms': 'Peranan',
  },
  'admin.userList.colActions': {
    'en': 'Actions',
    'zh': '操作',
    'ms': 'Tindakan',
  },
  'admin.userList.editUser': {
    'en': 'Edit user',
    'zh': '编辑员工',
    'ms': 'Edit staf',
  },
  'admin.userList.deleteUser': {
    'en': 'Delete user',
    'zh': '删除员工',
    'ms': 'Padam staf',
  },
  'admin.rolePermissions.title': {
    'en': 'Role Permissions',
    'zh': '角色权限',
    'ms': 'Kebenaran Peranan',
  },
  'admin.rolePermissions.noAccess': {
    'en': 'Only Admin, Director, or Super Admin can manage role permissions.',
    'zh': '仅管理员、总监或超级管理员可管理角色权限。',
    'ms': 'Hanya Admin, Pengarah, atau Super Admin boleh mengurus kebenaran peranan.',
  },
  'admin.rolePermissions.intro': {
    'en': 'Company-wide defaults per role. Director and Admin can edit this matrix. '
        'Personal per-user overrides are Super Admin only (User List → Edit user). '
        'Example: while Admin is on leave, temporarily enable extra Florist permissions, then turn them off after Save.',
    'zh': '按角色设置全公司默认权限。Director 与 Admin 可编辑此矩阵。'
        '个人权限仅 Super Admin 可在「用户列表 → 编辑用户」中设置。'
        '例如：管理员休假时可临时为花艺师开启额外权限，保存后该角色全员生效。',
    'ms': 'Lalai syarikat mengikut peranan. Director dan Admin boleh edit matriks ini. '
        'Ganti peribadi per pengguna hanya Super Admin (Senarai Pengguna → Edit). '
        'Contoh: semasa Admin bercuti, benarkan kebenaran tambahan untuk Florist, kemudian matikan selepas Simpan.',
  },
  'admin.rolePermissions.superAdminNote': {
    'en':
        'Super Admin always has full access. Admin cannot assign the Director role.',
    'zh': 'Super Admin 始终拥有全部权限。Admin 不能分配 Director 角色。',
    'ms':
        'Super Admin sentiasa mempunyai akses penuh. Admin tidak boleh tetapkan peranan Director.',
  },
  'admin.rolePermissions.save': {
    'en': 'Save permissions',
    'zh': '保存权限',
    'ms': 'Simpan kebenaran',
  },
  'admin.rolePermissions.saved': {
    'en': 'Role permissions saved. Staff with that role will pick up changes shortly.',
    'zh': '角色权限已保存，该角色员工将很快生效。',
    'ms': 'Kebenaran peranan disimpan. Staf dengan peranan itu akan menerima perubahan tidak lama lagi.',
  },
  'admin.rolePermissions.saveFailed': {
    'en': 'Save failed: {error}',
    'zh': '保存失败：{error}',
    'ms': 'Simpan gagal: {error}',
  },
  'admin.rolePermissions.defaultsSubtitle': {
    'en': 'Defaults apply unless overridden below.',
    'zh': '以下为默认权限，可在下方覆盖。',
    'ms': 'Lalai terpakai melainkan ditulis ganti di bawah.',
  },
  'admin.rolePermissions.resetDefaults': {
    'en': 'Reset to defaults',
    'zh': '恢复默认',
    'ms': 'Set semula ke lalai',
  },
  'admin.rolePermissions.manageDialogTitle': {
    'en': 'Manage Roles',
    'zh': '管理角色',
    'ms': 'Urus Peranan',
  },
  'admin.userPermissions.sectionTitle': {
    'en': 'Personal permissions (this user only)',
    'zh': '个人权限（仅该用户）',
    'ms': 'Kebenaran peribadi (pengguna ini sahaja)',
  },
  'admin.userPermissions.intro': {
    'en':
        'Override this user\'s access vs their role. Only Super Admin can edit. Changes apply after they reopen the app.',
    'zh': '相对其角色单独调整权限。仅超级管理员可编辑。员工重新打开 App 后生效。',
    'ms':
        'Tulis ganti akses pengguna berbanding peranan. Hanya Super Admin boleh edit. Berkuat kuasa selepas mereka buka semula app.',
  },
  'admin.userPermissions.resetDefaults': {
    'en': 'Clear personal overrides',
    'zh': '清除个人覆盖',
    'ms': 'Kosongkan ganti peribadi',
  },
  'admin.userPermissions.usesRoleDefault': {
    'en': 'Uses role default',
    'zh': '使用角色默认',
    'ms': 'Guna lalai peranan',
  },
  'admin.userPermissions.customOverride': {
    'en': 'Custom for this user',
    'zh': '该用户单独设置',
    'ms': 'Khas untuk pengguna ini',
  },

  'admin.register.title': {
    'en': 'Add staff',
    'zh': '添加员工',
    'ms': 'Tambah staf',
  },
  'admin.register.heading': {
    'en': 'Create staff account',
    'zh': '创建员工账户',
    'ms': 'Cipta akaun staf',
  },
  'admin.register.hintSuperAdmin': {
    'en': 'Super admin: choose company, then create staff (Admin, Senior Florist, or Driver). '
        'You will be signed out — sign in again afterward.',
    'zh': '超级管理员：选择公司后创建员工（管理员、高级花艺师或司机）。'
        '创建后您将登出，请重新登录。',
    'ms': 'Super admin: pilih syarikat, kemudian cipta staf (Admin, Florist Kanan, atau Pemandu). '
        'Anda akan dilog keluar — log masuk semula selepas itu.',
  },
  'admin.register.hintAdmin': {
    'en': 'Creates a staff account for your company (Admin, Senior Florist, or Driver). '
        'You will be signed out — sign in again afterward.',
    'zh': '为本公司创建员工账户（管理员、高级花艺师或司机）。'
        '创建后您将登出，请重新登录。',
    'ms': 'Mencipta akaun staf untuk syarikat anda (Admin, Florist Kanan, atau Pemandu). '
        'Anda akan dilog keluar — log masuk semula selepas itu.',
  },
  'admin.register.fullName': {
    'en': 'Full name',
    'zh': '姓名',
    'ms': 'Nama penuh',
  },
  'admin.register.email': {
    'en': 'Email',
    'zh': '邮箱',
    'ms': 'E-mel',
  },
  'admin.register.phoneOptional': {
    'en': 'Phone (optional)',
    'zh': '电话（可选）',
    'ms': 'Telefon (pilihan)',
  },
  'admin.register.password': {
    'en': 'Password',
    'zh': '密码',
    'ms': 'Kata laluan',
  },
  'admin.register.confirmPassword': {
    'en': 'Confirm password',
    'zh': '确认密码',
    'ms': 'Sahkan kata laluan',
  },
  'admin.register.role': {
    'en': 'Role',
    'zh': '角色',
    'ms': 'Peranan',
  },
  'admin.register.company': {
    'en': 'Company',
    'zh': '公司',
    'ms': 'Syarikat',
  },
  'admin.register.noCompanies': {
    'en': 'No active companies found. Add a company in settings first.',
    'zh': '未找到活跃公司，请先在设置中添加公司。',
    'ms': 'Tiada syarikat aktif dijumpai. Tambah syarikat dalam tetapan dahulu.',
  },
  'admin.register.companyFromProfile': {
    'en': 'Your company (from profile)',
    'zh': '您的公司（来自资料）',
    'ms': 'Syarikat anda (dari profil)',
  },
  'admin.register.submit': {
    'en': 'Create staff account',
    'zh': '创建员工账户',
    'ms': 'Cipta akaun staf',
  },
  'admin.register.submitting': {
    'en': 'Creating…',
    'zh': '创建中…',
    'ms': 'Mencipta…',
  },
  'admin.register.passwordMismatch': {
    'en': 'Passwords do not match.',
    'zh': '两次密码不一致。',
    'ms': 'Kata laluan tidak sepadan.',
  },
  'admin.register.selectRole': {
    'en': 'Please select a role.',
    'zh': '请选择角色。',
    'ms': 'Sila pilih peranan.',
  },
  'admin.register.selectCompany': {
    'en': 'Please select a company.',
    'zh': '请选择公司。',
    'ms': 'Sila pilih syarikat.',
  },
  'admin.register.noCompanyRef': {
    'en': 'Your admin profile has no company. Ask a super admin to set companyRef.',
    'zh': '您的管理员资料未关联公司，请联系超级管理员设置 companyRef。',
    'ms': 'Profil admin anda tiada syarikat. Minta super admin tetapkan companyRef.',
  },
  'admin.register.failed': {
    'en': 'Registration failed.',
    'zh': '注册失败。',
    'ms': 'Pendaftaran gagal.',
  },
  'admin.register.successSignIn': {
    'en': 'Staff account created. Sign in again with your admin account.',
    'zh': '员工账户已创建，请使用管理员账户重新登录。',
    'ms': 'Akaun staf dicipta. Log masuk semula dengan akaun admin anda.',
  },

  'admin.editUser.title': {
    'en': 'Edit user',
    'zh': '编辑员工',
    'ms': 'Edit staf',
  },
  'admin.editUser.name': {
    'en': 'Name',
    'zh': '姓名',
    'ms': 'Nama',
  },
  'admin.editUser.phone': {
    'en': 'Phone',
    'zh': '电话',
    'ms': 'Telefon',
  },
  'admin.editUser.nameRequired': {
    'en': 'Name is required.',
    'zh': '姓名为必填项。',
    'ms': 'Nama diperlukan.',
  },
  'admin.editUser.roleNotAllowed': {
    'en': 'This role cannot be assigned.',
    'zh': '无法分配此角色。',
    'ms': 'Peranan ini tidak boleh ditugaskan.',
  },
  'admin.editUser.saveFailed': {
    'en': 'Save failed: {error}',
    'zh': '保存失败：{error}',
    'ms': 'Simpan gagal: {error}',
  },
};
