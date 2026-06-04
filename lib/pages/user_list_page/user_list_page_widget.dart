import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '/auth/firebase_auth/auth_util.dart';
import '/auth/role_helpers.dart';
import '/backend/backend.dart';
import '/backend/tenant_context.dart';
import '/backend/user_admin_service.dart';
import '/backend/user_list_helpers.dart';
import '/backend/user_query_helpers.dart';
import '/components/home_nav_button.dart';
import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
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
  final Set<String> _selectedIds = {};
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
        _selectedIds.removeWhere(
          (id) => !filtered.any((user) => user.reference.id == id),
        );
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

  List<UsersRecord> get _selectedUsers => manageableUsersFromSelection(
        users: _users,
        selectedIds: _selectedIds,
        viewerRole: AppStateNotifier.instance.userRole,
        viewerUid: currentUserUid,
      );

  bool? _selectAllValue() {
    final manageable = _users
        .where(
          (user) => canManageTargetUser(
            viewerRole: AppStateNotifier.instance.userRole,
            target: user,
            viewerUid: currentUserUid,
          ),
        )
        .toList();
    if (manageable.isEmpty) {
      return false;
    }
    final selectedCount =
        manageable.where((u) => _selectedIds.contains(u.reference.id)).length;
    if (selectedCount == 0) {
      return false;
    }
    if (selectedCount == manageable.length) {
      return true;
    }
    return null;
  }

  void _toggleSelectAll(bool? value) {
    final manageable = _users.where(
      (user) => canManageTargetUser(
        viewerRole: AppStateNotifier.instance.userRole,
        target: user,
        viewerUid: currentUserUid,
      ),
    );
    setState(() {
      if (value == true) {
        _selectedIds.addAll(manageable.map((u) => u.reference.id));
      } else {
        for (final user in manageable) {
          _selectedIds.remove(user.reference.id);
        }
      }
    });
  }

  Future<void> _setActiveStatus(bool isActive) async {
    final selected = _selectedUsers;
    if (selected.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select at least one user.')),
      );
      return;
    }

    final actionLabel = isActive ? 'activate' : 'deactivate';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(isActive ? 'Activate users?' : 'Set users inactive?'),
        content: Text(
          '${isActive ? 'Activate' : 'Deactivate'} ${selected.length} user(s)?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(isActive ? 'Activate' : 'Set Inactive'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) {
      return;
    }

    setState(() => _saving = true);
    try {
      final count = await setUsersActiveStatus(
        users: selected,
        isActive: isActive,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _selectedIds.clear();
        _saving = false;
      });
      await _loadUsers();
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Updated $count user(s) to $actionLabel.')),
      );
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

  Future<void> _deleteSelected() async {
    final selected = _selectedUsers;
    if (selected.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select at least one user.')),
      );
      return;
    }

    final previewNames = selected
        .take(5)
        .map(userListDisplayName)
        .join('\n');
    final extra = selected.length > 5 ? '\n…' : '';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete selected users?'),
        content: Text(
          'Delete ${selected.length} user profile(s)?\n\n'
          '$previewNames$extra\n\n'
          'This removes Firestore profiles only. Firebase Auth accounts remain.',
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
      final count = await deleteUserProfiles(users: selected);
      if (!mounted) {
        return;
      }
      setState(() {
        _selectedIds.clear();
        _saving = false;
      });
      await _loadUsers();
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Deleted $count user profile(s).')),
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
                      SizedBox(
                        width: 40.0,
                        child: Checkbox(
                          tristate: true,
                          value: _selectAllValue(),
                          onChanged: _saving ? null : _toggleSelectAll,
                          activeColor: theme.primary,
                        ),
                      ),
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
                      Expanded(
                        flex: 2,
                        child: Text(
                          'Status',
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
              if (canViewUserList(AppStateNotifier.instance.userRole))
                _buildActionBar(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionBar(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final hasSelection = _selectedUsers.isNotEmpty;

    return Container(
      padding: const EdgeInsets.fromLTRB(16.0, 12.0, 16.0, 16.0),
      decoration: BoxDecoration(
        color: theme.secondaryBackground,
        border: Border(top: BorderSide(color: theme.alternate)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (hasSelection)
            Padding(
              padding: const EdgeInsets.only(bottom: 10.0),
              child: Text(
                '${_selectedUsers.length} selected',
                style: theme.labelMedium.override(color: theme.secondaryText),
              ),
            ),
          Row(
            children: [
              Expanded(
                child: FFButtonWidget(
                  onPressed: _saving || !hasSelection
                      ? null
                      : () => _setActiveStatus(false),
                  text: _saving ? 'Saving...' : 'Set Inactive',
                  icon: const Icon(Icons.person_off_outlined, size: 18.0),
                  options: FFButtonOptions(
                    height: 44.0,
                    color: theme.secondaryBackground,
                    textStyle: theme.titleSmall.override(
                      font: GoogleFonts.interTight(fontWeight: FontWeight.w600),
                      color: theme.primaryText,
                    ),
                    borderSide: BorderSide(color: theme.alternate),
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                ),
              ),
              const SizedBox(width: 8.0),
              Expanded(
                child: FFButtonWidget(
                  onPressed: _saving || !hasSelection
                      ? null
                      : () => _setActiveStatus(true),
                  text: _saving ? 'Saving...' : 'Activate',
                  icon: const Icon(Icons.person_outline, size: 18.0),
                  options: FFButtonOptions(
                    height: 44.0,
                    color: theme.secondaryBackground,
                    textStyle: theme.titleSmall.override(
                      font: GoogleFonts.interTight(fontWeight: FontWeight.w600),
                      color: theme.primaryText,
                    ),
                    borderSide: BorderSide(color: theme.alternate),
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                ),
              ),
              const SizedBox(width: 8.0),
              Expanded(
                child: FFButtonWidget(
                  onPressed: _saving || !hasSelection ? null : _deleteSelected,
                  text: _saving ? 'Deleting...' : 'Delete',
                  icon: const Icon(Icons.delete_outline, size: 18.0),
                  options: FFButtonOptions(
                    height: 44.0,
                    color: theme.error,
                    textStyle: theme.titleSmall.override(
                      font: GoogleFonts.interTight(fontWeight: FontWeight.w600),
                      color: Colors.white,
                    ),
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                ),
              ),
            ],
          ),
        ],
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
          final isSelected = _selectedIds.contains(user.reference.id);
          final isInactive = !userIsActive(user);

          return Opacity(
            opacity: isInactive ? 0.65 : 1.0,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10.0),
              decoration: BoxDecoration(
                color: theme.secondaryBackground,
                borderRadius: BorderRadius.circular(10.0),
                border: Border.all(
                  color: isSelected ? theme.primary : theme.alternate,
                  width: isSelected ? 1.5 : 1.0,
                ),
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: 40.0,
                    child: Checkbox(
                      value: isSelected,
                      onChanged: _saving || !canManage
                          ? null
                          : (value) {
                              setState(() {
                                if (value == true) {
                                  _selectedIds.add(user.reference.id);
                                } else {
                                  _selectedIds.remove(user.reference.id);
                                }
                              });
                            },
                      activeColor: theme.primary,
                    ),
                  ),
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
                  Expanded(
                    flex: 2,
                    child: Text(
                      userListStatusLabel(user),
                      style: theme.bodyMedium.override(
                        color: isInactive ? theme.error : theme.secondaryText,
                        font: GoogleFonts.inter(
                          fontWeight:
                              isInactive ? FontWeight.w600 : FontWeight.normal,
                        ),
                        fontWeight:
                            isInactive ? FontWeight.w600 : FontWeight.normal,
                      ),
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
