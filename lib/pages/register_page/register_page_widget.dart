import '/auth/role_helpers.dart';
import '/auth/viewer_role_helpers.dart';
import '/auth/auth_redirect.dart';
import '/auth/firebase_auth/auth_util.dart';
import '/auth/register_user_service.dart';
import '/backend/backend.dart';
import '/backend/staff_role_helpers.dart';
import '/backend/tenant_context.dart';
import '/backend/user_query_helpers.dart';
import '/flutter_flow/nav/nav.dart';
import '/backend/schema/enums/enums.dart';
import '/flutter_flow/flutter_flow_drop_down.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/flutter_flow/form_field_controller.dart';
import '/index.dart';
import '/components/home_nav_button.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'register_page_model.dart';
export 'register_page_model.dart';

class RegisterPageWidget extends StatefulWidget {
  const RegisterPageWidget({super.key});

  static String routeName = 'RegisterPage';
  static String routePath = '/register';

  @override
  State<RegisterPageWidget> createState() => _RegisterPageWidgetState();
}

class _RegisterPageWidgetState extends State<RegisterPageWidget> {
  late RegisterPageModel _model;
  final scaffoldKey = GlobalKey<ScaffoldState>();

  Map<String, DocumentReference> _companyRefsByName = {};
  List<UserRole> _tenantStaffRoles = const [];
  bool _loadingRoles = true;

  bool get _canSelectCompany =>
      canSelectCompanyForStaffRegistration(
        currentViewerRole(),
      );

  List<UserRole> get _registrationRoleOptions => staffRegistrationRoleOptions(
        currentViewerRole(),
        tenantRoles: _tenantStaffRoles,
      );

  List<String> get _roleOptions =>
      _registrationRoleOptions.map((role) => role.serialize()).toList();

