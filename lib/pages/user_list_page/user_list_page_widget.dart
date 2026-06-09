import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '/auth/firebase_auth/auth_util.dart';
import '/auth/role_helpers.dart';
import '/backend/backend.dart';
import '/backend/tenant_context.dart';
import '/backend/audit_log_helpers.dart';
import '/backend/audit_log_service.dart';
import '/backend/user_admin_service.dart';
import '/backend/user_list_helpers.dart';
import '/backend/user_query_helpers.dart';
import '/components/edit_user_dialog.dart';
import '/components/home_nav_button.dart';
import '/index.dart';
import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/nav/nav.dart';
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
    final role = AppStateNotifier.instance.userRole;
    if (!canViewUserList(role)) {
      if (!mounted) {
        return;
      }
      setState(() {
        _loading = false;
        _users = const [];
        _error = 'You do not have permission to view users.';
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
        _error = 'Failed to load users.';
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
        SnackBar(content: Text('Update failed: $e')),
      );
    }
  }

  Future<void> _deleteUser(UsersRecord user) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete user?'),
        content: Text(
          'Delete profile for ${userListDisplayName(user)}?\n\n'
          'This removes the Firestore profile only. '
          'The Firebase Auth account remains.',
        ),
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
            child: const Text('Delete'),
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
        const SnackBar(content: Text('User deleted.')),
      );
    } catch (e) {
      if (!mounted) {
        return;
      }
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Delete failed: $e')),
      );
    }
  }

  Future<void> _editUser(UsersRecord user) async {
    final saved = await showEditUserDialog(
      context,
      user: user,
      viewerRole: AppStateNotifier.instance.userRole,
    );
    if (saved && mounted) {
      await _loadUsers();
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User updated.')),
      );
    }
  }

  Future<void> _showUserActionMenu(UsersRecord user) async {
    final theme = FlutterFlowTheme.of(context);
    final action = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: theme.secondaryBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.edit_outlined),
                title: const Text('Edit user'),
                onTap: () => Navigator.pop(sheetContext, 'edit'),
              ),
              ListTile(
                leading: Icon(Icons.delete_outline, color: theme.error),
                title: Text(
                  'Delete user',
                  style: TextStyle(color: theme.error),
                ),
                onTap: () => Navigator.pop(sheetContext, 'delete'),
              ),
              ListTile(
                leading: const Icon(Icons.dashboard_outlined),
                title: const Text('Exit'),
                onTap: () => Navigator.pop(sheetContext, 'exit'),
              ),
            ],
          ),
        );
      },
    );

    if (!mounted || action == null) {
      return;
    }

    switch (action) {
      case 'edit':
        await _editUser(user);
      case 'delete':
        await _deleteUser(user);
      case 'exit':
        context.goNamed(HomePageWidget.routeName);
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
            'User List',
            style: theme.headlineMedium.override(
              font: GoogleFonts.interTight(fontWeight: FontWeight.w600),
              letterSpacing: 0.0,
              fontWeight: FontWeight.w600,
            ),
          ),
          actions: [
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
                          'Name',
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
                          'Role',
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
                          'Active',
                          textAlign: TextAlign.center,
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
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Text(
            _error!,
            textAlign: TextAlign.center,
            style: theme.bodyLarge.override(color: theme.error),
          ),
        ),
      );
    }

    if (_users.isEmpty) {
      return Center(
        child: Text(
          'No users found.',
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
            viewerRole: AppStateNotifier.instance.userRole,
            target: user,
            viewerUid: currentUserUid,
          );
          final isInactive = !userIsActive(user);

          return GestureDetector(
            onLongPress:
                canManage ? () => _showUserActionMenu(user) : null,
            onSecondaryTap:
                canManage ? () => _showUserActionMenu(user) : null,
            child: Opacity(
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
                ],
              ),
            ),
            ),
          );
        },
      ),
    );
  }
}
