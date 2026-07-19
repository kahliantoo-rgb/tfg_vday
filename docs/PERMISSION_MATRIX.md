# TFG VDAY — Permission Matrix / 权限矩阵

Reference for **30 app permissions**, **role defaults**, and **Firestore overrides**.  
**30 项应用权限**、**角色默认值** 与 **Firestore 覆盖** 的完整说明。

| Item | Detail |
|------|--------|
| **App version** | `v1.0.3 (10)` |
| **Source of truth** | `lib/auth/app_permissions.dart` · `lib/backend/role_permissions_helpers.dart` · `lib/auth/permission_service.dart` |
| **Related docs** | [FEATURES.md](FEATURES.md) · [WORKFLOW.md](WORKFLOW.md) · [DATABASE_SCHEMA.md](DATABASE_SCHEMA.md) |

---

## 1. Three-layer model / 三层权限模型

```mermaid
flowchart TB
    UI[Flutter UI<br/>Menu · buttons · routes]
    PS[PermissionService<br/>effectivePermission]
    DEF[Code defaults<br/>defaultPermissionsForRole]
    FS[(Firestore<br/>role_permissions/{companyId})]
    RULES[firestore.rules<br/>Server enforcement]

    UI --> PS
    PS --> DEF
    PS --> FS
    UI --> RULES
```

| Layer | EN | 中文 | Location |
|-------|----|------|----------|
| **UI gating** | Hide menu items & actions | 隐藏菜单与按钮 | `hasAppPermission()` across pages/components |
| **Effective permission** | Default ∪ Firestore override | 默认 ∪ Firestore 覆盖 | `PermissionService` · `effectivePermission()` |
| **Server rules** | Tenant + role on read/write | 租户 + 角色强制 | `firebase/firestore.rules` |

**Important:** UI permission ≠ full security. Firestore rules always enforce tenant isolation and driver field limits.  
**注意：** UI 权限不等于完整安全；Firestore 规则强制租户隔离与司机字段限制。

---

## 2. Roles / 角色

| Role | Configurable in matrix? | Cross-company? | After login |
|------|-------------------------|----------------|-------------|
| **superadmin** | No — always all permissions | Yes | Company Selection → Dashboard |
| **director** | Yes | No | Sales Dashboard |
| **admin** | Yes | No | Sales Dashboard |
| **manager** | Yes | No | Sales Dashboard |
| **account** | Yes | No | Sales Dashboard |
| **hr** | Yes | No | Sales Dashboard |
| **payroll** | Yes | No | Sales Dashboard |
| **senior_florist** | Yes | No | Sales Dashboard |
| **florist** | Yes | No | Sales Dashboard |
| **driver** | Yes | No | **Driver Delivery Page only** |

**Enum:** `UserRole` in `lib/backend/schema/enums/enums.dart`

**Driver route guard:** Only `/`, `/loginPage`, `/driverDeliveryPage`, `/orderDetailPage` — `lib/auth/role_route_guard.dart`

---

## 3. All 30 permissions / 全部 30 项权限

Defined in `AppPermission` enum — `lib/auth/app_permissions.dart`.