  List<String> get _roleOptionLabels =>
      _registrationRoleOptions.map(userRoleLabel).toList();

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => RegisterPageModel());
    _model.nameTextController ??= TextEditingController();
    _model.nameFocusNode ??= FocusNode();
    _model.emailTextController ??= TextEditingController();
    _model.emailFocusNode ??= FocusNode();
    _model.phoneTextController ??= TextEditingController();
    _model.phoneFocusNode ??= FocusNode();
    _model.passwordTextController ??= TextEditingController();
    _model.passwordFocusNode ??= FocusNode();
    _model.confirmPasswordTextController ??= TextEditingController();
    _model.confirmPasswordFocusNode ??= FocusNode();
    _model.roleDropDownValue ??= UserRole.senior_florist.serialize();
    _model.companyDropDownValue ??= '';
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadStaffRoles());
  }

  Future<void> _loadStaffRoles() async {
    if (loggedIn) {
      final profile = await resolveCurrentUserProfile();
      await TenantContext.instance.initialize(profile);
    }
    final roles = await loadManagedStaffRolesWithFallback();
    if (!mounted) {
      return;
    }
    final options = staffRegistrationRoleOptions(
      currentViewerRole(),
      tenantRoles: roles,
    );
    setState(() {
      _tenantStaffRoles = roles;
      _loadingRoles = false;
      if (options.isNotEmpty &&
          !options.any(
            (role) => role.serialize() == _model.roleDropDownValue,
          )) {
        _model.roleDropDownValue = options.first.serialize();
        _model.roleDropDownController?.value = _model.roleDropDownValue;
      }
    });
  }

  @override
  void dispose() {
    _model.dispose();
    super.dispose();
  }

  InputDecoration _fieldDecoration(BuildContext context, String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: FlutterFlowTheme.of(context).labelMedium,
      enabledBorder: OutlineInputBorder(
        borderSide: BorderSide(
          color: FlutterFlowTheme.of(context).alternate,
          width: 2.0,
        ),
        borderRadius: BorderRadius.circular(12.0),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: BorderSide(
          color: FlutterFlowTheme.of(context).primary,
          width: 2.0,
        ),
        borderRadius: BorderRadius.circular(12.0),
      ),
      filled: true,
      fillColor: FlutterFlowTheme.of(context).secondaryBackground,
    );
  }

  Future<void> _submitRegister() async {
    final name = _model.nameTextController!.text;
    final email = _model.emailTextController!.text;
    final password = _model.passwordTextController!.text;
    final confirm = _model.confirmPasswordTextController!.text;
    final phone = _model.phoneTextController!.text;

    if (password != confirm) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Passwords do not match.')),
      );
      return;
    }

    final role = deserializeEnum<UserRole>(_model.roleDropDownValue);
    if (role == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a role.')),
      );
      return;
    }

    final DocumentReference? companyRef;
    if (_canSelectCompany) {
      final companyName = _model.companyDropDownValue;
      companyRef = companyName != null && companyName.isNotEmpty
          ? _companyRefsByName[companyName]
          : null;
      if (companyRef == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a company.')),
        );
        return;
      }
    } else {
      companyRef = TenantContext.instance.writeCompanyRef;
      if (companyRef == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Your admin profile has no company. Ask a super admin to set companyRef.',
            ),
          ),
        );
        return;
      }
    }

    safeSetState(() => _model.isSubmitting = true);

    final result = await registerStaffUser(
      context: context,
      email: email,
      password: password,
      name: name,
      role: role,
      companyRef: companyRef,
      phoneNumber: phone,
    );

    if (!mounted) {
      return;
    }
    safeSetState(() => _model.isSubmitting = false);

    if (!result.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.errorMessage ?? 'Registration failed.'),
        ),
      );
      return;
    }

    if (result.signedOutAdminSession) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Staff account created. Sign in again with your admin account.',
          ),
        ),
      );
      context.go(LoginPageWidget.routePath);
      return;
    }

    await AppStateNotifier.instance.loadUserRole();
    final routePath = await getPostLoginRoutePath();
    if (!mounted) {
      return;
    }
    context.go(routePath);
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
        backgroundColor: FlutterFlowTheme.of(context).secondaryBackground,
        appBar: AppBar(
          backgroundColor: FlutterFlowTheme.of(context).secondaryBackground,
          automaticallyImplyLeading: true,
          title: Text(
            'Add staff',
            style: FlutterFlowTheme.of(context).headlineSmall,
          ),
          actions: const [
            HomeNavIconButton(),
          ],
          centerTitle: false,
          elevation: 0.0,
        ),
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsetsDirectional.fromSTEB(24.0, 8.0, 24.0, 24.0),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 530.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Create staff account',
                      style: FlutterFlowTheme.of(context).headlineMedium.override(
                            font: GoogleFonts.interTight(
                              fontWeight: FontWeight.w600,
                            ),
                            letterSpacing: 0.0,
                          ),
                    ),
                    Padding(
                      padding: const EdgeInsetsDirectional.fromSTEB(0.0, 8.0, 0.0, 16.0),
                      child: Text(
                        _canSelectCompany
                            ? 'Super admin: choose company, then create staff (Admin, Senior Florist, or Driver). You will be signed out — sign in again afterward.'
                            : 'Creates a staff account for your company (Admin, Senior Florist, or Driver). You will be signed out — sign in again afterward.',
                        style: FlutterFlowTheme.of(context).bodyMedium.override(
                              font: GoogleFonts.inter(),
                              color: FlutterFlowTheme.of(context).secondaryText,
                              letterSpacing: 0.0,
                            ),
                      ),
                    ),
                    TextFormField(
                      controller: _model.nameTextController,
                      focusNode: _model.nameFocusNode,
                      decoration: _fieldDecoration(context, 'Full name'),
                      style: FlutterFlowTheme.of(context).bodyLarge,
                      cursorColor: FlutterFlowTheme.of(context).primary,
                    ),
                    const SizedBox(height: 12.0),
                    TextFormField(
                      controller: _model.emailTextController,
                      focusNode: _model.emailFocusNode,
                      decoration: _fieldDecoration(context, 'Email'),
                      keyboardType: TextInputType.emailAddress,
                      style: FlutterFlowTheme.of(context).bodyLarge,
                      cursorColor: FlutterFlowTheme.of(context).primary,
                    ),
                    const SizedBox(height: 12.0),
                    TextFormField(
                      controller: _model.phoneTextController,
                      focusNode: _model.phoneFocusNode,
                      decoration: _fieldDecoration(context, 'Phone (optional)'),
                      keyboardType: TextInputType.phone,
                      style: FlutterFlowTheme.of(context).bodyLarge,
                      cursorColor: FlutterFlowTheme.of(context).primary,
                    ),
                    const SizedBox(height: 12.0),
                    TextFormField(
                      controller: _model.passwordTextController,
                      focusNode: _model.passwordFocusNode,
                      obscureText: !_model.passwordVisibility,
                      decoration: _fieldDecoration(context, 'Password').copyWith(
                        suffixIcon: InkWell(
                          onTap: () => safeSetState(
                            () => _model.passwordVisibility =
                                !_model.passwordVisibility,
                          ),
                          child: Icon(
                            _model.passwordVisibility
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                            color: FlutterFlowTheme.of(context).secondaryText,
                            size: 22.0,
                          ),
                        ),
                      ),
                      style: FlutterFlowTheme.of(context).bodyLarge,
                      cursorColor: FlutterFlowTheme.of(context).primary,
                    ),
                    const SizedBox(height: 12.0),
                    TextFormField(
                      controller: _model.confirmPasswordTextController,
                      focusNode: _model.confirmPasswordFocusNode,
                      obscureText: !_model.confirmPasswordVisibility,
                      decoration:
                          _fieldDecoration(context, 'Confirm password').copyWith(
                        suffixIcon: InkWell(
                          onTap: () => safeSetState(
                            () => _model.confirmPasswordVisibility =
                                !_model.confirmPasswordVisibility,
                          ),
                          child: Icon(
                            _model.confirmPasswordVisibility
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                            color: FlutterFlowTheme.of(context).secondaryText,
                            size: 22.0,
                          ),
                        ),
                      ),
                      style: FlutterFlowTheme.of(context).bodyLarge,
                      cursorColor: FlutterFlowTheme.of(context).primary,
                    ),
                    const SizedBox(height: 16.0),
                    FlutterFlowDropDown<String>(
                      controller: _model.roleDropDownController ??=
                          FormFieldController<String>(_model.roleDropDownValue),
                      options: _roleOptions,
                      optionLabels: _roleOptionLabels,
                      onChanged: (val) =>
                          safeSetState(() => _model.roleDropDownValue = val),
                      width: double.infinity,
                      height: 52.0,
                      textStyle: FlutterFlowTheme.of(context).bodyLarge,
                      hintText: 'Role',
                      icon: Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: FlutterFlowTheme.of(context).secondaryText,
                        size: 24.0,
                      ),
                      fillColor:
                          FlutterFlowTheme.of(context).secondaryBackground,
                      elevation: 0.0,
                      borderColor: FlutterFlowTheme.of(context).alternate,
                      borderWidth: 2.0,
                      borderRadius: 12.0,
                      margin: EdgeInsets.zero,
                      hidesUnderline: true,
                      isSearchable: false,
                      isMultiSelect: false,
                    ),
                    const SizedBox(height: 12.0),
                    if (_canSelectCompany)
                      StreamBuilder<List<CompaniesRecord>>(
                        stream: queryCompaniesRecord(
                          queryBuilder: (q) =>
                              q.where('is_active', isEqualTo: true),
                        ),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData) {
                            return const Center(
                              child: Padding(
                                padding: EdgeInsets.all(16.0),
                                child: CircularProgressIndicator(),
                              ),
                            );
                          }
                          final companies = snapshot.data!
                            ..sort(
                              (a, b) => a.companyName
                                  .toLowerCase()
                                  .compareTo(b.companyName.toLowerCase()),
                            );
                          _companyRefsByName = {
                            for (final c in companies)
                              c.companyName: c.reference,
                          };
                          final names =
                              companies.map((c) => c.companyName).toList();
                          if (names.isEmpty) {
                            return Text(
                              'No active companies found. Add a company in settings first.',
                              style: FlutterFlowTheme.of(context)
                                  .bodyMedium
                                  .override(
                                    font: GoogleFonts.inter(),
                                    color: FlutterFlowTheme.of(context).error,
                                  ),
                            );
                          }
                          final selected = _model.companyDropDownValue != null &&
                                  names.contains(_model.companyDropDownValue)
                              ? _model.companyDropDownValue!
                              : names.first;
                          _model.companyDropDownValue = selected;

                          return FlutterFlowDropDown<String>(
                            controller: _model.companyDropDownController ??=
                                FormFieldController<String>(selected),
                            options: names,
                            onChanged: (val) => safeSetState(
                              () => _model.companyDropDownValue = val,
                            ),
                            width: double.infinity,
                            height: 52.0,
                            textStyle: FlutterFlowTheme.of(context).bodyLarge,
                            hintText: 'Company',
                            icon: Icon(
                              Icons.keyboard_arrow_down_rounded,
                              color:
                                  FlutterFlowTheme.of(context).secondaryText,
                              size: 24.0,
                            ),
                            fillColor: FlutterFlowTheme.of(context)
                                .secondaryBackground,
                            elevation: 0.0,
                            borderColor:
                                FlutterFlowTheme.of(context).alternate,
                            borderWidth: 2.0,
                            borderRadius: 12.0,
                            margin: EdgeInsets.zero,
                            hidesUnderline: true,
                            isSearchable: false,
                            isMultiSelect: false,
                          );
                        },
                      )
                    else
                      ListenableBuilder(
                        listenable: TenantContext.instance,
                        builder: (context, _) {
                          final label = TenantContext
                                  .instance.activeCompany?.companyName
                                  .isNotEmpty ==
                              true
                              ? TenantContext.instance.activeCompany!.companyName
                              : 'Your company (from profile)';
                          return InputDecorator(
                            decoration: _fieldDecoration(context, 'Company'),
                            child: Text(
                              label,
                              style: FlutterFlowTheme.of(context).bodyLarge,
                            ),
                          );
                        },
                      ),
                    const SizedBox(height: 24.0),
                    FFButtonWidget(
                      onPressed: _model.isSubmitting ? null : _submitRegister,
                      text: _model.isSubmitting ? 'Creating…' : 'Create staff account',
                      options: FFButtonOptions(
                        width: double.infinity,
                        height: 52.0,
                        color: FlutterFlowTheme.of(context).primary,
                        textStyle: FlutterFlowTheme.of(context).titleSmall.override(
                              font: GoogleFonts.interTight(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                              color: Colors.white,
                              letterSpacing: 0.0,
                            ),
                        elevation: 2.0,
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                    ),
                    const SizedBox(height: 16.0),
                    Align(
                      alignment: Alignment.center,
                      child: TextButton(
                        onPressed: () {
                          if (Navigator.of(context).canPop()) {
                            context.pop();
                          } else {
                            context.go(LoginPageWidget.routePath);
                          }
                        },
                        child: Text(
                          'Cancel',
                          style: FlutterFlowTheme.of(context).bodyMedium.override(
                                font: GoogleFonts.inter(fontWeight: FontWeight.bold),
                                color: FlutterFlowTheme.of(context).primary,
                                letterSpacing: 0.0,
                              ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
