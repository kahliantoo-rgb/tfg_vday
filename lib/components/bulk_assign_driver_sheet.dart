import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '/auth/viewer_role_helpers.dart';
import '/auth/role_helpers.dart';
import '/backend/backend.dart';
import '/backend/bulk_order_actions_helpers.dart';
import '/backend/schema/enums/enums.dart';
import '/backend/schema/orders_record.dart';
import '/backend/tenant_company_helpers.dart';
import '/backend/tenant_context.dart';
import '/backend/user_list_helpers.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/l10n/tr.dart';

Future<bool> showBulkAssignDriverSheet(
  BuildContext context, {
  required List<OrdersRecord> orders,
}) async {
  if (!canAssignDriver(currentViewerRole())) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(tr(context, 'order.bulk.assignDriverDenied'))),
    );
    return false;
  }
  if (orders.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(tr(context, 'order.bulk.selectFirst'))),
    );
    return false;
  }

  final result = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) => _BulkAssignDriverSheet(orders: orders),
  );
  return result == true;
}

class _BulkAssignDriverSheet extends StatefulWidget {
  const _BulkAssignDriverSheet({required this.orders});

  final List<OrdersRecord> orders;

  @override
  State<_BulkAssignDriverSheet> createState() => _BulkAssignDriverSheetState();
}

class _BulkAssignDriverSheetState extends State<_BulkAssignDriverSheet> {
  bool _loading = true;
  bool _saving = false;
  List<UsersRecord> _drivers = [];
  DocumentReference? _selectedDriverRef;

  @override
  void initState() {
    super.initState();
    _loadDrivers();
  }

  Future<void> _loadDrivers() async {
    final companyId = TenantContext.instance.writeCompanyId;
    final all = await queryUsersRecordOnce(
      queryBuilder: (q) =>
          q.where('role', isEqualTo: UserRole.driver.serialize()),
    );
    final drivers = all.where((user) {
      if (!userIsActive(user)) {
        return false;
      }
      if (companyId.isEmpty) {
        return true;
      }
      return canonicalCompanyId(user.companyRef?.id) == companyId;
    }).toList()
      ..sort(
        (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
      );

    if (!mounted) {
      return;
    }
    setState(() {
      _drivers = drivers;
      _loading = false;
    });
  }

  Future<void> _save() async {
    if (_selectedDriverRef == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(tr(context, 'order.bulk.pickDriver'))),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      final count = await bulkAssignDriverToOrders(
        orders: widget.orders,
        driverUserRef: _selectedDriverRef!,
      );
      if (!mounted) {
        return;
      }
      Navigator.of(context).pop(true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            tr(
              context,
              'order.bulk.driverAssigned',
              params: {'count': '$count'},
            ),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            tr(context, 'order.bulk.assignDriverFailed', params: {'error': '$e'}),
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    return Material(
      color: Colors.transparent,
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.72,
        ),
        decoration: BoxDecoration(
          color: theme.secondaryBackground,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            16,
            20,
            20 + MediaQuery.paddingOf(context).bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                tr(context, 'order.bulk.assignDriverTitle'),
                style: theme.titleLarge.override(
                  font: GoogleFonts.interTight(fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                tr(
                  context,
                  'order.bulk.selectedCount',
                  params: {'count': '${widget.orders.length}'},
                ),
                style: theme.bodySmall.override(color: theme.secondaryText),
              ),
              const SizedBox(height: 12),
              if (_loading)
                const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_drivers.isEmpty)
                Text(tr(context, 'order.bulk.noDrivers'))
              else
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: _drivers.length,
                    itemBuilder: (context, index) {
                      final driver = _drivers[index];
                      return RadioListTile<DocumentReference>(
                        value: driver.reference,
                        groupValue: _selectedDriverRef,
                        onChanged: _saving
                            ? null
                            : (ref) =>
                                setState(() => _selectedDriverRef = ref),
                        title: Text(
                          driver.name.isNotEmpty ? driver.name : driver.email,
                        ),
                        subtitle: driver.email.isNotEmpty
                            ? Text(driver.email)
                            : null,
                      );
                    },
                  ),
                ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: _saving || _loading ? null : _save,
                child: Text(
                  _saving
                      ? tr(context, 'common.saving')
                      : tr(context, 'order.bulk.assignDriverConfirm'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