| # | Key | UI label (EN) | Group |
|---|-----|---------------|-------|
| 1 | `accessSalesDashboard` | Access sales dashboard | Core |
| 2 | `manageRolePermissions` | Manage role permissions | Admin |
| 3 | `viewStaffList` | View staff list | Admin |
| 4 | `createStaff` | Add staff | Admin |
| 5 | `editStaffRoles` | Edit staff roles | Admin |
| 6 | `editCompanyProfile` | Edit company profile | Admin |
| 7 | `viewAuditLog` | View audit log | Admin |
| 8 | `applyOrderDiscount` | Apply order discount | Orders |
| 9 | `viewOrders` | View orders | Orders |
| 10 | `createOrders` | Create orders | Orders |
| 11 | `editOrderDetails` | Edit order details | Orders |
| 12 | `editPaidOrderDetails` | Edit paid order details | Orders |
| 13 | `updateOrderStatus` | Update order status | Orders |
| 14 | `assignDriver` | Assign driver | Orders |
| 15 | `printCashInvoice` | Print cash invoice (order) | Orders |
| 16 | `deleteOrders` | Delete orders | Orders |
| 17 | `viewDeletedOrders` | View deleted orders | Orders |
| 18 | `restoreDeletedOrders` | Restore deleted orders | Orders |
| 19 | `permanentlyDeleteDeletedOrders` | Permanently delete archived orders | Orders |
| 20 | `viewCustomers` | View customers | Customers |
| 21 | `editCustomers` | Edit customers | Customers |
| 22 | `createCreditCustomers` | Create credit customers | Customers |
| 23 | `deleteCustomers` | Delete customers | Customers |
| 24 | `viewInvoices` | View invoices | Invoices |
| 25 | `createInvoices` | Create invoices | Invoices |
| 26 | `editInvoices` | Edit invoices | Invoices |
| 27 | `editPaidInvoices` | Edit paid invoices | Invoices |
| 28 | `voidInvoices` | Void invoices | Invoices |
| 29 | `markInvoicesPaid` | Mark invoices paid | Invoices |
| 30 | `manageProducts` | Manage products | Catalog |
| 31 | `exportOrdersCsv` | Export orders CSV | Reports |

---

## 4. Default matrix by role / 角色默认矩阵

Legend: ✅ = granted by default · ❌ = not granted · **—** = N/A (superadmin has all)

| Permission | director | admin | manager | account | hr | payroll | senior_florist | florist | driver |
|------------|:--------:|:-----:|:-------:|:-------:|:--:|:-------:|:--------------:|:-------:|:------:|
| `accessSalesDashboard` | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ❌ |
| `viewOrders` | ✅ | ✅ | ✅ | ✅ | ❌ | ❌ | ✅ | ✅ | ✅ |
| `createOrders` | ✅ | ✅ | ✅ | ❌ | ❌ | ❌ | ✅ | ✅ | ❌ |
| `editOrderDetails` | ✅ | ✅ | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ |
| `editPaidOrderDetails` | ✅ | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ |
| `updateOrderStatus` | ✅ | ✅ | ✅ | ❌ | ❌ | ❌ | ✅ | ✅ | ✅ |
| `assignDriver` | ✅ | ✅ | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ |
| `printCashInvoice` | ✅ | ✅ | ✅ | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ |
| `deleteOrders` | ✅ | ✅ | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ |
| `viewDeletedOrders` | ✅ | ✅ | ✅ | ❌ | ❌ | ❌ | ✅ | ✅ | ❌ |
| `restoreDeletedOrders` | ✅ | ✅ | ✅ | ❌ | ❌ | ❌ | ✅ | ✅ | ❌ |
| `permanentlyDeleteDeletedOrders` | ❌ | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ |
| `exportOrdersCsv` | ✅ | ✅ | ✅ | ❌ | ❌ | ❌ | ✅ | ✅ | ❌ |
| `manageProducts` | ✅ | ✅ | ✅ | ❌ | ❌ | ❌ | ✅ | ✅ | ❌ |
| `viewCustomers` | ✅ | ✅ | ✅ | ✅ | ❌ | ❌ | ✅ | ✅ | ❌ |
| `editCustomers` | ✅ | ✅ | ✅ | ❌ | ❌ | ❌ | ✅ | ✅ | ❌ |
| `createCreditCustomers` | ✅ | ✅ | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ |
| `deleteCustomers` | ❌ | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ |
| `viewInvoices` | ✅ | ✅ | ✅ | ✅ | ❌ | ❌ | ✅ | ✅ | ❌ |
| `createInvoices` | ✅ | ✅ | ✅ | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ |
| `editInvoices` | ✅ | ✅ | ✅ | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ |
| `editPaidInvoices` | ✅ | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ |
| `voidInvoices` | ✅ | ✅ | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ |
| `markInvoicesPaid` | ✅ | ✅ | ✅ | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ |
| `manageRolePermissions` | ✅ | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ |
| `viewStaffList` | ✅ | ✅ | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ |
| `createStaff` | ✅ | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ |
| `editStaffRoles` | ✅ | ✅ | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ |
| `editCompanyProfile` | ❌ | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ |
| `viewAuditLog` | ✅ | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ |
| `applyOrderDiscount` | ❌ | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ |

