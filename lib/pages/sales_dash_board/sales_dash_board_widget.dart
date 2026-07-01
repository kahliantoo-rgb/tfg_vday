import '/app_version.dart';
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
import '/components/staff_notice_app_bar_button.dart';
import '/components/language_picker_button.dart';
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
  Future<DashboardOrderStatsLoadResult>? _statsFuture;
  int _statsGeneration = 0;

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => SalesDashBoardModel());
    DashboardStatsRefresh.instance.addListener(_onDashboardStatsRefreshRequested);

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (loggedIn) {
        final profile = await resolveCurrentUserProfile();
        await TenantContext.instance.initialize(profile);
        AppStateNotifier.instance.syncUserRole(profile?.role);
      }
      if (mounted) {
        _reloadDashboardStats(rollForward: true);
      }
    });
  }

  @override
  void dispose() {
    DashboardStatsRefresh.instance.removeListener(_onDashboardStatsRefreshRequested);
    _model.dispose();

    super.dispose();
  }

  void _onDashboardStatsRefreshRequested() {
    if (!mounted) {
      return;
    }
    _reloadDashboardStats(rollForward: false);
  }

  Future<void> _openFilteredOrdersAndRefresh(
    DashboardOrderListFilter filter,
  ) async {
    await openDashboardFilteredOrderList(context, filter);
    if (mounted) {
      _reloadDashboardStats(rollForward: false);
    }
  }

  void _reloadDashboardStats({required bool rollForward}) {
    final future = rollForward
        ? loadDashboardOrderStatsWithRollForward()
        : loadDashboardOrderStatsFresh();

    setState(() {
      _statsGeneration++;
      _statsFuture = future;
    });

    if (!rollForward) {
      return;
    }

    future.then((result) {
      if (mounted && result.rolledForwardCount > 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              tr(context, 'dashboard.leftoverMoved',
                  params: {'count': '${result.rolledForwardCount}'}),
            ),
          ),
        );
      }
    });
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
          title: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                tr(context, 'dashboard.title'),
                style: theme.headlineMedium.override(
                  font: GoogleFonts.interTight(fontWeight: FontWeight.w600),
                  color: Colors.white,
                  fontSize: 22.0,
                ),
              ),
              Text(
                appVersionDisplay,
                style: theme.labelSmall.override(
                  color: Colors.white70,
                  fontSize: 11,
                ),
              ),
            ],
          ),
          actions: [
            FlutterFlowIconButton(
              borderColor: Colors.transparent,
              borderRadius: 30.0,
              borderWidth: 1.0,
              buttonSize: 48.0,
              icon: const Icon(Icons.menu, color: Colors.white, size: 26.0),
              onPressed: () => _showDashboardMenuSheet(context),
            ),
            const StaffNoticeAppBarButton.onPrimary(),
            const LanguagePickerAppBarButton(),
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

              return RefreshIndicator(
                onRefresh: () async {
                  _reloadDashboardStats(rollForward: false);
                  await _statsFuture;
                },
                child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildOverviewHeader(context),
                    const SizedBox(height: 16),
                    FutureBuilder<DashboardOrderStatsLoadResult>(
                      key: ValueKey(_statsGeneration),
                      future: _statsFuture,
                      builder: (context, snapshot) {
                        if (snapshot.hasError) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 24),
                            child: Text(
                              describeFirestoreError(snapshot.error!),
                              textAlign: TextAlign.center,
                              style: theme.bodyMedium.override(color: theme.error),
                            ),
                          );
                        }
                        final stats = snapshot.data?.stats;
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
                              label: tr(context, 'dashboard.stat.todayDelivery'),
                              value: _statValue(
                                context,
                                stats?.todayDeliveryOrders,
                                loading: !snapshot.hasData &&
                                    snapshot.connectionState ==
                                        ConnectionState.waiting,
                              ),
                              onTap: () => _openFilteredOrdersAndRefresh(
                                DashboardOrderListFilter.todayDeliveryOrders,
                              ),
                            ),
                            _buildStatCard(
                              context,
                              icon: Icons.pending_actions,
                              iconColor: theme.warning,
                              label: tr(context, 'dashboard.stat.todayPending'),
                              value: _statValue(
                                context,
                                stats?.todayPendingOrders,
                                loading: !snapshot.hasData &&
                                    snapshot.connectionState ==
                                        ConnectionState.waiting,
                              ),
                              onTap: () => _openFilteredOrdersAndRefresh(
                                DashboardOrderListFilter.todayPendingOrders,
                              ),
                            ),
                            _buildStatCard(
                              context,
                              icon: Icons.check_circle,
                              iconColor: theme.success,
                              label: tr(context, 'dashboard.stat.todayComplete'),
                              value: _statValue(
                                context,
                                stats?.todayCompletedOrders,
                                loading: !snapshot.hasData &&
                                    snapshot.connectionState ==
                                        ConnectionState.waiting,
                              ),
                              onTap: () => _openFilteredOrdersAndRefresh(
                                DashboardOrderListFilter.todayCompletedOrders,
                              ),
                            ),
                            _buildStatCard(
                              context,
                              icon: Icons.analytics,
                              iconColor: theme.tertiary,
                              label: tr(context, 'dashboard.stat.todayTotal'),
                              value: _statValue(
                                context,
                                stats?.todayTotalOrders,
                                loading: !snapshot.hasData &&
                                    snapshot.connectionState ==
                                        ConnectionState.waiting,
                              ),
                              onTap: () => _openFilteredOrdersAndRefresh(
                                DashboardOrderListFilter.todayTotalOrders,
                              ),
                            ),
                            _buildStatCard(
                              context,
                              icon: Icons.history,
                              iconColor: theme.error,
                              label: tr(context, 'dashboard.stat.leftover'),
                              value: _statValue(
                                context,
                                stats?.leftoverOrders,
                                loading: !snapshot.hasData &&
                                    snapshot.connectionState ==
                                        ConnectionState.waiting,
                              ),
                              onTap: () => _openFilteredOrdersAndRefresh(
                                DashboardOrderListFilter.leftoverOrders,
                              ),
                            ),
                            _buildStatCard(
                              context,
                              icon: Icons.local_shipping,
                              iconColor: theme.secondary,
                              label: tr(context, 'dashboard.stat.tomorrowDelivery'),
                              value: _statValue(
                                context,
                                stats?.tomorrowDeliveryOrders,
                                loading: !snapshot.hasData &&
                                    snapshot.connectionState ==
                                        ConnectionState.waiting,
                              ),
                              onTap: () => _openFilteredOrdersAndRefresh(
                                DashboardOrderListFilter.tomorrowDeliveryOrders,
                              ),
                            ),
                            _buildStatCard(
                              context,
                              icon: Icons.event_note,
                              iconColor: theme.secondaryText,
                              label: tr(context, 'dashboard.stat.tomorrowTotal'),
                              value: _statValue(
                                context,
                                stats?.tomorrowTotalOrders,
                                loading: !snapshot.hasData &&
                                    snapshot.connectionState ==
                                        ConnectionState.waiting,
                              ),
                              onTap: () => _openFilteredOrdersAndRefresh(
                                DashboardOrderListFilter.tomorrowTotalOrders,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 28),
                    Text(
                      tr(context, 'dashboard.quickActions'),
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
                      text: _creatingOrder
                          ? tr(context, 'dashboard.creating')
                          : tr(context, 'dashboard.createOrder'),
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
                        label: tr(context, 'dashboard.pasteWhatsapp'),
                        onDashboardImport: () =>
                            runWhatsAppOrderImportFromDashboard(context),
                      ),
                    ],
                  ],
                ),
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
      tr(context, 'dashboard.overview'),
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
    bool failed = false,
  }) {
    final theme = FlutterFlowTheme.of(context);
    if (failed) {
      return Text(
        '--',
        style: theme.headlineSmall.override(
          font: GoogleFonts.interTight(fontWeight: FontWeight.bold),
          fontSize: 26.0,
          color: theme.secondaryText,
        ),
      );
    }
    if (loading) {
      return const SizedBox(
        height: 28,
        width: 28,
        child: CircularProgressIndicator(strokeWidth: 2.5),
      );
    }
    if (count == null) {
      return Text(
        '--',
        style: theme.headlineSmall.override(
          font: GoogleFonts.interTight(fontWeight: FontWeight.bold),
          fontSize: 26.0,
          color: theme.secondaryText,
        ),
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

  List<_DashboardMenuSection> _dashboardMenuSections(BuildContext context) {
    final role = AppStateNotifier.instance.userRole;

    _DashboardMenuAction action({
      required String label,
      required IconData icon,
      required VoidCallback onPressed,
    }) {
      return _DashboardMenuAction(
        label: label,
        icon: icon,
        onPressed: onPressed,
      );
    }

    final sections = <_DashboardMenuSection>[
      _DashboardMenuSection(
        title: tr(context, 'dashboard.section.orders'),
        actions: [
          action(
            label: tr(context, 'dashboard.action.allOrders'),
            icon: Icons.list_alt,
            onPressed: () async {
              await context.pushNamed(OrderlistWidget.routeName);
              if (mounted) {
                _reloadDashboardStats(rollForward: false);
              }
            },
          ),
          if (canAssignDriver(role))
            action(
              label: tr(context, 'dashboard.action.driverAssignments'),
              icon: Icons.local_shipping_outlined,
              onPressed: () =>
                  context.pushNamed(DriverAssignmentsPageWidget.routeName),
            ),
          if (canViewDeletedOrders(role))
            action(
              label: tr(context, 'dashboard.action.deletedOrders'),
              icon: Icons.delete_sweep_outlined,
              onPressed: () =>
                  context.pushNamed(DeletedOrdersPageWidget.routeName),
            ),
        ],
      ),
      _DashboardMenuSection(
        title: tr(context, 'dashboard.section.customersBilling'),
        actions: [
          action(
            label: tr(context, 'dashboard.action.customers'),
            icon: Icons.people_outline,
            onPressed: () =>
                context.pushNamed(CustomerListPageWidget.routeName),
          ),
          if (canViewCreditAndInvoices(role))
            action(
              label: tr(context, 'dashboard.action.invoiceList'),
              icon: Icons.receipt_long_outlined,
              onPressed: () =>
                  context.pushNamed(InvoiceListPageWidget.routeName),
            ),
        ],
      ),
      _DashboardMenuSection(
        title: tr(context, 'dashboard.section.catalog'),
        actions: [
          action(
            label: tr(context, 'dashboard.action.productList'),
            icon: Icons.inventory_2_outlined,
            onPressed: () => context.pushNamed(ProductlistWidget.routeName),
          ),
          if (canCreateProducts(role) || canEditProducts(role))
            action(
              label: tr(context, 'dashboard.action.materialList'),
              icon: Icons.grass_outlined,
              onPressed: () => context.pushNamed(MateriallistWidget.routeName),
            ),
        ],
      ),
      _DashboardMenuSection(
        title: tr(context, 'dashboard.section.reports'),
        actions: [
          action(
            label: tr(context, 'dashboard.action.salesReport'),
            icon: Icons.assessment,
            onPressed: () =>
                context.pushNamed(SalesReportPageWidget.routeName),
          ),
          if (canCreateProducts(role) || canEditProducts(role))
            action(
              label: tr(context, 'dashboard.action.materialUsage'),
              icon: Icons.inventory_outlined,
              onPressed: () =>
                  context.pushNamed(MaterialUsageReportPageWidget.routeName),
            ),
          action(
            label: tr(context, 'dashboard.action.profitSummary'),
            icon: Icons.account_balance_wallet_outlined,
            onPressed: () =>
                context.pushNamed(ProfitSummaryReportPageWidget.routeName),
          ),
        ],
      ),
      _DashboardMenuSection(
        title: tr(context, 'dashboard.section.admin'),
        actions: [
          if (canViewUserList(role))
            action(
              label: tr(context, 'dashboard.action.userList'),
              icon: Icons.group_outlined,
              onPressed: () => context.pushNamed(UserListPageWidget.routeName),
            ),
          if (canEditCompanyProfile(role))
            action(
              label: tr(context, 'dashboard.action.companyProfile'),
              icon: Icons.business,
              onPressed: () =>
                  context.pushNamed(CompanySettingPageWidget.routeName),
            ),
          if (canViewAuditLog(role))
            action(
              label: tr(context, 'dashboard.action.auditLog'),
              icon: Icons.history,
              onPressed: () => context.pushNamed(AuditLogPageWidget.routeName),
            ),
        ],
      ),
      _DashboardMenuSection(
        title: tr(context, 'dashboard.section.account'),
        actions: [
          action(
            label: tr(context, 'dashboard.action.logout'),
            icon: Icons.logout,
            onPressed: () => context.pushNamed(LoginPageWidget.routeName),
          ),
        ],
      ),
    ];

    return sections
        .where((section) => section.actions.isNotEmpty)
        .toList(growable: false);
  }

  Future<void> _showDashboardMenuSheet(BuildContext context) async {
    final theme = FlutterFlowTheme.of(context);
    final sections = _dashboardMenuSections(context);
    final actionCount =
        sections.fold<int>(0, (sum, section) => sum + section.actions.length);

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: theme.secondaryBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetContext) {
        final maxHeight = MediaQuery.sizeOf(sheetContext).height * 0.7;
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Row(
                  children: [
                    Icon(Icons.menu, color: theme.primary),
                    const SizedBox(width: 10),
                    Text(
                      tr(sheetContext, 'dashboard.menu.title'),
                      style: theme.titleMedium.override(
                        font: GoogleFonts.interTight(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      tr(sheetContext, 'dashboard.menu.actionCount',
                          params: {'count': '$actionCount'}),
                      style: theme.labelSmall.override(
                        color: theme.secondaryText,
                      ),
                    ),
                  ],
                ),
              ),
              Divider(height: 1, color: theme.alternate),
              ConstrainedBox(
                constraints: BoxConstraints(maxHeight: maxHeight),
                child: ListView(
                  shrinkWrap: true,
                  padding: const EdgeInsets.only(bottom: 8),
                  children: [
                    for (var sectionIndex = 0;
                        sectionIndex < sections.length;
                        sectionIndex++) ...[
                      if (sectionIndex > 0)
                        Divider(height: 1, color: theme.alternate),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
                        child: Text(
                          sections[sectionIndex].title,
                          style: theme.labelLarge.override(
                            font: GoogleFonts.interTight(
                              fontWeight: FontWeight.w700,
                            ),
                            color: theme.secondaryText,
                          ),
                        ),
                      ),
                      for (final action in sections[sectionIndex].actions)
                        ListTile(
                          leading: Icon(action.icon, color: theme.primary),
                          title: Text(action.label),
                          onTap: () {
                            Navigator.pop(sheetContext);
                            action.onPressed();
                          },
                        ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _DashboardMenuSection {
  const _DashboardMenuSection({
    required this.title,
    required this.actions,
  });

  final String title;
  final List<_DashboardMenuAction> actions;
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
