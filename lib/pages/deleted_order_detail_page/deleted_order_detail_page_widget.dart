import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '/auth/role_helpers.dart';
import '/backend/backend.dart';
import '/backend/deleted_orders_helpers.dart';
import '/backend/order_delete_service.dart';
import '/backend/order_restore_service.dart';
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
        title: Text(tr(context, 'order.deleted.restoreTitle')),
        content: Text(tr(context, 'order.deleted.restoreBodyShort')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(tr(context, 'common.cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(tr(context, 'order.deleted.restore')),
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
        SnackBar(content: Text(tr(context, 'order.deleted.restoreSnack'))),
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
        title: Text(tr(context, 'order.deleted.permanentTitle')),
        content: Text(tr(context, 'order.deleted.permanentBodyShort')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(tr(context, 'common.cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: TextButton.styleFrom(
              foregroundColor: FlutterFlowTheme.of(context).error,
            ),
            child: Text(tr(context, 'order.deleted.permanentButton')),
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
        appBar: AppBar(
          title: Text(tr(context, 'order.deleted.detailShortTitle')),
        ),
        body: Center(
          child: Text(tr(context, 'order.deleted.missingRef')),
        ),
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
          tr(context, 'order.deleted.detailTitle'),
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
                              tr(context, 'order.deleted.banner'),
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
                    _infoCard(
                      context,
                      theme,
                      tr(context, 'order.deleted.colOrderId'),
                      record.orderId,
                    ),
                    _infoCard(
                      context,
                      theme,
                      tr(context, 'order.deleted.colCustomer'),
                      deletedOrderCustomerName(record),
                    ),
                    _infoCard(
                      context,
                      theme,
                      tr(context, 'order.deleted.colOrderDate'),
                      formatDeletedOrderDate(deletedOrderCreatedTime(record)),
                    ),
                    _infoCard(
                      context,
                      theme,
                      tr(context, 'order.deleted.colTotal'),
                      '\$${deletedOrderTotalAmount(record).toStringAsFixed(2)}',
                    ),
                    _infoCard(
                      context,
                      theme,
                      tr(context, 'order.deleted.originalStatus'),
                      deletedOrderStatusLabel(record),
                    ),
                    _infoCard(
                      context,
                      theme,
                      tr(context, 'order.deleted.deletedLabel'),
                      formatDeletedOrderDateTime(record.deletedAt),
                    ),
                    _infoCard(
                      context,
                      theme,
                      tr(context, 'order.deleted.colDeletedBy'),
                      record.deletedByEmail,
                    ),
                    _infoCard(
                      context,
                      theme,
                      tr(context, 'order.deleted.deleteReason'),
                      record.deleteReason.isEmpty ? '—' : record.deleteReason,
                    ),
                    if (record.isRestored) ...[
                      _infoCard(
                        context,
                        theme,
                        tr(context, 'order.deleted.restoredLabel'),
                        formatDeletedOrderDateTime(record.restoredAt),
                      ),
                      _infoCard(
                        context,
                        theme,
                        tr(context, 'order.deleted.restoredBy'),
                        record.restoredByEmail,
                      ),
                    ],
                    const SizedBox(height: 16),
                    Text(
                      tr(context, 'order.deleted.activityLog'),
                      style: theme.titleMedium.override(
                        font: GoogleFonts.interTight(fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (entries.isEmpty)
                      Text(
                        tr(context, 'order.deleted.noActivity'),
                        style: theme.bodyMedium,
                      )
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
                        text: tr(context, 'order.deleted.restoreOrder'),
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
                        text: tr(context, 'order.deleted.permanentlyDelete'),
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

  Widget _infoCard(
    BuildContext context,
    FlutterFlowTheme theme,
    String label,
    String value,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        title: Text(label, style: theme.labelMedium),
        subtitle: Text(value, style: theme.bodyLarge),
      ),
    );
  }
}
