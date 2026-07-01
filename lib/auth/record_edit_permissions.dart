import '/auth/app_permissions.dart';
import '/auth/permission_service.dart';
import '/auth/role_helpers.dart';
import '/backend/invoice_list_helpers.dart';
import '/backend/schema/invoices_record.dart';
import '/backend/schema/orders_record.dart';
import '/backend/schema/enums/enums.dart';

bool canEditPaidInvoices(UserRole? role) =>
    hasAppPermission(role, AppPermission.editPaidInvoices);

bool canEditPaidOrderDetails(UserRole? role) =>
    hasAppPermission(role, AppPermission.editPaidOrderDetails);

bool canEditInvoiceRecord(UserRole? role, InvoicesRecord invoice) {
  if (invoice.status == InvoiceStatus.voided) {
    return false;
  }
  if (!canEditInvoices(role)) {
    return false;
  }
  if (invoice.status == InvoiceStatus.paid && !canEditPaidInvoices(role)) {
    return false;
  }
  return true;
}

bool canEditOrderRecord(UserRole? role, OrdersRecord order) {
  if (!canEditOrderDetails(role)) {
    return false;
  }
  if (isCustomerOrderPaid(order) && !canEditPaidOrderDetails(role)) {
    return false;
  }
  return true;
}

void assertCanEditInvoiceRecord(UserRole? role, InvoicesRecord invoice) {
  if (invoice.status == InvoiceStatus.voided) {
    throw InvoiceWriteException('Voided invoices cannot be edited.');
  }
  if (invoice.status == InvoiceStatus.paid && !canEditPaidInvoices(role)) {
    throw InvoiceWriteException('Paid invoices cannot be edited.');
  }
}

void assertCanEditOrderRecord(UserRole? role, OrdersRecord order) {
  if (isCustomerOrderPaid(order) && !canEditPaidOrderDetails(role)) {
    throw StateError('Paid orders cannot be edited.');
  }
}
