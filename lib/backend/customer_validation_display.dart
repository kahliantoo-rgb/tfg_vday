import 'package:flutter/material.dart';

import '/backend/customer_helpers.dart';
import '/backend/invoice_list_helpers.dart';
import '/l10n/tr.dart';

String customerOrderPaymentFilterLabel(
  BuildContext context,
  CustomerOrderPaymentFilter filter,
) {
  switch (filter) {
    case CustomerOrderPaymentFilter.all:
      return tr(context, 'common.all');
    case CustomerOrderPaymentFilter.unpaid:
      return tr(context, 'common.unpaid');
    case CustomerOrderPaymentFilter.paid:
      return tr(context, 'common.paid');
  }
}

String? validateCustomerPhoneInputLocalized(
  BuildContext context,
  String? value, {
  bool required = true,
}) {
  if (value == null || value.trim().isEmpty) {
    return required ? tr(context, 'customer.validation.phoneRequired') : null;
  }
  final count = customerPhoneDigitCount(value);
  if (count < kCustomerPhoneMinDigits) {
    return tr(context, 'customer.validation.phoneMinDigits',
        params: {'min': '$kCustomerPhoneMinDigits'});
  }
  if (count > kCustomerPhoneMaxDigits) {
    return tr(context, 'customer.validation.phoneTooLong',
        params: {'max': '$kCustomerPhoneMaxDigits'});
  }
  return null;
}

String? validateCustomerEmailInputLocalized(BuildContext context, String? value) {
  if (value == null || value.trim().isEmpty) {
    return null;
  }
  final trimmed = value.trim();
  if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(trimmed)) {
    return tr(context, 'customer.validation.emailInvalid');
  }
  return null;
}

String formatCustomerBirthdayLocalized(BuildContext context, DateTime? birthday) {
  if (birthday == null) {
    return tr(context, 'common.notSet');
  }
  return formatCustomerBirthday(birthday);
}

String customerWriteErrorMessage(BuildContext context, String message) {
  switch (message) {
    case kCustomerDuplicateNameError:
      return tr(context, 'customer.validation.duplicateName');
    case kCustomerDuplicatePhoneError:
      return tr(context, 'customer.validation.duplicatePhone');
    default:
      return message;
  }
}
