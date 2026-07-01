import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '/auth/app_permissions.dart';
import '/auth/role_helpers.dart';
import '/auth/viewer_role_helpers.dart';
import '/backend/backend.dart';
import '/backend/create_order_service.dart';
import '/backend/schema/enums/enums.dart';
import '/backend/tenant_company_helpers.dart';
import '/backend/tenant_context.dart';
import '/backend/tenant_query_helpers.dart';
import '/backend/user_query_helpers.dart';
import '/flutter_flow/flutter_flow_util.dart';

/// Roles offered when adding staff before a company saves its own list.
const defaultCompanyStaffRoles = <UserRole>[
  UserRole.admin,
  UserRole.senior_florist,
  UserRole.florist,
  UserRole.driver,
];

List<UserRole> defaultStaffRolesForCompanyId(String companyId) {
  return List<UserRole>.from(defaultCompanyStaffRoles);
}

List<UserRole> normalizeStaffRoleList(Iterable<UserRole> values) {
  final seen = <UserRole>{};
  final normalized = <UserRole>[];
  for (final role in values) {
    if (role == UserRole.superadmin || !assignableStaffRoles.contains(role)) {
      continue;
    }
    if (seen.add(role)) {
      normalized.add(role);
    }
  }
  normalized.sort(
    (a, b) =>
        userRoleLabel(a).toLowerCase().compareTo(userRoleLabel(b).toLowerCase()),
  );
  return normalized;
}

List<UserRole> parseStaffRolesFromData(Map<String, dynamic>? data) {
  if (data == null) {
    return const [];
  }
  final raw = data['roles'];
  if (raw is! List) {
    return const [];
  }
  final parsed = <UserRole>[];
  for (final value in raw) {
    if (value is! String) {
      continue;
    }
    final role = deserializeEnum<UserRole>(value);
    if (role != null) {
      parsed.add(role);
    }
  }
  return normalizeStaffRoleList(parsed);
}

DocumentReference? tenantStaffRolesCompanyRef() {
  final ref = TenantContext.instance.writeCompanyRef ??
      TenantContext.instance.activeCompanyRef;
  if (ref == null) {
    return null;
  }
  return canonicalCompanyRef(ref);
}

DocumentReference? tenantStaffRolesDocRef() {
  final companyRef = tenantStaffRolesCompanyRef();
  if (companyRef == null) {
    return null;
  }
  return FirebaseFirestore.instance
      .collection('staff_roles')
      .doc(canonicalCompanyId(companyRef.id));
}

Stream<List<UserRole>> streamTenantStaffRoles() {
  final docRef = tenantStaffRolesDocRef();
  if (docRef == null) {
    return Stream.value(const <UserRole>[]);
  }
  return docRef.snapshots().map(
        (snapshot) => parseStaffRolesFromData(
          snapshot.data() as Map<String, dynamic>?,
        ),
      );
}

Future<List<UserRole>> loadTenantStaffRolesOnce() async {
  final docRef = tenantStaffRolesDocRef();
  if (docRef == null) {
    return const [];
  }
  final snapshot = await docRef.get();
  return parseStaffRolesFromData(
    snapshot.data() as Map<String, dynamic>?,
  );
}

Future<void> ensureTenantStaffRolesInitialized() async {
  final docRef = tenantStaffRolesDocRef();
  final companyRef = tenantStaffRolesCompanyRef();
  if (docRef == null || companyRef == null) {
    return;
  }

  final target = defaultStaffRolesForCompanyId(companyRef.id);
  if (target.isEmpty) {
    return;
  }

  final snapshot = await docRef.get();
  if (!snapshot.exists) {
    await saveTenantStaffRoles(target);
    return;
  }

  final existing = parseStaffRolesFromData(
    snapshot.data() as Map<String, dynamic>?,
  );
  if (existing.isEmpty) {
    await saveTenantStaffRoles(target);
  }
}

Future<List<UserRole>> loadManagedStaffRolesWithFallback() async {
  try {
    await ensureTenantStaffRolesInitialized();
    final stored = await loadTenantStaffRolesOnce();
    if (stored.isNotEmpty) {
      return stored;
    }
  } catch (_) {
    // Fall back below.
  }
  final companyRef = tenantStaffRolesCompanyRef();
  if (companyRef == null) {
    return const [];
  }
  return defaultStaffRolesForCompanyId(companyRef.id);
}