**superadmin:** all permissions (not stored in matrix).

---

## 5. Role summaries / 角色摘要

| Role | EN summary | 中文摘要 |
|------|------------|----------|
| **director** | Full operations + permissions matrix + staff create/edit + audit; can assign Director; can edit paid invoices/orders by default | 全业务 + 权限矩阵 + 添加/编辑员工 + 审计；可分配 Director；可编辑已付款发票/订单 |
| **admin** | **All company permissions by default** (incl. paid edits, company profile, permanent delete); tenant-scoped; **cannot** assign Director or manage Admin/Director accounts | **默认本公司全部权限**（含已付款编辑、公司资料、永久删归档）；受租户隔离；**不可**分配 Director 或管理 Admin/Director 账号 |
| **manager** | Operations floor + invoices + driver assign + delete orders + staff list (no permissions UI) | 运营全权限 + 发票 + 派司机（无权限矩阵编辑） |
| **account** | Dashboard + invoices + view customers/orders + print | 账务：发票与客户/订单查看 |
| **hr / payroll** | Dashboard access only (expand via matrix) | 仅主页；可通过矩阵扩展 |
| **senior_florist / florist** | Operations floor — orders, products, CSV, deleted restore | 一线：订单、产品、CSV、恢复归档 |
| **driver** | View orders + update status on assigned deliveries | 查看订单 + 更新配送状态 |

**Operations floor** (`_operationsFloorPermissions`): dashboard, orders CRUD (no edit details), status, CSV, products, deleted view/restore, customers view/edit, invoices view.

---

## 6. Firestore storage / Firestore 存储

**Document:** `role_permissions/{canonicalCompanyId}`

```json
{
  "companyRef": "Companies/{id}",
  "updated_time": "<timestamp>",
  "roles": {
    "florist": {
      "assignDriver": true,
      "deleteOrders": false
    },
    "driver": {
      "viewOrders": true
    }
  }
}
```

| Rule | Detail |
|------|--------|
| **Doc ID** | Canonical company ID — `lib/backend/tenant_company_helpers.dart` |
| **roleKey** | `UserRole.serialize()` e.g. `director`, `florist` |
| **permissionKey** | `AppPermission.name` e.g. `viewOrders` |
| **Stored values** | **Overrides only** — `true` or `false`; absent = use code default |
| **Who can edit doc** | Firestore: director, admin, superadmin |

**Assignable roles list (separate doc):** `staff_roles/{companyId}` → `{ roles: ["florist", "driver", …] }`

---

## 7. UI: editing the matrix / 编辑权限矩阵

| Item | Detail |
|------|--------|
| **Route** | `/rolePermissionsPage` |
| **Entry** | User List → shield icon · Menu (admin section) |
| **Who can open** | `manageRolePermissions` (director, admin, superadmin by default) |
| **Configurable roles** | All 9 staff roles except superadmin |
| **Editable keys** | `editablePermissionKeys()` — excludes `accessSalesDashboard` and `manageRolePermissions` from toggles |
| **Component** | `lib/components/manage_role_permissions_panel.dart` |

On save → `saveTenantRolePermissionOverrides()` → Firestore merge.

---

## 8. Resolution algorithm / 生效逻辑

```dart
// lib/backend/role_permissions_helpers.dart — effectivePermission()
if (role == superadmin) return true;
if (Firestore override exists for role+permission) return override;
return defaultPermissionsForRole(role).contains(permission);
```

