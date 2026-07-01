import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '/auth/role_helpers.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/flutter_flow/nav/nav.dart';
import '/l10n/tr.dart';

/// Bottom bulk actions for the order list (assign driver, update status, delete).
class BulkOrderActionBar extends StatelessWidget {
  const BulkOrderActionBar({
    super.key,
    required this.selectedCount,
    required this.onAssignDriver,
    required this.onUpdateStatus,
    this.onDelete,
    this.deleting = false,
  });

  final int selectedCount;
  final VoidCallback onAssignDriver;
  final VoidCallback onUpdateStatus;
  final VoidCallback? onDelete;
  final bool deleting;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final role = AppStateNotifier.instance.userRole;
    final showAssign = canAssignDriver(role);
    final showStatus = canUpdateOrderStatus(role);
    final showDelete = onDelete != null && canDeleteOrders(role);

    if (!showAssign && !showStatus && !showDelete) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
      decoration: BoxDecoration(
        color: theme.secondaryBackground,
        border: Border(top: BorderSide(color: theme.alternate)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            tr(
              context,
              selectedCount > 0
                  ? 'order.bulk.selectedCount'
                  : 'order.bulk.noneSelected',
              params: {'count': '$selectedCount'},
            ),
            style: theme.labelMedium.override(
              font: GoogleFonts.inter(fontWeight: FontWeight.w600),
              color: theme.secondaryText,
            ),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                if (showAssign) ...[
                  _ActionButton(
                    label: tr(context, 'order.bulk.assignDriver'),
                    icon: Icons.local_shipping_outlined,
                    color: theme.primary,
                    onPressed: selectedCount > 0 ? onAssignDriver : null,
                  ),
                  const SizedBox(width: 8),
                ],
                if (showStatus) ...[
                  _ActionButton(
                    label: tr(context, 'order.bulk.updateStatus'),
                    icon: Icons.sync_alt,
                    color: theme.secondary,
                    onPressed: selectedCount > 0 ? onUpdateStatus : null,
                  ),
                  const SizedBox(width: 8),
                ],
                if (showDelete)
                  _ActionButton(
                    label: deleting
                        ? tr(context, 'common.deleting')
                        : tr(context, 'common.delete'),
                    icon: Icons.delete_outline,
                    color: theme.error,
                    onPressed:
                        deleting || selectedCount <= 0 ? null : onDelete,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return FFButtonWidget(
      onPressed: onPressed,
      text: label,
      icon: Icon(icon, size: 16, color: Colors.white),
      options: FFButtonOptions(
        height: 40,
        padding: const EdgeInsetsDirectional.fromSTEB(12, 0, 12, 0),
        color: color,
        textStyle: FlutterFlowTheme.of(context).labelLarge.override(
              font: GoogleFonts.interTight(fontWeight: FontWeight.w600),
              color: Colors.white,
            ),
        elevation: 0,
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }
}