Future<void> saveTenantStaffRoles(List<UserRole> roles) async {
  final docRef = tenantStaffRolesDocRef();
  final companyRef = tenantStaffRolesCompanyRef();
  if (docRef == null || companyRef == null) {
    throw StateError('No company selected for staff role save.');
  }
  final rulesCompanyRef =
      TenantContext.instance.rulesMatchedCompanyRef ?? companyRef;
  await docRef.set(
    {
      'companyRef': rulesCompanyRef,
      'roles': normalizeStaffRoleList(roles)
          .map((role) => role.serialize())
          .toList(),
      'updated_time': getCurrentTimestamp,
    },
    SetOptions(merge: true),
  );
}

Future<String?> addTenantStaffRole(UserRole role) async {
  if (!assignableStaffRoles.contains(role)) {
    return 'This role cannot be added.';
  }
  try {
    final current = await loadManagedStaffRolesWithFallback();
    if (current.contains(role)) {
      return 'Role already exists.';
    }
    await saveTenantStaffRoles([...current, role]);
    return null;
  } catch (error) {
    return describeFirestoreError(error);
  }
}

Future<int> countTenantStaffWithRole(UserRole role) async {
  final users = await queryUsersRecordOnce();
  return users.where((user) => user.role == role).length;
}

Future<String?> removeTenantStaffRole(UserRole role) async {
  try {
    final current = await loadManagedStaffRolesWithFallback();
    if (!current.contains(role)) {
      return 'Role is not in the list.';
    }
    if (current.length <= 1) {
      return 'At least one staff role must remain.';
    }
    await saveTenantStaffRoles(
      current.where((value) => value != role).toList(),
    );
    return null;
  } catch (error) {
    return describeFirestoreError(error);
  }
}

List<UserRole> mergeStaffRoleOptions({
  required List<UserRole> tenantRoles,
  required List<UserRole> allowedRoles,
  UserRole? includeRole,
}) {
  final merged = normalizeStaffRoleList([
    ...tenantRoles.where(allowedRoles.contains),
    if (includeRole != null) includeRole,
  ]);
  if (merged.isNotEmpty) {
    return merged;
  }
  return normalizeStaffRoleList(allowedRoles);
}

String? tenantStaffRolesCompanyLabel() {
  final ref = tenantStaffRolesCompanyRef();
  if (ref == null) {
    return null;
  }
  return ref.id;
}

bool ensureSingleCompanyForStaffRoleWrite(BuildContext context) {
  if (!ensureActiveCompanyForWrite(context)) {
    return false;
  }
  if (TenantContext.instance.isViewingAllCompanies) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Select a company before managing staff roles.'),
      ),
    );
    return false;
  }
  return true;
}

bool canManageTenantStaffRoles(UserRole? role) =>
    canCreateStaffAccounts(role) || canManageRolePermissions(role);

class _ManageStaffRolesPanel extends StatefulWidget {
  const _ManageStaffRolesPanel({
    required this.companyLabel,
    required this.onSavingChanged,
  });

  final String? companyLabel;
  final ValueChanged<bool> onSavingChanged;

  @override
  State<_ManageStaffRolesPanel> createState() => _ManageStaffRolesPanelState();
}

class _ManageStaffRolesPanelState extends State<_ManageStaffRolesPanel> {
  List<UserRole> _roles = const [];
  UserRole? _selectedRole;
  bool _loading = true;
  String? _syncError;
  StreamSubscription<DocumentSnapshot>? _subscription;

