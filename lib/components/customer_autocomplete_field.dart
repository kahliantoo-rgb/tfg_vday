import 'package:flutter/material.dart';

import '/backend/customer_helpers.dart';
import '/backend/schema/customers_record.dart';
import '/flutter_flow/flutter_flow_theme.dart';

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
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final List<CustomersRecord> customers;
  final List<CustomersRecord> matches;
  final ValueChanged<String> onChanged;
  final ValueChanged<CustomersRecord> onCustomerSelected;
  final String? Function(String?)? validator;
  final VoidCallback? onCustomerCleared;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
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
            hintText: 'Enter full name',
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
                        if (customer.phone.isNotEmpty) customer.phone,
                        if (customer.billingAddress.isNotEmpty)
                          customer.billingAddress,
                      ].join(' · '),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    onTap: () => onCustomerSelected(customer),
                  ),
              ],
            ),
          ),
        if (controller.text.trim().length >= 2 &&
            matches.isEmpty &&
            findExactCustomerByName(customers, controller.text) == null)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              'No matching customer profile',
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
