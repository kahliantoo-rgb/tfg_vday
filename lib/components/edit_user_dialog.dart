import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '/auth/role_helpers.dart';
import '/backend/schema/enums/enums.dart';
import '/backend/schema/users_record.dart';
import '/backend/user_admin_service.dart';
import '/backend/user_list_helpers.dart';
import '/flutter_flow/flutter_flow_drop_down.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/form_field_controller.dart';

/// Shows a dialog to edit an existing staff profile.
Future<bool> showEditUserDialog(
  BuildContext context, {
  required UsersRecord user,
  required UserRole? viewerRole,
}) async {
  final theme = FlutterFlowTheme.of(context);
  final nameController = TextEditingController(text: user.name);
  final phoneController = TextEditingController(text: user.phoneNumber);
  final roleOptions = _roleOptionsForEdit(
    viewerRole: viewerRole,
    currentRole: user.role,
  );
  var selectedRole = user.role ?? UserRole.senior_florist;
  if (!roleOptions.contains(selectedRole)) {
    selectedRole = roleOptions.first;
  }
  final roleController = FormFieldController<String>(
    selectedRole.serialize(),
  );
  var saving = false;

  final saved = await showDialog<bool>(
    context: context,
    builder: (dialogContext) {
      return StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: Text(
              'Edit user',
              style: theme.titleLarge.override(
                font: GoogleFonts.interTight(fontWeight: FontWeight.w600),
              ),
            ),
            content: SizedBox(
              width: 420,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    enabled: !saving,
                    decoration: InputDecoration(
                      labelText: 'Name',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: phoneController,
                    enabled: !saving,
                    decoration: InputDecoration(
                      labelText: 'Phone',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  FlutterFlowDropDown<String>(
                    controller: roleController,
                    options: roleOptions.map((role) => role.serialize()).toList(),
                    optionLabels:
                        roleOptions.map(userListRoleLabel).toList(growable: false),
                    onChanged: saving
                        ? null
                        : (value) {
                            final role = deserializeEnum<UserRole>(value);
                            if (role != null) {
                              selectedRole = role;
                            }
                          },
                    width: double.infinity,
                    height: 52,
                    textStyle: theme.bodyMedium,
                    hintText: 'Role',
                    icon: Icon(Icons.keyboard_arrow_down_rounded,
                        color: theme.secondaryText),
                    fillColor: theme.secondaryBackground,
                    elevation: 0,
                    borderColor: theme.alternate,
                    borderWidth: 1,
                    borderRadius: 8,
                    margin: EdgeInsets.zero,
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      user.email,
                      style: theme.bodySmall.override(color: theme.secondaryText),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: saving ? null : () => Navigator.pop(dialogContext, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: saving
                    ? null
                    : () async {
                        final name = nameController.text.trim();
                        if (name.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Name is required.')),
                          );
                          return;
                        }
                        if (!isRoleAllowedForStaffEdit(
                              role: selectedRole,
                              editorRole: viewerRole,
                              targetCurrentRole: user.role,
                            ) &&
                            selectedRole != user.role) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('This role cannot be assigned.'),
                            ),
                          );
                          return;
                        }

                        setDialogState(() => saving = true);
                        try {
                          await updateUserProfile(
                            user: user,
                            name: name,
                            role: selectedRole,
                            phoneNumber: phoneController.text,
                          );
                          if (dialogContext.mounted) {
                            Navigator.pop(dialogContext, true);
                          }
                        } catch (e) {
                          setDialogState(() => saving = false);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Update failed: $e')),
                            );
                          }
                        }
                      },
                child: Text(saving ? 'Saving...' : 'Save'),
              ),
            ],
          );
        },
      );
    },
  );

  nameController.dispose();
  phoneController.dispose();
  return saved == true;
}

List<UserRole> _roleOptionsForEdit({
  required UserRole? viewerRole,
  required UserRole? currentRole,
}) {
  return roleEditOptionsForViewer(
    viewerRole: viewerRole,
    targetCurrentRole: currentRole,
  );
}
