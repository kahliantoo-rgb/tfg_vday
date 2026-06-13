import 'package:flutter/material.dart';

import '/auth/app_permissions.dart';
import '/auth/permission_service.dart';
import '/auth/role_helpers.dart';
import '/backend/role_permissions_helpers.dart';
import '/backend/schema/enums/enums.dart';
import '/backend/tenant_query_helpers.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/auth/viewer_role_helpers.dart';

class ManageRolePermissionsPanel extends StatefulWidget {
  const ManageRolePermissionsPanel({
    super.key,
    required this.onSavingChanged,
  });

  final ValueChanged<bool> onSavingChanged;

  @override
  State<ManageRolePermissionsPanel> createState() =>
      _ManageRolePermissionsPanelState();
}

class _ManageRolePermissionsPanelState extends State<ManageRolePermissionsPanel> {
  RolePermissionOverrides _draft = {};
  bool _loading = true;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final overrides = await loadTenantRolePermissionOverrides();
      if (!mounted) {
        return;
      }
      setState(() {
        _draft = _cloneOverrides(overrides);
        _loading = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _error = error.toString();
        _loading = false;
      });
    }
  }

  RolePermissionOverrides _cloneOverrides(RolePermissionOverrides source) {
    return {
      for (final entry in source.entries)
        entry.key: Map<String, bool>.from(entry.value),
    };
  }

  bool _isEnabled(UserRole role, AppPermission permission) {
    final roleKey = rolePermissionKey(role);
    final override = _draft[roleKey]?[appPermissionKey(permission)];
    if (override != null) {
      return override;
    }
    return defaultPermissionsForRole(role).contains(permission);
  }

  void _setPermission(UserRole role, AppPermission permission, bool enabled) {
    if ((role == UserRole.director || role == UserRole.admin) &&
        permission == AppPermission.manageRolePermissions &&
        !enabled) {
      return;
    }
    setState(() {
      final roleKey = rolePermissionKey(role);
      final defaults = defaultPermissionsForRole(role);
      final defaultEnabled = defaults.contains(permission);
      final roleMap = Map<String, bool>.from(_draft[roleKey] ?? {});
      if (enabled == defaultEnabled) {
        roleMap.remove(appPermissionKey(permission));
      } else {
        roleMap[appPermissionKey(permission)] = enabled;
      }
      if (roleMap.isEmpty) {
        _draft.remove(roleKey);
      } else {
        _draft[roleKey] = roleMap;
      }
    });
  }

  Future<void> _resetRole(UserRole role) {
    setState(() {
      _draft.remove(rolePermissionKey(role));
    });
    return Future.value();
  }

  Future<void> save() async {
    if (!ensureActiveCompanyForWrite(context)) {
      return;
    }
    setState(() => _saving = true);
    widget.onSavingChanged(true);
    try {
      await saveTenantRolePermissionOverrides(_draft);
      await PermissionService.instance.loadForActiveCompany();
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Role permissions saved. Staff with that role will pick up changes shortly.')),
      );
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Save failed: $error')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
      widget.onSavingChanged(false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);

    if (_loading) {
      return const SizedBox(
        height: 160,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return SizedBox(
        height: 160,
        child: Center(child: Text(_error!)),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Turn permissions on or off for each role. '
          'Example: while Admin is on leave, open Florist and enable '
          '"Print cash invoice", "View customers", or "Edit customers". '
          'Turn them off again when cover duty ends. '
          'Changes apply to all staff with that role after Save.',
          style: theme.bodyMedium.override(color: theme.secondaryText),
        ),
        const SizedBox(height: 8),
        Text(
          'Super Admin always has full access.',
          style: theme.bodySmall.override(color: theme.secondaryText),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: ListView(
            children: [
              for (final role in configurableStaffRoles)
                _roleCard(theme, role),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          height: 44,
          child: FilledButton(
            onPressed: _saving ? null : save,
            child: _saving
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text('Save permissions'),
          ),
        ),
      ],
    );
  }

  Widget _roleCard(FlutterFlowTheme theme, UserRole role) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        title: Text(
          userRoleLabel(role),
          style: theme.titleMedium.override(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          'Defaults apply unless overridden below.',
          style: theme.bodySmall.override(color: theme.secondaryText),
        ),
        children: [
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: _saving ? null : () => _resetRole(role),
              child: const Text('Reset to defaults'),
            ),
          ),
          for (final permission in editablePermissionKeys())
            SwitchListTile(
              title: Text(appPermissionLabel(permission)),
              value: _isEnabled(role, permission),
              onChanged: _saving
                  ? null
                  : (value) => _setPermission(role, permission, value),
            ),
        ],
      ),
    );
  }
}

Future<void> showManageRolePermissionsDialog(BuildContext context) async {
  if (!canManageRolePermissions(currentViewerRole())) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Only Admin, Director, or Super Admin can manage role permissions.'),
      ),
    );
    return;
  }
  if (!ensureActiveCompanyForWrite(context)) {
    return;
  }

  var saving = false;

  await showDialog<void>(
    context: context,
    builder: (dialogContext) {
      return StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('Manage Roles'),
            content: SizedBox(
              width: double.maxFinite,
              height: 520,
              child: ManageRolePermissionsPanel(
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