`PermissionService` loads overrides on company context init and streams live updates.

**Usage in UI:**

```dart
hasAppPermission(currentUserRole, AppPermission.createOrders)
```

---

## 9. Menu gating examples / 菜单权限示例

| Menu item | Permission |
|-----------|------------|
| All Orders | `viewOrders` |
| Driver Assignments | `assignDriver` |
| Deleted Orders | `viewDeletedOrders` |
| Customers | `viewCustomers` |
| Invoice List | `viewInvoices` |
| Product / Material List | `manageProducts` |
| Sales / Material / Profit reports | `accessSalesDashboard` + report-specific |
| User List | `viewStaffList` |
| Company Profile | `editCompanyProfile` (edit) · view for others |
| Audit Log | `viewAuditLog` |
| Apply order discount (Retail / Delivery payment) | `applyOrderDiscount` |
| + Create Order | `createOrders` |
| CSV export actions | `exportOrdersCsv` |

Dashboard menu builder: `lib/pages/sales_dash_board/` — empty sections hidden when no permission.

---

## 10. Firestore rules vs app permissions / 规则与 App 权限

App permissions control **UI visibility**. Firestore rules control **data access**:

| Concern | App permission | Firestore rule |
|---------|----------------|----------------|
| View company orders | `viewOrders` | `isStaffUser()` + tenant `companyRef` |
| Driver update status | `updateOrderStatus` | Driver + limited field whitelist |
| Edit role_permissions | `manageRolePermissions` | director/admin/superadmin |
| Apply order discount fields | `applyOrderDiscount` | platform admin only (`discount` / `discount_label` / `discount_remark`) |
| Delete orders (archive) | `deleteOrders` | platform admin role in rules |
| Cross-tenant read | superadmin UI | `canCrossTenantAccess()` |

Rules tests: `firebase/test/firestore.rules.test.js` — run `npm run test:firebase`.

---

## 11. Staff lifecycle permissions / 员工管理权限

| Action | Permission | Notes |
|--------|------------|-------|
| View user list | `viewStaffList` | `/userListPage` |
| Register staff | `createStaff` | `/register` — no public signup |
| Change user role | `editStaffRoles` | User list actions |
| Set inactive | `editStaffRoles` or admin flow | `is_active: false` blocks login |
| Delete profile | Admin / platform | Removes Firestore doc only |

### Director vs Admin scope / Director 与 Admin 差异

| Action | Director | Admin |
|--------|:--------:|:-----:|
| Edit role permission matrix | ✅ | ✅ |
| Add staff (Register) | ✅ all assignable roles | ✅ except Director |
| Change user role | ✅ including Director | ✅ except Director |
| Deactivate/delete user | ✅ below Director tier | ✅ below Admin tier (not Admin/Director) |
| Manage company assignable roles list | ✅ includes Director | ✅ excludes Director |
| Per-user permission overrides | ❌ Super Admin only | ❌ Super Admin only |

---

## 12. Implementation index / 实现索引

| File | Purpose |
|------|---------|
| `lib/auth/app_permissions.dart` | Enum, labels, defaults, editable keys |
| `lib/auth/permission_service.dart` | Singleton + Firestore stream |
| `lib/backend/role_permissions_helpers.dart` | Load/save/resolve overrides |
| `lib/backend/staff_role_helpers.dart` | Assignable roles list |
| `lib/components/manage_role_permissions_panel.dart` | Matrix UI |
| `lib/pages/role_permissions_page/` | Full page wrapper |
| `lib/auth/role_route_guard.dart` | Driver route allow-list |
| `firebase/firestore.rules` | Server-side enforcement |

---

*Permission matrix for `tfg_vday` at version **v1.0.3 (10)**. Defaults reflect `defaultPermissionsForRole()` in `app_permissions.dart`.*

*对应版本 **v1.0.3 (10)**；默认值以 `app_permissions.dart` 为准。*
