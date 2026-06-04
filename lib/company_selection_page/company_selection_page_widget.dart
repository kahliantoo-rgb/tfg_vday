import '/auth/role_helpers.dart';
import '/backend/backend.dart';
import '/backend/company_query_helpers.dart';
import '/backend/tenant_context.dart';
import '/components/home_nav_button.dart';
import '/backend/user_query_helpers.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/index.dart';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'company_selection_page_model.dart';
export 'company_selection_page_model.dart';

/// Create a FlutterFlow page named "CompanySelectionPage".
///
/// Purpose:
/// Allow users to select which company they are operating under after login.
///
/// Data Source:
/// - Companies collection
/// - Filter: is_active == true
///
/// Layout:
/// - AppBar title: "Select Company"
/// - ListView of company cards
///
/// Each Card:
/// - Company Name
/// - Company Phone
/// - Optional UEN label if exists
///
/// Actions:
/// - On card tap:
///   - Save selected companyRef to App State
///   - Navigate to Sales Dashboard
///
/// Rules:
/// - Use FlutterFlow App State for selected company
/// - No custom code
/// - Clean spacing and clear tap feedback
class CompanySelectionPageWidget extends StatefulWidget {
  const CompanySelectionPageWidget({super.key});

  static String routeName = 'CompanySelectionPage';
  static String routePath = '/companySelectionPage';

  @override
  State<CompanySelectionPageWidget> createState() =>
      _CompanySelectionPageWidgetState();
}

