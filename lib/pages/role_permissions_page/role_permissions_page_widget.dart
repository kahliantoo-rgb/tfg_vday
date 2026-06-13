import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '/auth/role_helpers.dart';
import '/auth/viewer_role_helpers.dart';
import '/components/home_nav_button.dart';
import '/components/manage_role_permissions_panel.dart';
import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';

class RolePermissionsPageWidget extends StatefulWidget {
  const RolePermissionsPageWidget({super.key});

  static String routeName = 'RolePermissionsPage';
  static String routePath = '/rolePermissions';

  @override
  State<RolePermissionsPageWidget> createState() =>
      _RolePermissionsPageWidgetState();
}

class _RolePermissionsPageWidgetState extends State<RolePermissionsPageWidget> {
  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final canManage = canManageRolePermissions(currentViewerRole());

    return Scaffold(
      backgroundColor: theme.primaryBackground,
      appBar: AppBar(
        backgroundColor: theme.primary,
        automaticallyImplyLeading: false,
        leading: FlutterFlowIconButton(
          borderRadius: 30,
          buttonSize: 60,
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 30),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Role Permissions',
          style: theme.headlineMedium.override(
            font: GoogleFonts.interTight(fontWeight: FontWeight.w600),
            color: Colors.white,
            fontSize: 22,
          ),
        ),
        actions: const [HomeNavIconButton()],
        centerTitle: true,
      ),
      body: !canManage
          ? const Center(
              child: Text(
                'Only Admin, Director, or Super Admin can manage role permissions.',
              ),
            )
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: ManageRolePermissionsPanel(
                  onSavingChanged: (_) {},
                ),
              ),
            ),
    );
  }
}
