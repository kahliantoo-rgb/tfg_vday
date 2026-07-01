import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '/auth/firebase_auth/auth_util.dart';
import '/auth/role_helpers.dart';
import '/auth/viewer_role_helpers.dart';
import '/backend/create_order_service.dart';
import '/backend/customer_helpers.dart';
import '/backend/customer_validation_display.dart';
import '/backend/customer_navigation_helpers.dart';
import '/backend/price_list_helpers.dart';
import '/backend/payment_method_helpers.dart';
import '/backend/schema/customers_record.dart';
import '/backend/schema/price_lists_record.dart';
import '/backend/tenant_context.dart';
import '/backend/tenant_query_helpers.dart';
import '/backend/user_query_helpers.dart';
import '/components/customer_birthday_picker.dart';
import '/components/home_nav_button.dart';
import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/index.dart';
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
  List<PriceListsRecord> _priceLists = const [];
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
      _model.selectedPriceListRef =
          customer.hasPriceListRef() ? customer.priceListRef : null;
      _model.birthday = customer.birthday;
      _priceLists = await queryTenantPriceListsRecordOnce();
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
        tr(context, 'customer.snack.requiredFields'),
        isError: true,
      );
      return;
    }

    final creditError = _model.validateCreditCustomer();
    if (creditError != null) {
      _showFormMessage(
        tr(context, 'customer.validation.creditTermsRequired'),
        isError: true,
      );
      return;
    }

    final canManageCredit =
        canManageCreditAndInvoices(currentViewerRole());
    if (_model.isCreditCustomer && !canManageCredit) {
      _showFormMessage(
        tr(context, 'customer.snack.noCreditPermission', params: {
          'action': tr(context, 'customer.snack.creditActionSet'),
        }),
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
        priceListRef:
            canManageCredit && _model.isCreditCustomer
                ? _model.selectedPriceListRef
                : null,
      );
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(tr(context, 'customer.snack.updated'))),
      );
      context.pop(true);
    } catch (error) {
      if (mounted) {
        final message = error is CustomerWriteException
            ? customerWriteErrorMessage(context, error.message)
            : tr(context, 'customer.snack.updateFailed',
                params: {'error': describeFirestoreError(error)});
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
          tr(context, 'customer.edit.title'),
          style: theme.headlineMedium.override(
            font: GoogleFonts.interTight(fontWeight: FontWeight.w600),
            color: Colors.white,
            fontSize: 22,
          ),
        ),
        actions: const [AppBarLanguageHomeActions()],
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
      return Center(child: Text(tr(context, 'customer.profile.notFound')));
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
                tr(context, 'customer.profile.loadError'),
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
                child: Text(tr(context, 'common.retry')),
              ),
            ],
          ),
        ),
      );
    }
    if (customer == null) {
      return Center(child: Text(tr(context, 'customer.profile.notFound')));
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
                  decoration: InputDecoration(
                    labelText: tr(context, 'customer.form.customerId'),
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
                validator: (value) => _model.validateName(value) != null
                    ? tr(context, 'customer.validation.nameRequired')
                    : null,
                decoration: InputDecoration(
                  labelText: tr(context, 'customer.form.name'),
                  hintText: tr(context, 'customer.form.nameHint'),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _model.phoneController,
                focusNode: _model.phoneFocusNode,
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.next,
                validator: (value) =>
                    validateCustomerPhoneInputLocalized(context, value),
                decoration: InputDecoration(
                  labelText: tr(context, 'customer.form.phone'),
                  hintText: tr(context, 'customer.form.phoneHint'),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _model.emailController,
                focusNode: _model.emailFocusNode,
                keyboardType: TextInputType.emailAddress,
                autofillHints: const [AutofillHints.email],
                validator: (value) =>
                    validateCustomerEmailInputLocalized(context, value),
                decoration: InputDecoration(
                  labelText: tr(context, 'customer.form.email'),
                  hintText: tr(context, 'customer.form.emailHint'),
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
                decoration: InputDecoration(
                  labelText: tr(context, 'customer.form.billingAddress'),
                  hintText: tr(context, 'customer.form.billingAddressHint'),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _model.uenController,
                focusNode: _model.uenFocusNode,
                textCapitalization: TextCapitalization.characters,
                validator: _model.validateUen,
                decoration: InputDecoration(
                  labelText: tr(context, 'customer.form.uen'),
                  hintText: tr(context, 'customer.form.uenHint'),
                ),
              ),
              const SizedBox(height: 16),
              if (canManageCredit) ...[
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(tr(context, 'customer.form.creditCustomer')),
                  subtitle: Text(
                    tr(context, 'customer.form.creditCustomerSubtitle'),
                  ),
                  value: _model.isCreditCustomer,
                  onChanged: (value) async {
                    if (!value) {
                      setState(() {
                        _model.isCreditCustomer = false;
                        _model.creditTerm = null;
                        _model.selectedPriceListRef = null;
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
                    title: Text(tr(context, 'customer.form.creditTerms')),
                    subtitle: Text(
                      _model.creditTerm ?? tr(context, 'common.notSet'),
                    ),
                    trailing: TextButton(
                      onPressed: () async {
                        final term =
                            await showCreditTermPickerDialog(context);
                        if (term != null && mounted) {
                          setState(() => _model.creditTerm = term);
                        }
                      },
                      child: Text(tr(context, 'common.change')),
                    ),
                  ),
                  DropdownButtonFormField<DocumentReference?>(
                    value: _model.selectedPriceListRef != null &&
                            _priceLists.any(
                              (list) =>
                                  list.reference.path ==
                                  _model.selectedPriceListRef!.path,
                            )
                        ? _model.selectedPriceListRef
                        : null,
                    decoration: InputDecoration(
                      labelText: loc(context,
                          en: 'Price list',
                          zh: '价目表',
                          ms: 'Senarai harga'),
                      border: const OutlineInputBorder(),
                    ),
                    items: [
                      DropdownMenuItem<DocumentReference?>(
                        value: null,
                        child: Text(loc(context,
                            en: 'None (catalog prices)',
                            zh: '无（使用目录价）',
                            ms: 'Tiada (harga katalog)')),
                      ),
                      ..._priceLists.map(
                        (list) => DropdownMenuItem<DocumentReference?>(
                          value: list.reference,
                          child: Text(priceListLabel(list)),
                        ),
                      ),
                    ],
                    onChanged: (value) {
                      setState(() => _model.selectedPriceListRef = value);
                    },
                  ),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton(
                      onPressed: () async {
                        await context.pushNamed(PriceListPageWidget.routeName);
                        if (!mounted) {
                          return;
                        }
                        final lists = await queryTenantPriceListsRecordOnce();
                        setState(() => _priceLists = lists);
                      },
                      child: Text(loc(context,
                          en: 'Manage price lists',
                          zh: '管理价目表',
                          ms: 'Urus senarai harga')),
                    ),
                  ),
                ],
              ],
              const SizedBox(height: 8),
              FFButtonWidget(
                onPressed: _model.saving ? null : _saveCustomer,
                text: _model.saving
                    ? tr(context, 'common.saving')
                    : tr(context, 'customer.form.saveChanges'),
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
