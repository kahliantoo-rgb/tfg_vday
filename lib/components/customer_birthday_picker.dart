import 'package:flutter/material.dart';

import '/backend/customer_helpers.dart';
import '/flutter_flow/flutter_flow_theme.dart';

class CustomerBirthdayPickerTile extends StatelessWidget {
  const CustomerBirthdayPickerTile({
    super.key,
    required this.birthday,
    required this.onChanged,
    this.labelText = 'Birthday (optional)',
  });

  final DateTime? birthday;
  final ValueChanged<DateTime?> onChanged;
  final String labelText;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    return InputDecorator(
      decoration: InputDecoration(
        labelText: labelText,
        border: const OutlineInputBorder(),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              formatCustomerBirthday(birthday),
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
            child: const Text('Pick date'),
          ),
          if (birthday != null)
            TextButton(
              onPressed: () => onChanged(null),
              child: const Text('Clear'),
            ),
        ],
      ),
    );
  }
}
