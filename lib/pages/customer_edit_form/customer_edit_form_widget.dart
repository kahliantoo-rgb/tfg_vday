import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '/auth/firebase_auth/auth_util.dart';
import '/auth/role_helpers.dart';
import '/auth/viewer_role_helpers.dart';
import '/backend/create_order_service.dart';
import '/backend/customer_helpers.dart';
import '/backend/customer_navigation_helpers.dart';
import '/backend/payment_method_helpers.dart';
import '/backend/schema/customers_record.dart';
import '/backend/tenant_context.dart';
import '/backend/user_query_helpers.dart';
import '/components/customer_birthday_picker.dart';
import '/components/home_nav_button.dart';
import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import 'customer_edit_form_model.dart';
export 'customer_edit_form_model.dart';

class CustomerEditFormWidget extends StatefulWidget {
  const CustomerEditFormWidget({
    super.key,
    required this.customerId,
  });

  final String customerId;

  static String routeName = 'CustomerEditForm';
  static String routePath = '/customerEditForm';

  @override
  State<CustomerEditFormWidget> createState() => _CustomerEditFormWidgetState();
}

class _CustomerEditFormWidgetState extends State<CustomerEditFormWidget> {
  late CustomerEditFormModel _model;
  final _scrollController = ScrollController();
  CustomersRecord? _customer;
  bool _loading = true;
  String? _loadError;
  String? _formMessage;
  bool _formMessageIsError = true;

  DocumentReference get _customerRef =>
      CustomersRecord.collection.doc(widget.customerId);

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => CustomerEditFormModel());
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
    WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrapAndLoad());
  }

  Future<void> _bootstrapAndLoad() async {
    if (loggedIn) {
      final profile = await resolveCurrentUserProfile();
      await TenantContext.instance.initialize(profile);
    }
    await _loadCustomer();
  }

  Future<void> _loadCustomer() async {
    setState(() {
      _loading = true;
      _loadError = null;
    });
    try {
      final customer = await CustomersRecord.getDocumentOnce(_customerRef);
      if (!mounted) {
        return;
      }
      _model.nameController!.text = customer.name;
      _model.phoneController!.text = customer.phone;
      _model.emailController!.text = customer.email;
      _model.billingAddressController!.text = customer.billingAddress;
      _model.uenController!.text = customer.uen;
      _model.isCreditCustomer = customer.isCreditCustomer;
      _model.creditTerm =
          customer.creditTerm.isEmpty ? null : customer.creditTerm;
      _model.birthday = customer.birthday;
      setState(() {
        _customer = customer;
        _loading = false;
      });
    } catch (error) {
      if (mounted) {
        setState(() {
          _loading = false;
          _loadError = describeFirestoreError(error);
        });
      }
    }
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

  Future<void> _saveCustomer() async {
    final customer = _customer;
    if (customer == null) {
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() => _formMessage = null);

    if (_model.formKey.currentState == null ||
        !_model.formKey.currentState!.validate()) {
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
        'Only Super Admin, Admin, Manager, or Account can set credit customers.',
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
      _showFormMessage(tenantBlocked, isError: true);
      return;
    }

    setState(() => _model.saving = true);
    try {
      await updateCustomerProfile(
        customer: customer,
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Customer profile updated')),
      );
      context.pop(true);
    } catch (error) {
      if (mounted) {
        final message = error is CustomerWriteException
            ? error.message
            : 'Failed to update customer: ${describeFirestoreError(error)}';
        _showFormMessage(message, isError: true);
      }
    } finally {
      if (mounted) {
        setState(() => _model.saving = false);
      }
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _model.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final canManageCredit =
        canManageCreditAndInvoices(currentViewerRole());
    final customer = _customer;

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
          'Edit Customer',
          style: theme.headlineMedium.override(
            font: GoogleFonts.interTight(fontWeight: FontWeight.w600),
            color: Colors.white,
            fontSize: 22,
          ),
        ),
        actions: const [HomeNavIconButton()],
        centerTitle: true,
      ),
      body: _buildBody(theme, canManageCredit, customer),
    );
  }

  Widget _buildBody(
    FlutterFlowTheme theme,
    bool canManageCredit,
    CustomersRecord? customer,
  ) {
    if (widget.customerId.isEmpty) {
      return const Center(child: Text('Customer not found'));
    }
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_loadError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Could not load customer.',
                style: theme.titleMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                _loadError!,
                style: theme.bodyMedium.override(color: theme.secondaryText),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: _bootstrapAndLoad,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }
    if (customer == null) {
      return const Center(child: Text('Customer not found'));
    }

    return SafeArea(
      child: SingleChildScrollView(
        controller: _scrollController,
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _model.formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
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
              if (customer.customerId.isNotEmpty) ...[
                InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Customer ID',
                  ),
                  child: Text(
                    customer.customerId,
                    style: theme.titleMedium.override(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
              TextFormField(
                controller: _model.nameController,
                focusNode: _model.nameFocusNode,
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
                    subtitle: Text(_model.creditTerm ?? 'Not set'),
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
              const SizedBox(height: 8),
              FFButtonWidget(
                onPressed: _model.saving ? null : _saveCustomer,
                text: _model.saving ? 'Saving...' : 'Save changes',
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
    );
  }
}
