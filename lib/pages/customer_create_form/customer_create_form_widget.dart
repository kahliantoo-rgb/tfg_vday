import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '/auth/firebase_auth/auth_util.dart';
import '/auth/role_helpers.dart';
import '/auth/viewer_role_helpers.dart';
import '/backend/create_order_service.dart';
import '/backend/customer_helpers.dart';
import '/backend/customer_navigation_helpers.dart';
import '/backend/payment_method_helpers.dart';
import '/pages/customer_profile_page/customer_profile_page_widget.dart';
import '/backend/tenant_context.dart';
import '/backend/user_query_helpers.dart';
import '/components/customer_birthday_picker.dart';
import '/components/customer_import_button.dart';
import '/components/home_nav_button.dart';
import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import 'customer_create_form_model.dart';
export 'customer_create_form_model.dart';

class CustomerCreateFormWidget extends StatefulWidget {
  const CustomerCreateFormWidget({super.key});

  static String routeName = 'CustomerCreateForm';
  static String routePath = '/customerCreateForm';

  @override
  State<CustomerCreateFormWidget> createState() =>
      _CustomerCreateFormWidgetState();
}

class _CustomerCreateFormWidgetState extends State<CustomerCreateFormWidget> {
  late CustomerCreateFormModel _model;
  final _scrollController = ScrollController();
  String? _formMessage;
  bool _formMessageIsError = true;
  String? _tenantBlockedMessage;

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => CustomerCreateFormModel());
    _model.nameController ??= TextEditingController();
    _model.nameFocusNode ??= FocusNode();
    _model.phoneController ??= TextEditingController();
    _model.phoneFocusNode ??= FocusNode();
    _model.emailController ??= TextEditingController();
    _model.emailFocusNode ??= FocusNode();
    _model.billingAddressController ??= TextEditingController();
    _model.billingAddressFocusNode ??= FocusNode();
    _model.uenController ??= TextEditingController();
    _model.uenFocusNode ??= FocusNode();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (loggedIn) {
        final profile = await resolveCurrentUserProfile();
        await TenantContext.instance.initialize(profile);
        AppStateNotifier.instance.syncUserRole(profile?.role);
      }
      if (mounted) {
        final blocked =
            await TenantContext.instance.ensureReadyForTenantWrite();
        setState(() => _tenantBlockedMessage = blocked);
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _model.dispose();
    super.dispose();
  }

  void _showFormMessage(String message, {required bool isError}) {
    setState(() {
      _formMessage = message;
      _formMessageIsError = isError;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _scrollToField(FocusNode? focusNode) async {
    if (focusNode == null || !focusNode.hasFocus) {
      focusNode?.requestFocus();
    }
    await Future<void>.delayed(const Duration(milliseconds: 100));
    if (!mounted) {
      return;
    }
    final context = focusNode?.context;
    if (context != null) {
      await Scrollable.ensureVisible(
        context,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        alignment: 0.2,
      );
    } else if (_scrollController.hasClients) {
      await _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _saveCustomer() async {
    FocusScope.of(context).unfocus();
    setState(() => _formMessage = null);

    if (_model.formKey.currentState == null ||
        !_model.formKey.currentState!.validate()) {
      await _scrollToField(_model.nameFocusNode);
      _showFormMessage(
        'Name and phone are required. Check the highlighted fields.',
        isError: true,
      );
      return;
    }

    final creditError = _model.validateCreditCustomer();
    if (creditError != null) {
      _showFormMessage(creditError, isError: true);
      return;
    }

    final canManageCredit =
        canManageCreditAndInvoices(currentViewerRole());
    if (_model.isCreditCustomer && !canManageCredit) {
      _showFormMessage(
        'Only Super Admin, Admin, Manager, or Account can create credit customers.',
        isError: true,
      );
      return;
    }

    final tenantBlocked =
        await TenantContext.instance.ensureReadyForTenantWrite();
    if (!mounted) {
      return;
    }
    if (tenantBlocked != null) {
      setState(() => _tenantBlockedMessage = tenantBlocked);
      _showFormMessage(tenantBlocked, isError: true);
      return;
    }
    setState(() => _tenantBlockedMessage = null);

    setState(() => _model.saving = true);
    try {
      final result = await createCustomerProfile(
        name: _model.nameController!.text,
        phone: _model.phoneController!.text,
        email: _model.emailController!.text,
        billingAddress: _model.billingAddressController!.text,
        uen: _model.uenController!.text,
        birthday: _model.birthday,
        isCreditCustomer: canManageCredit && _model.isCreditCustomer,
        creditTerm: canManageCredit ? _model.creditTerm : null,
      );
      if (!mounted) {
        return;
      }
      if (result == null) {
        _showFormMessage(
          'Customer was not saved. Please try again.',
          isError: true,
        );
        return;
      }
      if (!mounted) {
        return;
      }
      markPendingCreatedCustomer(result.reference);
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Customer created: ${_model.nameController!.text.trim()} '
            '(${result.customerId})',
          ),
        ),
      );
      context.go(
        CustomerProfilePageWidget.locationForId(result.reference.id),
      );
    } catch (error) {
      if (mounted) {
        final message = error is CustomerWriteException
            ? error.message
            : 'Failed to create customer: ${describeFirestoreError(error)}';
        _showFormMessage(message, isError: true);
      }
    } finally {
      if (mounted) {
        setState(() => _model.saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final canManageCredit =
        canManageCreditAndInvoices(currentViewerRole());
    return Scaffold(
      backgroundColor: theme.primaryBackground,
      appBar: AppBar(
        backgroundColor: theme.primary,
        leading: FlutterFlowIconButton(
          borderRadius: 30,
          buttonSize: 60,
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 30),
          onPressed: () => exitCustomerFlow(context),
        ),
        title: Text(
          'Create Customer',
          style: theme.headlineMedium.override(
            font: GoogleFonts.interTight(fontWeight: FontWeight.w600),
            color: Colors.white,
            fontSize: 22,
          ),
        ),
        actions: const [HomeNavIconButton()],
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          controller: _scrollController,
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _model.formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_tenantBlockedMessage != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: theme.error.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: theme.error),
                    ),
                    child: Text(
                      _tenantBlockedMessage!,
                      style: theme.bodyMedium.override(color: theme.error),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                if (_formMessage != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: (_formMessageIsError ? theme.error : theme.success)
                          .withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: _formMessageIsError ? theme.error : theme.success,
                      ),
                    ),
                    child: Text(
                      _formMessage!,
                      style: theme.bodyMedium.override(
                        color: _formMessageIsError ? theme.error : theme.success,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                TextFormField(
                  controller: _model.nameController,
                  focusNode: _model.nameFocusNode,
                  autofocus: true,
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.next,
                  validator: _model.validateName,
                  decoration: const InputDecoration(
                    labelText: 'Name *',
                    hintText: 'Customer full name',
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _model.phoneController,
                  focusNode: _model.phoneFocusNode,
                  keyboardType: TextInputType.phone,
                  textInputAction: TextInputAction.next,
                  validator: _model.validatePhone,
                  decoration: const InputDecoration(
                    labelText: 'Phone *',
                    hintText: 'Local or international (e.g. 91234567, +65…, +1…)',
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _model.emailController,
                  focusNode: _model.emailFocusNode,
                  keyboardType: TextInputType.emailAddress,
                  autofillHints: const [AutofillHints.email],
                  validator: _model.validateEmail,
                  decoration: const InputDecoration(
                    labelText: 'Email (optional)',
                    hintText: 'customer@example.com',
                  ),
                ),
                const SizedBox(height: 16),
                CustomerBirthdayPickerTile(
                  birthday: _model.birthday,
                  onChanged: (value) {
                    setState(() => _model.birthday = value);
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _model.billingAddressController,
                  focusNode: _model.billingAddressFocusNode,
                  minLines: 2,
                  maxLines: 4,
                  validator: _model.validateBillingAddress,
                  decoration: const InputDecoration(
                    labelText: 'Billing address (optional)',
                    hintText: 'Street, unit number, postal code',
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _model.uenController,
                  focusNode: _model.uenFocusNode,
                  textCapitalization: TextCapitalization.characters,
                  validator: _model.validateUen,
                  decoration: const InputDecoration(
                    labelText: 'UEN (optional)',
                    hintText: 'Business registration number',
                  ),
                ),
                const SizedBox(height: 16),
                if (canManageCredit) ...[
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Credit customer'),
                    subtitle: const Text(
                      'Enable credit terms and consolidated invoicing',
                    ),
                    value: _model.isCreditCustomer,
                    onChanged: (value) async {
                      if (!value) {
                        setState(() {
                          _model.isCreditCustomer = false;
                          _model.creditTerm = null;
                        });
                        return;
                      }
                      final term = await showCreditTermPickerDialog(context);
                      if (!mounted) {
                        return;
                      }
                      if (term == null) {
                        return;
                      }
                      setState(() {
                        _model.isCreditCustomer = true;
                        _model.creditTerm = term;
                      });
                    },
                  ),
                  if (_model.isCreditCustomer) ...[
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Credit terms'),
                      subtitle: Text(
                        _model.creditTerm ?? 'Not set',
                      ),
                      trailing: TextButton(
                        onPressed: () async {
                          final term =
                              await showCreditTermPickerDialog(context);
                          if (term != null && mounted) {
                            setState(() => _model.creditTerm = term);
                          }
                        },
                        child: const Text('Change'),
                      ),
                    ),
                  ],
                ],
                CustomerImportButton(
                  allowCreditCustomers: canManageCredit,
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 8, bottom: 16),
                  child: Text(
                    'Upload .xlsx or .csv with columns: Name, Phone, Email, '
                    'Billing address, UEN, Credit customer, Credit term.',
                    style: theme.bodySmall.override(
                      fontFamily: 'Outfit',
                      color: const Color(0xFF606A85),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                FFButtonWidget(
                  onPressed: _model.saving ? null : _saveCustomer,
                  text: _model.saving ? 'Saving...' : 'Create Customer',
                  options: FFButtonOptions(
                    width: double.infinity,
                    height: 48,
                    color: theme.primary,
                    textStyle: theme.titleMedium.override(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                    borderRadius: BorderRadius.circular(8),
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
