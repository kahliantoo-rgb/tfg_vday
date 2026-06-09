import '/auth/role_helpers.dart';
import '/auth/firebase_auth/auth_util.dart';
import '/backend/backend.dart';
import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/backend/create_order_service.dart';
import '/backend/dashboard_order_stats_helpers.dart';
import '/backend/tenant_context.dart';
import '/backend/user_query_helpers.dart';
import '/backend/whatsapp_order_import_service.dart';
import '/components/whatsapp_order_paste_button.dart';
import '/flutter_flow/nav/nav.dart';
import '/index.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'sales_dash_board_model.dart';
export 'sales_dash_board_model.dart';

/// Create a FlutterFlow Page named "SalesDashboard" for an internal POS and
/// order management system.
///
/// Layout:
/// - AppBar with title "Sales Dashboard"
/// - Vertical scroll layout
/// - Clean admin-style UI
///
/// Dashboard Cards:
/// 1) Today Orders
///    - Count orders created today
///    - Firestore: orders
///    - Filter by created_time = today
///
/// 2) Pending Orders
///    - Count orders where status = "Pending"
///
/// 3) Completed Orders
///    - Count orders where status = "Completed"
///
/// Sales Summary:
/// - Today Sales Total
///   - Sum orders.total for today
/// - This Month Sales Total
///   - Sum orders.total for current month
///
/// Actions:
/// - Primary button: "+ Create Order"
///   - On tap, show Bottom Sheet:
///     - POS / Cashier Order
///     - Delivery Order
///   - Navigate to ProductSelectionPage
///   - Pass parameter: orderType
///
/// Navigation:
/// - Button: "All Orders"
///   - Navigate to OrderListPage
///
/// Requirements:
/// - Use Firebase Firestore
/// - Use FlutterFlow native widgets and actions
/// - Mobile-first responsive layout
class SalesDashBoardWidget extends StatefulWidget {
  const SalesDashBoardWidget({
    super.key,
    this.orderRef,
  });

  final DocumentReference? orderRef;

  static String routeName = 'SalesDashBoard';
  static String routePath = '/salesDashBoard';

  @override
  State<SalesDashBoardWidget> createState() => _SalesDashBoardWidgetState();
}

