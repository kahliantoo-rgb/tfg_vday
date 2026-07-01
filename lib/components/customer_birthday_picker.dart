import 'package:flutter/material.dart';

import '/backend/customer_helpers.dart';
import '/backend/customer_validation_display.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';

class CustomerBirthdayPickerTile extends StatelessWidget {
  const CustomerBirthdayPickerTile({
    super.key,
    required this.birthday,
    required this.onChanged,
    this.labelText,
  });

  final DateTime? birthday;
  final ValueChanged<DateTime?> onChanged;
  final String? labelText;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    return InputDecorator(
      decoration: InputDecoration(
        labelText: labelText ?? tr(context, 'customer.birthday.label'),
        border: const OutlineInputBorder(),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              formatCustomerBirthdayLocalized(context, birthday),
              style: theme.bodyMedium.override(
                color: birthday == null ? theme.secondaryText : theme.primaryText,
              ),
            ),
          ),
          TextButton(
            onPressed: () async {
              final picked = await pickCustomerBirthday(
                context,
                initial: birthday,
              );
              if (picked != null) {
                onChanged(picked);
              }
            },
            child: Text(tr(context, 'customer.birthday.pickDate')),
          ),
          if (birthday != null)
            TextButton(
              onPressed: () => onChanged(null),
              child: Text(tr(context, 'common.clear')),
            ),
        ],
      ),
    );
  }
}
