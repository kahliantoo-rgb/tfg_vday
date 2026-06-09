import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '/backend/audit_log_helpers.dart';
import '/backend/audit_log_service.dart';
import '/backend/order_activity_log_service.dart';
import '/backend/schema/audit_logs_record.dart';
import '/backend/tenant_query_helpers.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';

/// Collapsible delete / restore / edit audit entries for an active order.
class OrderActivityLogPanel extends StatelessWidget {
  const OrderActivityLogPanel({
    super.key,
    required this.orderRef,
  });

  final DocumentReference orderRef;

  String _actionLabel(String action) {
    switch (action) {
      case OrderActivityAction.orderDelete:
      case AuditLogAction.deleteOrder:
        return 'Order deleted';
      case OrderActivityAction.orderRestore:
        return 'Order restored';
      case OrderActivityAction.orderPermanentDelete:
        return 'Archive permanently deleted';
      default:
        return auditActionLabel(action);
    }
  }

  String _formatTimestamp(DateTime? value) {
    if (value == null) {
      return '—';
    }
    return dateTimeFormat('d MMM yyyy, h:mm a', value);
  }

  String _entrySubtitle(AuditLogsRecord log) {
    final detail = log.description.isNotEmpty
        ? log.description
        : log.entityLabel;
    final lines = <String>[
      'By ${auditLogPerformerLabel(log)}',
      if (detail.isNotEmpty) detail,
      _formatTimestamp(log.createdAt),
    ];
    return lines.join('\n');
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);

    return FutureBuilder<List<AuditLogsRecord>>(
      future: queryOrderActivityLogsOnce(orderRef),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const SizedBox.shrink();
        }
        final logs = snapshot.data ?? const [];
        if (logs.isEmpty) {
          return const SizedBox.shrink();
        }

        return Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: theme.secondaryBackground,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: theme.alternate),
          ),
          child: Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              initiallyExpanded: false,
              tilePadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              childrenPadding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
              title: Text(
                'Activity Log (${logs.length})',
                style: theme.titleMedium.override(
                  font: GoogleFonts.interTight(fontWeight: FontWeight.bold),
                ),
              ),
              subtitle: Text(
                'Tap to view who changed this order',
                style: theme.bodySmall.override(
                  font: GoogleFonts.inter(),
                  color: theme.secondaryText,
                ),
              ),
              children: logs
                  .map(
                    (log) => ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                      dense: true,
                      leading: Icon(
                        log.action == OrderActivityAction.orderRestore ||
                                log.action == AuditLogAction.updateOrder
                            ? Icons.restore
                            : Icons.history,
                        color: theme.primary,
                        size: 20,
                      ),
                      title: Text(_actionLabel(log.action)),
                      subtitle: Text(_entrySubtitle(log)),
                      isThreeLine: true,
                    ),
                  )
                  .toList(),
            ),
          ),
        );
      },
    );
  }
}
