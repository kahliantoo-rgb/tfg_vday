import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '/auth/record_edit_permissions.dart';
import '/auth/role_helpers.dart';
import '/backend/backend.dart';
import '/backend/order_navigation_helpers.dart';
import '/backend/order_production_menu_helpers.dart';
import '/backend/reprint_receipt_helpers.dart';
import '/backend/staff_notice_helpers.dart';
import '/backend/schema/enums/enums.dart';
import '/components/assign_driver_sheet.dart';
import '/components/edit_order_details_widget.dart';
import '/components/edit_order_products_widget.dart';
import '/components/update_order_status_widget.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/l10n/tr.dart';

class OrderDetailActionBar extends StatelessWidget {
  const OrderDetailActionBar({
    super.key,
    required this.order,
    required this.orderRef,
    this.onOrderChanged,
  });

  final OrdersRecord order;
  final DocumentReference orderRef;
  final VoidCallback? onOrderChanged;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final role = AppStateNotifier.instance.userRole;
    final actions = _buildActions(context, role);

    if (actions.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: theme.secondaryBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.alternate),
      ),
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            tr(context, 'order.action.barTitle'),
            style: theme.labelMedium.override(
              font: GoogleFonts.inter(fontWeight: FontWeight.w600),
              color: theme.secondaryText,
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 76,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: actions.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final action = actions[index];
                return _ActionBarTile(
                  icon: action.icon,
                  label: action.label,
                  color: action.color,
                  onTap: action.onTap,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  List<_OrderDetailAction> _buildActions(BuildContext context, UserRole? role) {
    final theme = FlutterFlowTheme.of(context);
    final actions = <_OrderDetailAction>[];

    void add({
      required IconData icon,
      required String label,
      required Color color,
      required VoidCallback onTap,
    }) {
      actions.add(
        _OrderDetailAction(
          icon: icon,
          label: label,
          color: color,
          onTap: onTap,
        ),
      );
    }

    if (canEditOrderRecord(role, order)) {
      add(
        icon: Icons.person_outline,
        label: tr(context, 'order.action.editAddress'),
        color: theme.tertiary,
        onTap: () => showEditOrderDetailsSheet(
          context,
          orderRef: orderRef,
          order: order,
        ),
      );
      add(
        icon: Icons.shopping_bag_outlined,
        label: tr(context, 'order.action.editProducts'),
        color: theme.primary,
        onTap: () => showEditOrderProductsSheet(
          context,
          orderRef: orderRef,
          order: order,
        ),
      );
    }

    if (canAssignDriver(role)) {
      final assigned = order.hasAssignedDriver();
      add(
        icon: assigned
            ? Icons.check_circle_outline
            : Icons.local_shipping_outlined,
        label: assigned
            ? tr(context, 'order.driver.assigned')
            : tr(context, 'order.action.assignDriver'),
        color: assigned ? theme.success : theme.tertiary,
        onTap: () => showAssignDriverSheet(
          context,
          orderRef: orderRef,
          order: order,
        ),
      );
    }

    if (canPrintCashInvoice(role)) {
      add(
        icon: Icons.receipt_long,
        label: tr(context, 'order.action.printReceipt'),
        color: theme.secondary,
        onTap: () => promptAndReprintOrderReceipt(context, orderRef, order),
      );
    }

    add(
      icon: Icons.restaurant_menu,
      label: tr(context, 'order.action.productionMenu'),
      color: theme.tertiary,
      onTap: () => openProductionMenuPreview(context, orderRef),
    );

    if (isSuperAdminRole(role)) {
      add(
        icon: Icons.local_florist,
        label: tr(context, 'order.action.sendPurchaseReminder'),
        color: theme.warning,
        onTap: () => _sendPurchaseReminder(context),
      );
    }

    if (canUpdateOrderStatus(role)) {
      add(
        icon: Icons.check_circle_outline,
        label: tr(context, 'order.action.updateStatus'),
        color: theme.primary,
        onTap: () => _openUpdateStatusSheet(context),
      );
    }

    add(
      icon: Icons.local_shipping,
      label: tr(context, 'order.action.deliveryOrder'),
      color: Colors.purple,
      onTap: () => runDeliveryOrderFlow(context, orderRef),
    );

    return actions;
  }

  Future<void> _sendPurchaseReminder(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(tr(dialogContext, 'order.purchaseReminder.confirmTitle')),
          content: Text(tr(dialogContext, 'order.purchaseReminder.confirmBody')),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: Text(tr(dialogContext, 'common.cancel')),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: Text(tr(dialogContext, 'order.purchaseReminder.send')),
            ),
          ],
        );
      },
    );
    if (confirmed != true || !context.mounted) {
      return;
    }
    try {
      final sent = await sendSpecialProcurementReminder(
        order: order,
        actorRole: AppStateNotifier.instance.userRole,
      );
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            sent > 0
                ? tr(
                    context,
                    'order.purchaseReminder.sent',
                    params: {'count': '$sent'},
                  )
                : tr(context, 'order.purchaseReminder.noRecipients'),
          ),
        ),
      );
    } catch (_) {
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(tr(context, 'order.purchaseReminder.failed')),
        ),
      );
    }
  }

  Future<void> _openUpdateStatusSheet(BuildContext context) async {
    await showModalBottomSheet(
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      enableDrag: false,
      context: context,
      builder: (sheetContext) {
        return GestureDetector(
          onTap: () {
            FocusScope.of(sheetContext).unfocus();
            FocusManager.instance.primaryFocus?.unfocus();
          },
          child: Padding(
            padding: MediaQuery.viewInsetsOf(sheetContext),
            child: UpdateOrderStatusWidget(orderRef: orderRef),
          ),
        );
      },
    );
    onOrderChanged?.call();
  }
}

class _OrderDetailAction {
  const _OrderDetailAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
}

class _ActionBarTile extends StatelessWidget {
  const _ActionBarTile({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);

    return Material(
      color: theme.primaryBackground,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: SizedBox(
          width: 76,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, size: 20, color: color),
                ),
                const SizedBox(height: 6),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    height: 1.15,
                    fontWeight: FontWeight.w500,
                    color: theme.primaryText,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
