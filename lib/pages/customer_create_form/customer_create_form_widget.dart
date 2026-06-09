import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '/backend/customer_helpers.dart';
import '/backend/tenant_query_helpers.dart';
import '/components/home_nav_button.dart';
import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/index.dart';
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

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => CustomerCreateFormModel());
    _model.nameController ??= TextEditingController();
    _model.nameFocusNode ??= FocusNode();
    _model.phoneController ??= TextEditingController();
    _model.phoneFocusNode ??= FocusNode();
    _model.billingAddressController ??= TextEditingController();
    _model.billingAddressFocusNode ??= FocusNode();
  }

  @override
  void dispose() {
    _model.dispose();
    super.dispose();
  }

  Future<void> _saveCustomer() async {
    if (_model.formKey.currentState == null ||
        !_model.formKey.currentState!.validate()) {
      return;
    }
    if (!ensureActiveCompanyForWrite(context)) {
      return;
    }

    setState(() => _model.saving = true);
    try {
      final ref = await createCustomerProfile(
        name: _model.nameController!.text,
        phone: _model.phoneController!.text,
        billingAddress: _model.billingAddressController!.text,
      );
      if (!mounted || ref == null) {
        return;
      }
      context.pushReplacementNamed(
        CustomerProfilePageWidget.routeName,
        queryParameters: {
          'customerRef': serializeParam(
            ref,
            ParamType.DocumentReference,
          )!,
        },
        extra: {'customerRef': ref},
      );
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to create customer: $error')),
        );
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
    return Scaffold(
      appBar: AppBar(
        backgroundColor: theme.primary,
        leading: FlutterFlowIconButton(
          borderRadius: 30,
          buttonSize: 60,
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 30),
          onPressed: () => context.pop(),
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
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _model.formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _model.nameController,
                  focusNode: _model.nameFocusNode,
                  textCapitalization: TextCapitalization.words,
                  validator: _model.validateName,
                  decoration: const InputDecoration(
                    labelText: 'Name',
                    hintText: 'Customer full name',
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _model.phoneController,
                  focusNode: _model.phoneFocusNode,
                  keyboardType: TextInputType.phone,
                  validator: _model.validatePhone,
                  decoration: const InputDecoration(
                    labelText: 'Phone',
                    hintText: '8-digit mobile number',
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _model.billingAddressController,
                  focusNode: _model.billingAddressFocusNode,
                  minLines: 2,
                  maxLines: 4,
                  validator: _model.validateBillingAddress,
                  decoration: const InputDecoration(
                    labelText: 'Billing Address',
                    hintText: 'Street, unit number, postal code',
                  ),
                ),
                const SizedBox(height: 24),
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
