import 'package:flutter/material.dart';

/// Phone portrait and small devices.
const double kCompactBreakpoint = 600;

/// Tablet portrait and medium layouts.
const double kMediumBreakpoint = 768;

/// Desktop table layout for order list rows.
const double kOrderListTableBreakpoint = 1100;

double responsivePagePadding(double width) {
  if (width < kCompactBreakpoint) {
    return 12.0;
  }
  if (width < kMediumBreakpoint) {
    return 16.0;
  }
  return 24.0;
}

class FormFieldLayout {
  const FormFieldLayout({
    required this.columnWidth,
    required this.columnSpacing,
    required this.runSpacing,
  });

  final double columnWidth;
  final double columnSpacing;
  final double runSpacing;
}

FormFieldLayout formFieldLayoutForWidth(double width) {
  if (width < kMediumBreakpoint) {
    return FormFieldLayout(
      columnWidth: width,
      columnSpacing: 0,
      runSpacing: 16,
    );
  }
  return FormFieldLayout(
    columnWidth: (width - 24) / 2,
    columnSpacing: 24,
    runSpacing: 16,
  );
}

/// Wraps form field columns so they stack on phone and sit two per row on desktop.
class ResponsiveFormFieldsWrap extends StatelessWidget {
  const ResponsiveFormFieldsWrap({
    super.key,
    required this.children,
  });

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final layout = formFieldLayoutForWidth(constraints.maxWidth);
        return Wrap(
          spacing: layout.columnSpacing,
          runSpacing: layout.runSpacing,
          alignment: WrapAlignment.start,
          crossAxisAlignment: WrapCrossAlignment.start,
          children: children
              .map(
                (child) => SizedBox(
                  width: layout.columnWidth,
                  child: child,
                ),
              )
              .toList(),
        );
      },
    );
  }
}
