import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '/auth/role_helpers.dart';
import '/backend/backend.dart';
import '/backend/schema/enums/enums.dart';
import '/backend/tenant_company_helpers.dart';
import '/backend/tenant_context.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/nav/nav.dart';

Future<void> showAssignDriverSheet(
  BuildContext context, {
  required DocumentReference orderRef,
  required OrdersRecord order,
}) async {
  if (!canAssignDriver(AppStateNotifier.instance.userRole)) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Only administrators can assign drivers.')),
    );
    return;
  }

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) {
      return _AssignDriverSheet(
        orderRef: orderRef,
        order: order,
      );
    },
  );
}

class _AssignDriverSheet extends StatefulWidget {
  const _AssignDriverSheet({
    required this.orderRef,
    required this.order,
  });

  final DocumentReference orderRef;
  final OrdersRecord order;

  @override
  State<_AssignDriverSheet> createState() => _AssignDriverSheetState();
}

class _AssignDriverSheetState extends State<_AssignDriverSheet> {
  bool _loading = true;
  bool _saving = false;
  List<UsersRecord> _drivers = [];
  DocumentReference? _selectedDriverRef;

  @override
  void initState() {
    super.initState();
    _selectedDriverRef = widget.order.assignedDriver;
    _loadDrivers();
  }

  Future<void> _loadDrivers() async {
    final companyId = TenantContext.instance.writeCompanyId;
    final all = await queryUsersRecordOnce(
      queryBuilder: (q) =>
          q.where('role', isEqualTo: UserRole.driver.serialize()),
    );
    final drivers = all.where((u) {
      if (companyId.isEmpty) {
        return true;
      }
      return canonicalCompanyId(u.companyRef?.id) == companyId;
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
        const SnackBar(content: Text('Select a driver.')),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      await widget.orderRef.update(
        createOrdersRecordData(
          assignedDriver: _selectedDriverRef,
        ),
      );
      if (!mounted) {
        return;
      }
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Driver assigned.')),
      );
    } catch (e) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not assign driver: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.7,
        ),
        decoration: BoxDecoration(
          color: FlutterFlowTheme.of(context).secondaryBackground,
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
                'Assign driver',
                style: FlutterFlowTheme.of(context).titleLarge.override(
                      font: GoogleFonts.interTight(fontWeight: FontWeight.w600),
                    ),
              ),
              const SizedBox(height: 12),
              if (_loading)
                const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_drivers.isEmpty)
                Text(
                  'No drivers found for this company.',
                  style: FlutterFlowTheme.of(context).bodyMedium,
                )
              else
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: _drivers.length,
                    itemBuilder: (context, index) {
                      final driver = _drivers[index];
                      final selected =
                          _selectedDriverRef?.path == driver.reference.path;
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
                        selected: selected,
                      );
                    },
                  ),
                ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: _saving || _loading ? null : _save,
                child: Text(_saving ? 'Saving…' : 'Save'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
