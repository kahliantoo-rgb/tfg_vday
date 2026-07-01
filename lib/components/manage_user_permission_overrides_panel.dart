import 'package:flutter/material.dart';

import '/auth/app_permissions.dart';
import '/auth/role_helpers.dart';
import '/backend/role_permissions_helpers.dart';
import '/backend/schema/enums/enums.dart';
import '/backend/user_permissions_helpers.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';

class ManageUserPermissionOverridesPanel extends StatefulWidget {
  const ManageUserPermissionOverridesPanel({
    super.key,
    required this.role,
    required this.initialOverrides,
    required this.onChanged,
    this.enabled = true,
  });

  final UserRole role;
  final UserPermissionOverrides initialOverrides;
  final ValueChanged<UserPermissionOverrides> onChanged;
  final bool enabled;

  @override
  State<ManageUserPermissionOverridesPanel> createState() =>
      _ManageUserPermissionOverridesPanelState();
}

class _ManageUserPermissionOverridesPanelState
    extends State<ManageUserPermissionOverridesPanel> {
  late UserPermissionOverrides _draft;
  RolePermissionOverrides _roleOverrides = {};

  @override
  void initState() {
    super.initState();
    _draft = Map<String, bool>.from(widget.initialOverrides);
    _loadRoleOverrides();
  }

  @override
  void didUpdateWidget(covariant ManageUserPermissionOverridesPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.role != widget.role ||
        oldWidget.initialOverrides != widget.initialOverrides) {
      _draft = Map<String, bool>.from(widget.initialOverrides);
    }
  }

  Future<void> _loadRoleOverrides() async {
    try {
      final overrides = await loadTenantRolePermissionOverrides();
      if (!mounted) {
        return;
      }
      setState(() => _roleOverrides = overrides);
    } catch (_) {}
  }

  bool _isEnabled(AppPermission permission) {
    return effectivePermissionForUser(
      role: widget.role,
      permission: permission,
      roleOverrides: _roleOverrides,
      userOverrides: _draft,
    );
  }

  bool _usesRoleDefault(AppPermission permission) {
    return !_draft.containsKey(appPermissionKey(permission));
  }

  void _setPermission(AppPermission permission, bool enabled) {
    final key = appPermissionKey(permission);
    final baseline = effectivePermission(
      role: widget.role,
      permission: permission,
      overrides: _roleOverrides,
    );
    setState(() {
      if (enabled == baseline) {
        _draft.remove(key);
      } else {
        _draft[key] = enabled;
      }
      widget.onChanged(Map<String, bool>.from(_draft));
    });
  }

  void _resetAll() {
    setState(() {
      _draft.clear();
      widget.onChanged({});
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          tr(context, 'admin.userPermissions.intro'),
          style: theme.bodySmall.override(color: theme.secondaryText),
        ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: widget.enabled ? _resetAll : null,
            child: Text(tr(context, 'admin.userPermissions.resetDefaults')),
          ),
        ),
        for (final permission in editablePermissionKeys())
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(appPermissionLabel(permission)),
            subtitle: _usesRoleDefault(permission)
                ? Text(
                    tr(context, 'admin.userPermissions.usesRoleDefault'),
                    style: theme.bodySmall.override(color: theme.secondaryText),
                  )
                : Text(
                    tr(context, 'admin.userPermissions.customOverride'),
                    style: theme.bodySmall.override(color: theme.warning),
                  ),
            value: _isEnabled(permission),
            onChanged: widget.enabled
                ? (value) => _setPermission(permission, value)
                : null,
          ),
      ],
    );
  }
}
