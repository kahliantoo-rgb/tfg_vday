import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '/auth/firebase_auth/auth_util.dart';
import '/auth/role_helpers.dart';
import '/auth/viewer_role_helpers.dart';
import '/backend/backend.dart';
import '/backend/create_order_service.dart';
import '/backend/tenant_context.dart';
import '/backend/audit_log_helpers.dart';
import '/backend/audit_log_service.dart';
import '/backend/user_admin_service.dart';
import '/backend/user_list_helpers.dart';
import '/backend/user_query_helpers.dart';
import '/backend/staff_role_helpers.dart';
import '/components/edit_user_dialog.dart';
import '/components/home_nav_button.dart';
import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/index.dart';
import 'user_list_page_model.dart';
export 'user_list_page_model.dart';

class UserListPageWidget extends StatefulWidget {
  const UserListPageWidget({super.key});

  static String routeName = 'UserListPage';
  static String routePath = '/userListPage';

  @override
  State<UserListPageWidget> createState() => _UserListPageWidgetState();
}

class _UserListPageWidgetState extends State<UserListPageWidget> {
  late UserListPageModel _model;
  final scaffoldKey = GlobalKey<ScaffoldState>();

  List<UsersRecord> _users = [];
  bool _loading = true;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => UserListPageModel());
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (loggedIn) {
        final profile = await resolveCurrentUserProfile();
        await TenantContext.instance.initialize(profile);
      }
      await _loadUsers();
    });
  }

  Future<void> _loadUsers() async {
    final role = currentViewerRole();
    if (!canViewUserList(role)) {
      if (!mounted) {
        return;
      }
      setState(() {
        _loading = false;
        _users = const [];
        _error = '__no_permission__';
      });
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final all = await queryUsersRecordOnce();
      final filtered = filterUsersForAdminList(
        all,
        viewerRole: role,
        tenantCompanyId: TenantContext.instance.writeCompanyId,
        isViewingAllCompanies: TenantContext.instance.isViewingAllCompanies,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _users = filtered;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }
      setState(() {
        _loading = false;
        _error = '__load_failed__';
      });
    }
  }

  Future<void> _toggleUserActive(UsersRecord user, bool isActive) async {
    if (_saving) {
      return;
    }

    setState(() => _saving = true);
    try {
      await setUsersActiveStatus(users: [user], isActive: isActive);
      await auditLogStaffChange(
        action: isActive
            ? AuditLogAction.reactivateStaff
            : AuditLogAction.deactivateStaff,
        user: user,
        oldValue: {'isActive': !isActive},
        newValue: {'isActive': isActive},
      );
      if (!mounted) {
        return;
      }
      setState(() => _saving = false);
      await _loadUsers();
    } catch (e) {
      if (!mounted) {
        return;
      }
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            tr(context, 'admin.userList.updateFailed',
                params: {'error': '$e'}),
          ),
        ),
      );
    }
  }

  Future<void> _deleteUser(UsersRecord user) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(tr(context, 'admin.userList.deleteTitle')),
        content: Text(
          tr(context, 'admin.userList.deleteBody', params: {
            'name': userListDisplayName(user),
          }),
        ),
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
            child: Text(tr(context, 'common.delete')),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) {
      return;
    }

    setState(() => _saving = true);
    try {
      await deleteUserProfiles(users: [user]);
      await auditLogStaffChange(
        action: AuditLogAction.deleteStaffProfile,
        user: user,
        oldValue: staffAuditSnapshot(user),
        description: 'Staff profile deleted from Firestore',
      );
      if (!mounted) {
        return;
      }
      setState(() => _saving = false);
      await _loadUsers();
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(tr(context, 'admin.userList.deleted'))),
      );
    } catch (e) {
      if (!mounted) {
        return;
      }
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            tr(context, 'admin.userList.deleteFailed',
                params: {'error': describeFirestoreError(e)}),
          ),
          duration: const Duration(seconds: 8),
        ),
      );
    }
  }

  Future<void> _editUser(UsersRecord user) async {
    final viewerRole = currentViewerRole();
    if (!canEditStaffRoles(viewerRole)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(tr(context, 'admin.userList.cannotEditRoles')),
        ),
      );
      return;
    }
    final saved = await showEditUserDialog(
      context,
      user: user,
      viewerRole: currentViewerRole(),
    );
    if (saved && mounted) {
      await _loadUsers();
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(tr(context, 'admin.userList.updated'))),
      );
    }
  }

  @override
  void dispose() {
    _model.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final scopeLabel = TenantContext.instance.viewScopeLabel;

    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
        FocusManager.instance.primaryFocus?.unfocus();
      },
      child: Scaffold(
        key: scaffoldKey,
        backgroundColor: theme.primaryBackground,
        appBar: AppBar(
          backgroundColor: theme.secondaryBackground,
          automaticallyImplyLeading: false,
          title: Text(
            tr(context, 'admin.userList.title'),
            style: theme.headlineMedium.override(
              font: GoogleFonts.interTight(fontWeight: FontWeight.w600),
              letterSpacing: 0.0,
              fontWeight: FontWeight.w600,
            ),
          ),
          actions: [
            if (canCreateStaffAccounts(currentViewerRole()))
              Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(0, 0, 4, 0),
                child: FlutterFlowIconButton(
                  borderRadius: 20.0,
                  buttonSize: 40.0,
                  fillColor: theme.primary,
                  icon: const Icon(
                    Icons.person_add_outlined,
                    color: Colors.white,
                    size: 22.0,
                  ),
                  onPressed: () async {
                    await context.pushNamed(RegisterPageWidget.routeName);
                    if (!mounted) {
                      return;
                    }
                    await _loadUsers();
                  },
                ),
              ),
            if (canManageRolePermissions(currentViewerRole()))
              Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(0, 0, 4, 0),
                child: Tooltip(
                  message: tr(context, 'admin.userList.rolePermissionsTooltip'),
                  child: FlutterFlowIconButton(
                    borderRadius: 20.0,
                    buttonSize: 40.0,
                    icon: Icon(
                      Icons.admin_panel_settings_outlined,
                      color: theme.primaryText,
                      size: 22.0,
                    ),
                    onPressed: () =>
                        context.pushNamed(RolePermissionsPageWidget.routeName),
                  ),
                ),
              ),
            const HomeNavIconButton(),
            Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(8.0, 0.0, 16.0, 0.0),
              child: FlutterFlowIconButton(
                borderRadius: 20.0,
                buttonSize: 40.0,
                icon: Icon(
                  Icons.refresh,
                  color: theme.primaryText,
                  size: 22.0,
                ),
                onPressed: _loading || _saving ? null : _loadUsers,
              ),
            ),
          ],
          centerTitle: false,
          elevation: 0.0,
        ),
        body: SafeArea(
          top: true,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16.0, 12.0, 16.0, 8.0),
                child: Text(
                  scopeLabel,
                  style: theme.labelMedium.override(
                    color: theme.secondaryText,
                    font: GoogleFonts.inter(),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12.0,
                    vertical: 10.0,
                  ),
                  decoration: BoxDecoration(
                    color: theme.alternate.withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: Text(
                          tr(context, 'admin.userList.colName'),
                          style: theme.labelLarge.override(
                            font: GoogleFonts.interTight(
                              fontWeight: FontWeight.w700,
                            ),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          tr(context, 'admin.userList.colRole'),
                          style: theme.labelLarge.override(
                            font: GoogleFonts.interTight(
                              fontWeight: FontWeight.w700,
                            ),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 72.0,
                        child: Text(
                          tr(context, 'common.active'),
                          textAlign: TextAlign.center,
                          style: theme.labelLarge.override(
                            font: GoogleFonts.interTight(
                              fontWeight: FontWeight.w700,
                            ),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 88.0,
                        child: Text(
                          tr(context, 'admin.userList.colActions'),
                          textAlign: TextAlign.end,
                          style: theme.labelLarge.override(
                            font: GoogleFonts.interTight(
                              fontWeight: FontWeight.w700,
                            ),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8.0),
              Expanded(child: _buildBody(context)),
            ],
          ),
        ),
        floatingActionButton: canManageTenantStaffRoles(
          currentViewerRole(),
        )
            ? FloatingActionButton.extended(
                onPressed: () => showManageStaffRolesDialog(context),
                icon: const Icon(Icons.badge_outlined),
                label: Text(tr(context, 'admin.userList.addRole')),
              )
            : canCreateStaffAccounts(
                currentViewerRole(),
              )
                ? FloatingActionButton.extended(
                    onPressed: () async {
                      await context.pushNamed(RegisterPageWidget.routeName);
                      if (!mounted) {
                        return;
                      }
                      await _loadUsers();
                    },
                    icon: const Icon(Icons.person_add),
                    label: Text(tr(context, 'admin.userList.addStaff')),
                  )
                : null,
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);

    if (_loading) {
      return const Center(
        child: SizedBox(
          width: 44.0,
          height: 44.0,
          child: CircularProgressIndicator(strokeWidth: 2.5),
        ),
      );
    }

    if (_error != null) {
      final message = switch (_error) {
        '__no_permission__' => tr(context, 'admin.userList.noPermission'),
        '__load_failed__' => tr(context, 'admin.userList.loadFailed'),
        _ => _error!,
      };
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Text(
            message,
            textAlign: TextAlign.center,
            style: theme.bodyLarge.override(color: theme.error),
          ),
        ),
      );
    }

    if (_users.isEmpty) {
      return Center(
        child: Text(
          tr(context, 'admin.userList.noUsers'),
          style: theme.bodyLarge.override(color: theme.secondaryText),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadUsers,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16.0, 0.0, 16.0, 24.0),
        itemCount: _users.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8.0),
        itemBuilder: (context, index) {
          final user = _users[index];
          final canManage = canManageTargetUser(
            viewerRole: currentViewerRole(),
            target: user,
            viewerUid: currentUserUid,
          );
          final canEditRole = canEditStaffRoles(
            currentViewerRole(),
          );
          final isInactive = !userIsActive(user);

          return Opacity(
            opacity: isInactive ? 0.65 : 1.0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10.0),
              decoration: BoxDecoration(
                color: theme.secondaryBackground,
                borderRadius: BorderRadius.circular(10.0),
                border: Border.all(
                  color: theme.alternate,
                  width: 1.0,
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Text(
                      userListDisplayName(user),
                      style: theme.bodyLarge.override(
                        font: GoogleFonts.inter(fontWeight: FontWeight.w500),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      userListRoleLabel(user.role),
                      style: theme.bodyMedium.override(
                        color: theme.secondaryText,
                        font: GoogleFonts.inter(),
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 72.0,
                    child: Switch(
                      value: userIsActive(user),
                      onChanged: _saving || !canManage
                          ? null
                          : (value) => _toggleUserActive(user, value),
                    ),
                  ),
                  SizedBox(
                    width: 88.0,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (canEditRole)
                          IconButton(
                            tooltip: tr(context, 'admin.userList.editUser'),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(
                              minWidth: 36,
                              minHeight: 36,
                            ),
                            icon: Icon(
                              Icons.edit_outlined,
                              color: theme.primary,
                              size: 22,
                            ),
                            onPressed: _saving
                                ? null
                                : () => _editUser(user),
                          ),
                        if (canManage)
                          IconButton(
                            tooltip: tr(context, 'admin.userList.deleteUser'),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(
                              minWidth: 36,
                              minHeight: 36,
                            ),
                            icon: Icon(
                              Icons.delete_outline,
                              color: theme.error,
                              size: 22,
                            ),
                            onPressed: _saving
                                ? null
                                : () => _deleteUser(user),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