  @override
  void initState() {
    super.initState();
    _reloadRoles();
    _subscribeToRoles();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  List<UserRole> get _availableToAdd {
    final viewerRole = currentViewerRole();
    final pool = isCompanyAdminRole(viewerRole)
        ? assignableStaffRoles
            .where((role) => role != UserRole.director)
            .toList(growable: false)
        : assignableStaffRoles;
    return pool.where((role) => !_roles.contains(role)).toList(growable: false);
  }

  void _subscribeToRoles() {
    final docRef = tenantStaffRolesDocRef();
    if (docRef == null) {
      return;
    }
    _subscription = docRef.snapshots().listen(
      (snapshot) {
        if (!mounted) {
          return;
        }
        setState(() {
          _roles = parseStaffRolesFromData(
            snapshot.data() as Map<String, dynamic>?,
          );
          _syncError = null;
          _loading = false;
          if (_selectedRole != null && !_availableToAdd.contains(_selectedRole)) {
            _selectedRole = _availableToAdd.isNotEmpty ? _availableToAdd.first : null;
          } else {
            _selectedRole ??=
                _availableToAdd.isNotEmpty ? _availableToAdd.first : null;
          }
        });
      },
      onError: (error) {
        if (!mounted) {
          return;
        }
        setState(() {
          if (_roles.isEmpty) {
            _syncError = describeFirestoreError(error);
          }
          _loading = false;
        });
      },
    );
  }

  Future<void> _reloadRoles() async {
    setState(() {
      _loading = true;
      _syncError = null;
    });
    try {
      final roles = await loadManagedStaffRolesWithFallback();
      if (!mounted) {
        return;
      }
      setState(() {
        _roles = roles;
        _loading = false;
        _selectedRole ??=
            _availableToAdd.isNotEmpty ? _availableToAdd.first : null;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _syncError = describeFirestoreError(error);
        _loading = false;
      });
    }
  }

  Future<void> _addRole() async {
    final role = _selectedRole;
    if (role == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select a role to add.')),
      );
      return;
    }
    widget.onSavingChanged(true);
    final error = await addTenantStaffRole(role);
    if (!mounted) {
      return;
    }
    if (error == null) {
      await _reloadRoles();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error)),
      );
    }
    widget.onSavingChanged(false);
  }

  Future<void> _deleteRole(UserRole role) async {
    final staffCount = await countTenantStaffWithRole(role);
    if (!mounted) {
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (confirmContext) {
        return AlertDialog(
          title: const Text('Remove role?'),
          content: Text(
            staffCount > 0
                ? '$staffCount staff member(s) still use ${userRoleLabel(role)}. '
                    'They keep this role, but it will be removed from Add Staff options.'
                : 'Remove ${userRoleLabel(role)} from the staff role list?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(confirmContext).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(confirmContext).pop(true),
              child: const Text('Remove'),
            ),
          ],
        );
      },
    );
    if (confirmed != true || !mounted) {
      return;
    }
    widget.onSavingChanged(true);
    final error = await removeTenantStaffRole(role);
    if (!mounted) {
      return;
    }
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error)),
      );
    } else {
      await _reloadRoles();
    }
    widget.onSavingChanged(false);
  }

  @override
  Widget build(BuildContext context) {
    final canEdit = !_loading;
    final availableToAdd = _availableToAdd;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.companyLabel != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              'Company: ${widget.companyLabel}',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
        Text(
          'Choose which staff roles appear when adding or editing users.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        if (_syncError != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              _syncError!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.error,
                  ),
            ),
          ),
        const SizedBox(height: 12),
        if (availableToAdd.isNotEmpty)
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<UserRole>(
                  value: _selectedRole,
                  decoration: const InputDecoration(
                    labelText: 'Add role',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    for (final role in availableToAdd)
                      DropdownMenuItem(
                        value: role,
                        child: Text(userRoleLabel(role)),
                      ),
                  ],
                  onChanged: canEdit
                      ? (value) => setState(() => _selectedRole = value)
                      : null,
                ),
              ),
              const SizedBox(width: 8),
              FilledButton(
                onPressed: canEdit ? _addRole : null,
                child: const Text('Add'),
              ),
            ],
          )
        else
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              'All available roles are already added.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        const SizedBox(height: 12),
        if (_loading)
          const SizedBox(
            height: 120,
            child: Center(child: CircularProgressIndicator()),
          )
        else
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _roles.length,
              itemBuilder: (context, index) {
                final role = _roles[index];
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(userRoleLabel(role)),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: canEdit ? () => _deleteRole(role) : null,
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}

Future<void> showManageStaffRolesDialog(BuildContext context) async {
  if (!canManageTenantStaffRoles(currentViewerRole())) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('You do not have permission to manage staff roles.'),
      ),
    );
    return;
  }
  if (!ensureSingleCompanyForStaffRoleWrite(context)) {
    return;
  }

  var saving = false;

  await showDialog<void>(
    context: context,
    builder: (dialogContext) {
      return StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('Manage Staff Roles'),
            content: SizedBox(
              width: double.maxFinite,
              height: 420,
              child: _ManageStaffRolesPanel(
                companyLabel: tenantStaffRolesCompanyLabel(),
                onSavingChanged: (value) {
                  setDialogState(() => saving = value);
                },
              ),
            ),
            actions: [
              TextButton(
                onPressed: saving ? null : () => Navigator.of(dialogContext).pop(),
                child: const Text('Close'),
              ),
            ],
          );
        },
      );
    },
  );
}
