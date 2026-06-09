import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '/auth/role_helpers.dart';
import '/backend/backend.dart';
import '/backend/deleted_orders_helpers.dart';
import '/backend/order_delete_service.dart';
import '/backend/order_restore_service.dart';
import '/components/home_nav_button.dart';
import '/components/home_nav_button.dart';
import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/flutter_flow/nav/nav.dart';

class DeletedOrderDetailPageWidget extends StatefulWidget {
  const DeletedOrderDetailPageWidget({
    super.key,
    required this.deletedOrderRef,
  });

  final DocumentReference? deletedOrderRef;

  static String routeName = 'DeletedOrderDetailPage';
  static String routePath = '/deletedOrderDetailPage';

  @override
  State<DeletedOrderDetailPageWidget> createState() =>
      _DeletedOrderDetailPageWidgetState();
}

class _DeletedOrderDetailPageWidgetState
    extends State<DeletedOrderDetailPageWidget> {
  bool _busy = false;

  Future<void> _confirmRestore(DeletedOrdersRecord record) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Restore order?'),
        content: const Text(
          'This order will reappear in Active Orders after restore.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Restore'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) {
      return;
    }

    setState(() => _busy = true);
    try {
      await restoreDeletedOrder(record);
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Order restored.')),
      );
      context.safePop();
    } on OrderRestoreException catch (e) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _confirmPermanentDelete(DeletedOrdersRecord record) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Permanently delete?'),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: TextButton.styleFrom(
              foregroundColor: FlutterFlowTheme.of(context).error,
            ),
            child: const Text('Delete permanently'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) {
      return;
    }

    setState(() => _busy = true);
    try {
      await permanentlyDeleteArchivedOrder(record);
      if (!mounted) {
        return;
      }
      context.safePop();
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final role = AppStateNotifier.instance.userRole;
    final canRestore = canRestoreDeletedOrders(role);
    final canPermanentDelete = canPermanentlyDeleteDeletedOrders(role);

    if (widget.deletedOrderRef == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Deleted Order')),
        body: const Center(child: Text('Missing archive reference.')),
      );
    }

    return Scaffold(
      backgroundColor: theme.primaryBackground,
      appBar: AppBar(
        backgroundColor: theme.primary,
        automaticallyImplyLeading: false,
        leading: FlutterFlowIconButton(
          borderColor: Colors.transparent,
          borderRadius: 30.0,
          buttonSize: 46.0,
          icon: Icon(Icons.arrow_back_rounded, color: theme.info, size: 25.0),
          onPressed: () => context.safePop(),
        ),
        title: Text(
          'Deleted Order Details',
          style: theme.headlineMedium.override(
            font: GoogleFonts.interTight(fontWeight: FontWeight.w600),
            color: theme.info,
            fontSize: 22.0,
          ),
        ),
        actions: [
          Padding(
            padding: EdgeInsetsDirectional.fromSTEB(0, 0, 12, 0),
            child: HomeNavIconButton(),
          ),
        ],
        elevation: 0.0,
      ),
      body: Stack(
        children: [
          StreamBuilder<DeletedOrdersRecord>(
            stream: DeletedOrdersRecord.getDocument(widget.deletedOrderRef!),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final record = snapshot.data!;
              final entries = sortedActivityLogEntries(record.activityLog);

              return SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: theme.error.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: theme.error),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.warning_amber_rounded, color: theme.error),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'This order was deleted and is not in Active Orders.',
                              style: theme.bodyLarge.override(
                                color: theme.error,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    _infoCard(theme, 'Order ID', record.orderId),
                    _infoCard(theme, 'Customer', deletedOrderCustomerName(record)),
                    _infoCard(
                      theme,
                      'Order date',
                      formatDeletedOrderDate(deletedOrderCreatedTime(record)),
                    ),
                    _infoCard(
                      theme,
                      'Total',
                      '\$${deletedOrderTotalAmount(record).toStringAsFixed(2)}',
                    ),
                    _infoCard(
                      theme,
                      'Original status',
                      deletedOrderStatusLabel(record),
                    ),
                    _infoCard(
                      theme,
                      'Deleted',
                      formatDeletedOrderDateTime(record.deletedAt),
                    ),
                    _infoCard(theme, 'Deleted by', record.deletedByEmail),
                    _infoCard(
                      theme,
                      'Delete reason',
                      record.deleteReason.isEmpty ? '—' : record.deleteReason,
                    ),
                    if (record.isRestored) ...[
                      _infoCard(
                        theme,
                        'Restored',
                        formatDeletedOrderDateTime(record.restoredAt),
                      ),
                      _infoCard(theme, 'Restored by', record.restoredByEmail),
                    ],
                    const SizedBox(height: 16),
                    Text(
                      'Activity Log',
                      style: theme.titleMedium.override(
                        font: GoogleFonts.interTight(fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (entries.isEmpty)
                      Text('No activity recorded.', style: theme.bodyMedium)
                    else
                      ...entries.map(
                        (entry) => Card(
                          child: ListTile(
                            leading: Icon(
                              entry['action'] == 'restored'
                                  ? Icons.restore
                                  : Icons.delete_outline,
                              color: theme.primary,
                            ),
                            title: Text(activityLogActionLabel(
                              entry['action'] as String? ?? '',
                            )),
                            subtitle: Text(
                              '${entry['by_email'] ?? '—'}\n'
                              '${formatDeletedOrderDateTime(activityLogEntryTime(entry))}'
                              '${entry['note'] != null ? '\n${entry['note']}' : ''}',
                            ),
                            isThreeLine: entry['note'] != null,
                          ),
                        ),
                      ),
                    const SizedBox(height: 16),
                    if (canRestore && !record.isRestored)
                      FFButtonWidget(
                        onPressed: () => _confirmRestore(record),
                        text: 'Restore Order',
                        options: FFButtonOptions(
                          width: double.infinity,
                          height: 44,
                          color: theme.primary,
                          textStyle: theme.titleSmall.override(
                            font: GoogleFonts.interTight(),
                            color: theme.info,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    if (canPermanentDelete) ...[
                      const SizedBox(height: 10),
                      FFButtonWidget(
                        onPressed: () => _confirmPermanentDelete(record),
                        text: 'Permanently Delete',
                        options: FFButtonOptions(
                          width: double.infinity,
                          height: 44,
                          color: theme.error,
                          textStyle: theme.titleSmall.override(
                            font: GoogleFonts.interTight(),
                            color: theme.info,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ],
                  ],
                ),
              );
            },
          ),
          if (_busy)
            Container(
              color: Colors.black26,
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }

  Widget _infoCard(FlutterFlowTheme theme, String label, String value) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        title: Text(label, style: theme.labelMedium),
        subtitle: Text(value, style: theme.bodyLarge),
      ),
    );
  }
}