class _SalesDashBoardWidgetState extends State<SalesDashBoardWidget> {
  late SalesDashBoardModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();
  bool _creatingOrder = false;

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => SalesDashBoardModel());

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (loggedIn) {
        final profile = await resolveCurrentUserProfile();
        await TenantContext.instance.initialize(profile);
        AppStateNotifier.instance.syncUserRole(profile?.role);
      }
      safeSetState(() {});
    });
  }

  @override
  void dispose() {
    _model.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);

    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
        FocusManager.instance.primaryFocus?.unfocus();
      },
      child: Scaffold(
        key: scaffoldKey,
        backgroundColor: theme.primaryBackground,
        appBar: AppBar(
          backgroundColor: theme.primary,
          automaticallyImplyLeading: false,
          leading: FlutterFlowIconButton(
            borderColor: Colors.transparent,
            borderRadius: 30.0,
            borderWidth: 1.0,
            buttonSize: 60.0,
            icon: const Icon(
              Icons.arrow_back_rounded,
              color: Colors.white,
              size: 30.0,
            ),
            onPressed: () => context.pop(),
          ),
          title: Text(
            'Sales Dashboard',
            style: theme.headlineMedium.override(
              font: GoogleFonts.interTight(fontWeight: FontWeight.w600),
              color: Colors.white,
              fontSize: 22.0,
            ),
          ),
          actions: [
            ListenableBuilder(
              listenable: TenantContext.instance,
              builder: (context, _) {
                if (!isSuperAdminRole(AppStateNotifier.instance.userRole)) {
                  return const SizedBox.shrink();
                }
                return Padding(
                  padding: const EdgeInsetsDirectional.only(end: 8.0),
                  child: TextButton.icon(
                    onPressed: () {
                      context.pushNamed(CompanySelectionPageWidget.routeName);
                    },
                    icon: Icon(
                      TenantContext.instance.isViewingAllCompanies
                          ? Icons.business
                          : Icons.filter_alt,
                      color: Colors.white,
                      size: 18.0,
                    ),
                    label: Text(
                      TenantContext.instance.viewScopeLabel,
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                    ),
                  ),
                );
              },
            ),
          ],
          centerTitle: true,
          elevation: 2.0,
        ),
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final wide = constraints.maxWidth >= 720;
              final statColumns = wide ? 4 : 2;
              final statAspectRatio = wide ? 1.55 : 1.35;

              return SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildOverviewHeader(context),
                    const SizedBox(height: 16),
                    FutureBuilder<DashboardOrderStats>(
                      future: loadDashboardOrderStats(),
                      builder: (context, snapshot) {
                        final stats = snapshot.data;
                        return GridView.count(
                      crossAxisCount: statColumns,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: statAspectRatio,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      children: [
                        _buildStatCard(
                          context,
                          icon: Icons.local_shipping_outlined,
                          iconColor: theme.primary,
                          label: 'Today Delivery Orders',
                          value: _statValue(
                            context,
                            stats?.todayDeliveryOrders,
                            loading: !snapshot.hasData &&
                                snapshot.connectionState ==
                                    ConnectionState.waiting,
                          ),
                          onTap: () => openDashboardFilteredOrderList(
                            context,
                            DashboardOrderListFilter.todayDeliveryOrders,
                          ),
                        ),
                        _buildStatCard(
                          context,
                          icon: Icons.pending_actions,
                          iconColor: theme.warning,
                          label: 'Today Pending Orders',
                          value: _statValue(
                            context,
                            stats?.todayPendingOrders,
                            loading: !snapshot.hasData &&
                                snapshot.connectionState ==
                                    ConnectionState.waiting,
                          ),
                          onTap: () => openDashboardFilteredOrderList(
                            context,
                            DashboardOrderListFilter.todayPendingOrders,
                          ),
                        ),
                        _buildStatCard(
                          context,
                          icon: Icons.check_circle,
                          iconColor: theme.success,
                          label: 'Today Complete Orders',
                          value: _statValue(
                            context,
                            stats?.todayCompletedOrders,
                            loading: !snapshot.hasData &&
                                snapshot.connectionState ==
                                    ConnectionState.waiting,
                          ),
                          onTap: () => openDashboardFilteredOrderList(
                            context,
                            DashboardOrderListFilter.todayCompletedOrders,
                          ),
                        ),
                        _buildStatCard(
                          context,
                          icon: Icons.analytics,
                          iconColor: theme.tertiary,
                          label: 'Today Total Order',
                          value: _statValue(
                            context,
                            stats?.todayTotalOrders,
                            loading: !snapshot.hasData &&
                                snapshot.connectionState ==
                                    ConnectionState.waiting,
                          ),
                          onTap: () => openDashboardFilteredOrderList(
                            context,
                            DashboardOrderListFilter.todayTotalOrders,
                          ),
                        ),
                        _buildStatCard(
                          context,
                          icon: Icons.local_shipping,
                          iconColor: theme.secondary,
                          label: 'Tomorrow Delivery Orders',
                          value: _statValue(
                            context,
                            stats?.tomorrowDeliveryOrders,
                            loading: !snapshot.hasData &&
                                snapshot.connectionState ==
                                    ConnectionState.waiting,
                          ),
                          onTap: () => openDashboardFilteredOrderList(
                            context,
                            DashboardOrderListFilter.tomorrowDeliveryOrders,
                          ),
                        ),
                        _buildStatCard(
                          context,
                          icon: Icons.event_note,
                          iconColor: theme.secondaryText,
                          label: 'Tomorrow Total Order',
                          value: _statValue(
                            context,
                            stats?.tomorrowTotalOrders,
                            loading: !snapshot.hasData &&
                                snapshot.connectionState ==
                                    ConnectionState.waiting,
                          ),
                          onTap: () => openDashboardFilteredOrderList(
                            context,
                            DashboardOrderListFilter.tomorrowTotalOrders,
                          ),
                        ),
                      ],
                        );
                      },
                    ),
                    const SizedBox(height: 28),
                    Text(
                      'Quick Actions',
                      style: theme.titleLarge.override(
                        font: GoogleFonts.interTight(fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(height: 12),
                    FFButtonWidget(
                      onPressed: _creatingOrder
                          ? null
                          : () async {
                              setState(() => _creatingOrder = true);
                              try {
                                await createDraftOrderAndOpenProductSelection(
                                  context,
                                );
                              } catch (e) {
                                if (!context.mounted) {
                                  return;
                                }
                                final message = describeFirestoreError(e);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(message),
                                    backgroundColor: theme.error,
                                    duration: const Duration(seconds: 8),
                                  ),
                                );
                                if (isSuperAdminRole(
                                        AppStateNotifier.instance.userRole) &&
                                    (message.contains('company') ||
                                        message.contains('Company') ||
                                        message.contains('users/'))) {
                                  context.pushNamed(
                                    CompanySelectionPageWidget.routeName,
                                  );
                                }
                              } finally {
                                if (mounted) {
                                  setState(() => _creatingOrder = false);
                                }
                              }
                            },
                      text: _creatingOrder ? 'Creating...' : '+ Create Order',
                      icon: const Icon(Icons.add_rounded, size: 22.0),
                      options: FFButtonOptions(
                        width: double.infinity,
                        height: 52.0,
                        color: theme.primary,
                        iconColor: Colors.white,
                        textStyle: theme.titleMedium.override(
                          font: GoogleFonts.interTight(fontWeight: FontWeight.w600),
                          color: Colors.white,
                        ),
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                    ),
                    if (isWhatsAppOrderImportEnabled) ...[
                      const SizedBox(height: 10),
                      WhatsAppOrderPasteButton(
                        fullWidth: true,
                        label: 'Paste from WhatsApp',
                        onDashboardImport: () =>
                            runWhatsAppOrderImportFromDashboard(context),
                      ),
                    ],
                    const SizedBox(height: 12),
                    _buildActionsMenu(context),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildOverviewHeader(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    return Text(
      'Dashboard Overview',
      style: theme.headlineMedium.override(
        font: GoogleFonts.interTight(fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String label,
    required Widget value,
    VoidCallback? onTap,
  }) {
    final theme = FlutterFlowTheme.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
      decoration: BoxDecoration(
        color: theme.secondaryBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.alternate),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: iconColor, size: 26),
          value,
          Text(
            label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.labelMedium.override(color: theme.secondaryText),
          ),
        ],
      ),
        ),
      ),
    );
  }

  Widget _statValue(
    BuildContext context,
    int? count, {
    bool loading = false,
  }) {
    final theme = FlutterFlowTheme.of(context);
    if (loading || count == null) {
      return const SizedBox(
        height: 28,
        width: 28,
        child: CircularProgressIndicator(strokeWidth: 2.5),
      );
    }
    return Text(
      count.toString(),
      style: theme.headlineSmall.override(
        font: GoogleFonts.interTight(fontWeight: FontWeight.bold),
        fontSize: 26.0,
      ),
    );
  }

  Widget _buildActionsMenu(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final role = AppStateNotifier.instance.userRole;
    final actions = <_DashboardMenuAction>[
      _DashboardMenuAction(
        label: 'All Orders',
        icon: Icons.list_alt,
        onPressed: () => context.pushNamed(OrderlistWidget.routeName),
      ),
      if (canViewAuditLog(role))
        _DashboardMenuAction(
          label: 'Audit Log',
          icon: Icons.history,
          onPressed: () => context.pushNamed(AuditLogPageWidget.routeName),
        ),
      if (canEditCompanyProfile(role))
        _DashboardMenuAction(
          label: 'Company Profile',
          icon: Icons.business,
          onPressed: () =>
              context.pushNamed(CompanySettingPageWidget.routeName),
        ),
      _DashboardMenuAction(
        label: 'Create Customer',
        icon: Icons.person_add_alt_1,
        onPressed: () =>
            context.pushNamed(CustomerCreateFormWidget.routeName),
      ),
      _DashboardMenuAction(
        label: 'Customers',
        icon: Icons.people_outline,
        onPressed: () => context.pushNamed(CustomerListPageWidget.routeName),
      ),
      if (canViewDeletedOrders(role))
        _DashboardMenuAction(
          label: 'Deleted Orders',
          icon: Icons.delete_sweep_outlined,
          onPressed: () =>
              context.pushNamed(DeletedOrdersPageWidget.routeName),
        ),
      _DashboardMenuAction(
        label: 'Product List',
        icon: Icons.inventory_2_outlined,
        onPressed: () => context.pushNamed(ProductlistWidget.routeName),
      ),
      if (canViewUserList(role))
        _DashboardMenuAction(
          label: 'User List',
          icon: Icons.people_outline,
          onPressed: () => context.pushNamed(UserListPageWidget.routeName),
        ),
      _DashboardMenuAction(
        label: 'View Reports',
        icon: Icons.assessment,
        onPressed: () => context.pushNamed(SalesReportPageWidget.routeName),
      ),
    ];

    final logoutAction = _DashboardMenuAction(
      label: 'Logout',
      icon: Icons.logout,
      onPressed: () => context.pushNamed(LoginPageWidget.routeName),
    );

    actions.sort((a, b) => a.label.compareTo(b.label));
    actions.add(logoutAction);

    return Material(
      color: theme.secondaryBackground,
      borderRadius: BorderRadius.circular(12),
      clipBehavior: Clip.antiAlias,
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: theme.alternate),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16),
          childrenPadding: EdgeInsets.zero,
          leading: Icon(Icons.menu, color: theme.primary),
          title: Text(
            'Menu',
            style: theme.titleMedium.override(
              font: GoogleFonts.interTight(fontWeight: FontWeight.w600),
            ),
          ),
          subtitle: Text(
            '${actions.length} actions',
            style: theme.labelSmall.override(color: theme.secondaryText),
          ),
          children: [
            for (final action in actions)
              ListTile(
                leading: Icon(action.icon, color: theme.primary, size: 22),
                title: Text(action.label),
                onTap: action.onPressed,
              ),
          ],
        ),
      ),
    );
  }
}

class _DashboardMenuAction {
  const _DashboardMenuAction({
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  final String label;
  final IconData icon;
  final VoidCallback onPressed;
}
