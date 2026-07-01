import 'package:flutter/material.dart';

import '/backend/customer_helpers.dart';
import '/backend/customer_validation_display.dart';
import '/backend/schema/customers_record.dart';
import '/components/customer_birthday_picker.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';

class CustomerAutocompleteField extends StatelessWidget {
  const CustomerAutocompleteField({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.customers,
    required this.matches,
    required this.onChanged,
    required this.onCustomerSelected,
    this.validator,
    this.onCustomerCleared,
    this.hintText,
    this.onAddCustomer,
    this.onUseWalkInCustomer,
    this.walkInSelected = false,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final List<CustomersRecord> customers;
  final List<CustomersRecord> matches;
  final ValueChanged<String> onChanged;
  final ValueChanged<CustomersRecord> onCustomerSelected;
  final String? Function(String?)? validator;
  final VoidCallback? onCustomerCleared;
  final String? hintText;
  final VoidCallback? onAddCustomer;
  final VoidCallback? onUseWalkInCustomer;
  final bool walkInSelected;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final query = controller.text.trim();
    final showNoMatchActions = query.length >= 2 &&
        matches.isEmpty &&
        findCustomerByNameOrId(customers, query) == null &&
        (onAddCustomer != null || onUseWalkInCustomer != null);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextFormField(
          controller: controller,
          focusNode: focusNode,
          textCapitalization: TextCapitalization.words,
          textInputAction: TextInputAction.next,
          validator: validator,
          onChanged: onChanged,
          decoration: InputDecoration(
            isDense: true,
            hintText: hintText ?? tr(context, 'customer.autocomplete.hint'),
            suffixIcon: controller.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear, size: 18),
                    onPressed: () {
                      controller.clear();
                      onCustomerCleared?.call();
                      onChanged('');
                    },
                  )
                : null,
          ),
        ),
        if (walkInSelected)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              tr(context, 'customer.autocomplete.walkIn'),
              style: theme.labelSmall.override(color: theme.secondaryText),
            ),
          ),
        if (matches.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 6),
            decoration: BoxDecoration(
              color: theme.secondaryBackground,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: theme.alternate),
            ),
            child: Column(
              children: [
                for (final customer in matches)
                  ListTile(
                    dense: true,
                    title: Text(customer.name),
                    subtitle: Text(
                      [
                        if (customer.customerId.isNotEmpty) customer.customerId,
                        if (customer.phone.isNotEmpty) customer.phone,
                        if (customer.email.isNotEmpty) customer.email,
                      ].join(' · '),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    onTap: () => onCustomerSelected(customer),
                  ),
              ],
            ),
          ),
        if (showNoMatchActions)
          Container(
            margin: const EdgeInsets.only(top: 6),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.secondaryBackground,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: theme.alternate),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  tr(context, 'customer.autocomplete.noMatch'),
                  style: theme.labelMedium.override(color: theme.secondaryText),
                ),
                const SizedBox(height: 8),
                if (onAddCustomer != null)
                  OutlinedButton.icon(
                    onPressed: onAddCustomer,
                    icon: const Icon(Icons.person_add_outlined, size: 18),
                    label: Text(tr(context, 'customer.autocomplete.addCustomer')),
                  ),
                if (onAddCustomer != null && onUseWalkInCustomer != null)
                  const SizedBox(height: 8),
                if (onUseWalkInCustomer != null)
                  TextButton.icon(
                    onPressed: onUseWalkInCustomer,
                    icon: const Icon(Icons.person_outline, size: 18),
                    label: Text(tr(context, 'customer.autocomplete.useWalkIn')),
                  ),
              ],
            ),
          )
        else if (query.length >= 2 &&
            matches.isEmpty &&
            findCustomerByNameOrId(customers, query) == null)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              tr(context, 'customer.autocomplete.noMatch'),
              style: theme.labelSmall.override(color: theme.secondaryText),
            ),
          ),
      ],
    );
  }
}

void applyCustomerProfileToCreateOrderForm({
  required CustomersRecord customer,
  required TextEditingController clientNameController,
  required TextEditingController addressController,
}) {
  clientNameController.text = customer.name;
  if (customer.billingAddress.isNotEmpty &&
      addressController.text.trim().isEmpty) {
    addressController.text = customer.billingAddress;
  }
}

Future<CustomersRecord?> showQuickAddCustomerDialog(
  BuildContext context, {
  required String initialName,
}) async {
  final nameController = TextEditingController(text: initialName.trim());
  final phoneController = TextEditingController();
  final addressController = TextEditingController();
  final formKey = GlobalKey<FormState>();
  DateTime? birthday;

  final saved = await showDialog<bool>(
    context: context,
    builder: (dialogContext) {
      return StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: Text(tr(context, 'customer.autocomplete.quickAddTitle')),
            content: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: nameController,
                      textCapitalization: TextCapitalization.words,
                      decoration: InputDecoration(
                        labelText: tr(context, 'customer.autocomplete.quickAddName'),
                        border: const OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return tr(context, 'customer.validation.nameRequired');
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        labelText: tr(context, 'customer.autocomplete.quickAddPhone'),
                        border: const OutlineInputBorder(),
                      ),
                      validator: (value) =>
                          validateCustomerPhoneInputLocalized(context, value),
                    ),
                    const SizedBox(height: 12),
                    CustomerBirthdayPickerTile(
                      birthday: birthday,
                      onChanged: (value) {
                        setDialogState(() => birthday = value);
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: addressController,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: InputDecoration(
                        labelText: tr(context, 'customer.form.billingAddress'),
                        border: const OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(false),
                child: Text(tr(context, 'common.cancel')),
              ),
              FilledButton(
                onPressed: () {
                  if (formKey.currentState?.validate() ?? false) {
                    Navigator.of(dialogContext).pop(true);
                  }
                },
                child: Text(tr(context, 'common.save')),
              ),
            ],
          );
        },
      );
    },
  );

  if (saved != true) {
    nameController.dispose();
    phoneController.dispose();
    addressController.dispose();
    return null;
  }

  try {
    final result = await createCustomerProfile(
      name: nameController.text,
      phone: phoneController.text,
      billingAddress: addressController.text,
      birthday: birthday,
    );
    if (result == null) {
      return null;
    }
    return CustomersRecord.getDocumentOnce(result.reference);
  } finally {
    nameController.dispose();
    phoneController.dispose();
    addressController.dispose();
  }
}