class _CompanySelectionPageWidgetState
    extends State<CompanySelectionPageWidget> {
  late CompanySelectionPageModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();
  UsersRecord? _profile;

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => CompanySelectionPageModel());
    _model.searchController ??= TextEditingController();
    _model.searchFocusNode ??= FocusNode();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      _profile = await resolveCurrentUserProfile();
      safeSetState(() {});
    });
  }

  @override
  void dispose() {
    _model.dispose();

    super.dispose();
  }

  void _onSearchChanged(String _) => safeSetState(() {});

  Future<void> _selectAllCompanies() async {
    await TenantContext.instance.setViewAllCompanies();
    if (!mounted) {
      return;
    }
    context.go(SalesDashBoardWidget.routePath);
  }

  Future<void> _selectCompany(CompaniesRecord company) async {
    await TenantContext.instance.setActiveCompany(
      company.reference,
      viewAll: false,
    );
    if (!mounted) {
      return;
    }
    context.go(SalesDashBoardWidget.routePath);
  }

  Widget _buildAllCompaniesCard(BuildContext context, {required bool selected}) {
    return InkWell(
      onTap: _selectAllCompanies,
      child: Card(
        color: selected
            ? FlutterFlowTheme.of(context).primary
            : FlutterFlowTheme.of(context).secondaryBackground,
        elevation: selected ? 4.0 : 2.0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
          side: selected
              ? BorderSide.none
              : BorderSide(
                  color: FlutterFlowTheme.of(context).primary,
                  width: 1.5,
                ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Icon(
                Icons.business,
                color: selected
                    ? Colors.white
                    : FlutterFlowTheme.of(context).primary,
              ),
              const SizedBox(width: 12.0),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'All companies',
                      style: FlutterFlowTheme.of(context).titleMedium.override(
                            font: GoogleFonts.interTight(
                              fontWeight: FontWeight.w600,
                            ),
                            color: selected
                                ? Colors.white
                                : FlutterFlowTheme.of(context).primaryText,
                            letterSpacing: 0.0,
                          ),
                    ),
                    Text(
                      'Cross-company view (orders, reports)',
                      style: FlutterFlowTheme.of(context).bodySmall.override(
                            font: GoogleFonts.inter(),
                            color: selected
                                ? Colors.white70
                                : FlutterFlowTheme.of(context).secondaryText,
                            letterSpacing: 0.0,
                          ),
                    ),
                  ],
                ),
              ),
              if (selected)
                const Icon(Icons.check_circle, color: Colors.white)
              else
                Icon(
                  Icons.chevron_right,
                  color: FlutterFlowTheme.of(context).secondaryText,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCompanyCard(
    BuildContext context,
    CompaniesRecord company, {
    required bool selected,
  }) {
    return InkWell(
      onTap: () => _selectCompany(company),
      child: Card(
        clipBehavior: Clip.antiAliasWithSaveLayer,
        color: selected
            ? FlutterFlowTheme.of(context).accent1
            : FlutterFlowTheme.of(context).secondaryBackground,
        elevation: selected ? 4.0 : 2.0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
          side: selected
              ? BorderSide(
                  color: FlutterFlowTheme.of(context).primary,
                  width: 2.0,
                )
              : BorderSide.none,
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      company.companyName,
                      style: FlutterFlowTheme.of(context).titleMedium.override(
                            font: GoogleFonts.interTight(
                              fontWeight: FontWeight.w600,
                            ),
                            color: FlutterFlowTheme.of(context).primaryText,
                            letterSpacing: 0.0,
                          ),
                    ),
                    if (company.companyPhone.isNotEmpty) ...[
                      const SizedBox(height: 6.0),
                      Row(
                        children: [
                          Icon(
                            Icons.phone,
                            color: FlutterFlowTheme.of(context).secondaryText,
                            size: 16.0,
                          ),
                          const SizedBox(width: 6.0),
                          Text(
                            company.companyPhone,
                            style: FlutterFlowTheme.of(context).bodyMedium.override(
                                  font: GoogleFonts.inter(),
                                  color:
                                      FlutterFlowTheme.of(context).secondaryText,
                                  letterSpacing: 0.0,
                                ),
                          ),
                        ],
                      ),
                    ],
                    if (company.companyUen.isNotEmpty) ...[
                      const SizedBox(height: 4.0),
                      Text(
                        'UEN: ${company.companyUen}',
                        style: FlutterFlowTheme.of(context).bodySmall.override(
                              font: GoogleFonts.inter(),
                              color: FlutterFlowTheme.of(context).secondaryText,
                              letterSpacing: 0.0,
                            ),
                      ),
                    ],
                  ],
                ),
              ),
              if (selected)
                Icon(
                  Icons.check_circle,
                  color: FlutterFlowTheme.of(context).primary,
                )
              else
                Icon(
                  Icons.chevron_right,
                  color: FlutterFlowTheme.of(context).secondaryText,
                ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
        FocusManager.instance.primaryFocus?.unfocus();
      },
      child: Scaffold(
        key: scaffoldKey,
        backgroundColor: FlutterFlowTheme.of(context).primaryBackground,
        appBar: AppBar(
          backgroundColor: FlutterFlowTheme.of(context).secondaryBackground,
          automaticallyImplyLeading: false,
          title: Text(
            'Select Company',
            style: FlutterFlowTheme.of(context).headlineMedium.override(
                  font: GoogleFonts.interTight(
                    fontWeight: FontWeight.w600,
                    fontStyle:
                        FlutterFlowTheme.of(context).headlineMedium.fontStyle,
                  ),
                  color: FlutterFlowTheme.of(context).primaryText,
                  fontSize: 22.0,
                  letterSpacing: 0.0,
                  fontWeight: FontWeight.w600,
                  fontStyle:
                      FlutterFlowTheme.of(context).headlineMedium.fontStyle,
                ),
          ),
          actions: const [
            HomeNavIconButton(),
          ],
          centerTitle: true,
          elevation: 2.0,
        ),
        body: SafeArea(
          top: true,
          child: Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(16.0, 16.0, 16.0, 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (isSuperAdminRole(_profile?.role)) ...[
                  Text(
                    'Choose a company to view its data, or select all companies.',
                    style: FlutterFlowTheme.of(context).bodyMedium.override(
                          font: GoogleFonts.inter(),
                          color: FlutterFlowTheme.of(context).secondaryText,
                          letterSpacing: 0.0,
                        ),
                  ),
                  const SizedBox(height: 12.0),
                ],
                TextFormField(
                  controller: _model.searchController,
                  focusNode: _model.searchFocusNode,
                  decoration: InputDecoration(
                    hintText: 'Search company name, phone, UEN...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: (_model.searchController?.text.isNotEmpty ?? false)
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _model.searchController?.clear();
                              _onSearchChanged('');
                            },
                          )
                        : null,
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                        color: FlutterFlowTheme.of(context).alternate,
                      ),
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(
                        color: FlutterFlowTheme.of(context).primary,
                      ),
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    filled: true,
                    fillColor: FlutterFlowTheme.of(context).secondaryBackground,
                  ),
                  onChanged: _onSearchChanged,
                ),
                const SizedBox(height: 12.0),
                Expanded(
                  child: ListenableBuilder(
                    listenable: TenantContext.instance,
                    builder: (context, _) {
                      return StreamBuilder<List<CompaniesRecord>>(
                        stream: queryCompaniesRecord(
                          queryBuilder:
                              TenantContext.instance.companiesQueryForUser(
                            _profile,
                          ),
                        ),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData) {
                            return Center(
                              child: SizedBox(
                                width: 50.0,
                                height: 50.0,
                                child: CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    FlutterFlowTheme.of(context).primary,
                                  ),
                                ),
                              ),
                            );
                          }

                          final searchText = _model.searchController?.text ?? '';
                          final allCompanies = snapshot.data!;
                          final filteredCompanies = filterCompaniesBySearchQuery(
                            allCompanies,
                            searchText,
                          );
                          final showAllOption =
                              TenantContext.canViewAllCompanies(_profile);
                          final tenant = TenantContext.instance;
                          final viewingAll = tenant.isViewingAllCompanies;
                          final activeRef = tenant.activeCompanyRef;

                          if (filteredCompanies.isEmpty &&
                              !(showAllOption && searchText.trim().isEmpty)) {
                            return Center(
                              child: Text(
                                searchText.trim().isEmpty
                                    ? 'No active companies found.'
                                    : 'No companies match "$searchText".',
                                textAlign: TextAlign.center,
                                style: FlutterFlowTheme.of(context)
                                    .bodyMedium
                                    .override(
                                      font: GoogleFonts.inter(),
                                      color: FlutterFlowTheme.of(context)
                                          .secondaryText,
                                      letterSpacing: 0.0,
                                    ),
                              ),
                            );
                          }

                          final itemCount = filteredCompanies.length +
                              (showAllOption && searchText.trim().isEmpty
                                  ? 1
                                  : 0);

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                '$itemCount ${itemCount == 1 ? 'result' : 'results'}',
                                style: FlutterFlowTheme.of(context)
                                    .labelMedium
                                    .override(
                                      font: GoogleFonts.inter(),
                                      color: FlutterFlowTheme.of(context)
                                          .secondaryText,
                                      letterSpacing: 0.0,
                                    ),
                              ),
                              const SizedBox(height: 8.0),
                              Expanded(
                                child: ListView.separated(
                                  padding: EdgeInsets.zero,
                                  itemCount: itemCount,
                                  separatorBuilder: (_, __) =>
                                      const SizedBox(height: 12.0),
                                  itemBuilder: (context, listViewIndex) {
                                    if (showAllOption &&
                                        searchText.trim().isEmpty &&
                                        listViewIndex == 0) {
                                      return _buildAllCompaniesCard(
                                        context,
                                        selected: viewingAll,
                                      );
                                    }

                                    final companyIndex = showAllOption &&
                                            searchText.trim().isEmpty
                                        ? listViewIndex - 1
                                        : listViewIndex;
                                    final company =
                                        filteredCompanies[companyIndex];
                                    final selected = !viewingAll &&
                                        activeRef != null &&
                                        activeRef.path ==
                                            company.reference.path;

                                    return _buildCompanyCard(
                                      context,
                                      company,
                                      selected: selected,
                                    );
                                  },
                                ),
                              ),
                            ],
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
