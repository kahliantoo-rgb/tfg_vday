import '/auth/role_helpers.dart';
import '/auth/firebase_auth/auth_util.dart';
import '/backend/backend.dart';
import '/backend/schema/enums/enums.dart';
import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/backend/create_order_service.dart';
import '/backend/tenant_context.dart';
import '/backend/user_query_helpers.dart';
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
                    _buildOverviewHeader(context, wide: wide),
                    const SizedBox(height: 16),
                    GridView.count(
                      crossAxisCount: statColumns,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: statAspectRatio,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      children: [
                        _buildStatCard(
                          context,
                          icon: Icons.today,
                          iconColor: theme.primary,
                          label: 'Today Delivery',
                          value: FutureBuilder<List<OrdersRecord>>(
                            future: queryTenantOrdersRecordOnce(
                              queryBuilder: (ordersRecord) =>
                                  ordersRecord.where(
                                'delivery_date',
                                isEqualTo: getCurrentTimestamp,
                              ),
                            ),
                            builder: (context, snapshot) =>
                                _statValue(context, snapshot.data?.length),
                          ),
                        ),
                        _buildStatCard(
                          context,
                          icon: Icons.pending_actions,
                          iconColor: theme.warning,
                          label: 'Pending Orders',
                          value: FutureBuilder<int>(
                            future: queryTenantOrdersRecordCount(
                              queryBuilder: (ordersRecord) =>
                                  ordersRecord.where(
                                'status',
                                isEqualTo: OrderStatus.pending.serialize(),
                              ),
                            ),
                            builder: (context, snapshot) =>
                                _statValue(context, snapshot.data),
                          ),
                        ),
                        _buildStatCard(
                          context,
                          icon: Icons.check_circle,
                          iconColor: theme.success,
                          label: 'Completed Orders',
                          value: FutureBuilder<int>(
                            future: queryTenantOrdersRecordCount(
                              queryBuilder: (ordersRecord) =>
                                  ordersRecord.where(
                                'status',
                                isEqualTo: OrderStatus.completed.serialize(),
                              ),
                            ),
                            builder: (context, snapshot) =>
                                _statValue(context, snapshot.data),
                          ),
                        ),
                        _buildStatCard(
                          context,
                          icon: Icons.analytics,
                          iconColor: theme.tertiary,
                          label: 'Total Orders',
                          value: FutureBuilder<int>(
                            future: queryTenantOrdersRecordCount(),
                            builder: (context, snapshot) =>
                                _statValue(context, snapshot.data),
                          ),
                        ),
                      ],
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
                    const SizedBox(height: 10),
                    FFButtonWidget(
                      onPressed: () =>
                          context.pushNamed(ProductlistWidget.routeName),
                      text: 'Product List',
                      icon: const Icon(Icons.inventory_2_outlined, size: 20.0),
                      options: FFButtonOptions(
                        width: double.infinity,
                        height: 48.0,
                        color: theme.secondaryBackground,
                        iconColor: theme.primary,
                        textStyle: theme.titleSmall.override(
                          font: GoogleFonts.interTight(fontWeight: FontWeight.w600),
                          color: theme.primary,
                        ),
                        borderSide: BorderSide(color: theme.primary, width: 1.0),
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildSecondaryActions(context, wide: wide),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildOverviewHeader(BuildContext context, {required bool wide}) {
    final theme = FlutterFlowTheme.of(context);
    if (wide) {
      return Row(
        children: [
          Expanded(
            child: Text(
              'Dashboard Overview',
              style: theme.headlineMedium.override(
                font: GoogleFonts.interTight(fontWeight: FontWeight.bold),
              ),
            ),
          ),
          FFButtonWidget(
            onPressed: () => context.pushNamed(OrderlistWidget.routeName),
            text: 'All Orders',
            icon: const Icon(Icons.list_alt, size: 18.0),
            options: FFButtonOptions(
              height: 40.0,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              color: theme.secondaryBackground,
              iconColor: theme.primary,
              textStyle: theme.titleSmall.override(
                font: GoogleFonts.interTight(fontWeight: FontWeight.w600),
                color: theme.primary,
              ),
              borderSide: BorderSide(color: theme.primary),
              borderRadius: BorderRadius.circular(8.0),
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Dashboard Overview',
          style: theme.headlineMedium.override(
            font: GoogleFonts.interTight(fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(height: 12),
        FFButtonWidget(
          onPressed: () => context.pushNamed(OrderlistWidget.routeName),
          text: 'All Orders',
          icon: const Icon(Icons.list_alt, size: 18.0),
          options: FFButtonOptions(
            width: double.infinity,
            height: 40.0,
            color: theme.secondaryBackground,
            iconColor: theme.primary,
            textStyle: theme.titleSmall.override(
              font: GoogleFonts.interTight(fontWeight: FontWeight.w600),
              color: theme.primary,
            ),
            borderSide: BorderSide(color: theme.primary),
            borderRadius: BorderRadius.circular(8.0),
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String label,
    required Widget value,
  }) {
    final theme = FlutterFlowTheme.of(context);
    return Container(
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
    );
  }

  Widget _statValue(BuildContext context, int? count) {
    final theme = FlutterFlowTheme.of(context);
    if (count == null) {
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

  Widget _buildSecondaryActions(BuildContext context, {required bool wide}) {
    final role = AppStateNotifier.instance.userRole;
    final showCompanyProfile = canEditCompanyProfile(role);
    final showUserList = canViewUserList(role);

    final buttons = <Widget>[
      if (showCompanyProfile)
        _outlineActionButton(
          context,
          label: 'Company Profile',
          icon: Icons.business,
          onPressed: () =>
              context.pushNamed(CompanySettingPageWidget.routeName),
        ),
      if (showUserList)
        _outlineActionButton(
          context,
          label: 'User List',
          icon: Icons.people_outline,
          onPressed: () => context.pushNamed(UserListPageWidget.routeName),
        ),
      _outlineActionButton(
        context,
        label: 'View Reports',
        icon: Icons.assessment,
        onPressed: () => context.pushNamed(SalesReportPageWidget.routeName),
      ),
      _outlineActionButton(
        context,
        label: 'Logout',
        icon: Icons.logout,
        onPressed: () => context.pushNamed(LoginPageWidget.routeName),
      ),
    ];

    if (wide && buttons.length > 1) {
      return Row(
        children: buttons
            .map(
              (button) => Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                    right: button == buttons.last ? 0 : 10,
                  ),
                  child: button,
                ),
              ),
            )
            .toList(),
      );
    }

    return Column(
      children: [
        for (var i = 0; i < buttons.length; i++) ...[
          if (i > 0) const SizedBox(height: 10),
          buttons[i],
        ],
      ],
    );
  }

  Widget _outlineActionButton(
    BuildContext context, {
    required String label,
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    final theme = FlutterFlowTheme.of(context);
    return FFButtonWidget(
      onPressed: onPressed,
      text: label,
      icon: Icon(icon, size: 18.0),
      options: FFButtonOptions(
        width: double.infinity,
        height: 44.0,
        color: theme.secondaryBackground,
        iconColor: theme.primaryText,
        textStyle: theme.titleSmall.override(
          font: GoogleFonts.interTight(fontWeight: FontWeight.w600),
          color: theme.primaryText,
        ),
        borderSide: BorderSide(color: theme.alternate),
        borderRadius: BorderRadius.circular(8.0),
      ),
    );
  }
}
