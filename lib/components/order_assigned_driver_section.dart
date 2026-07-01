import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '/backend/backend.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/l10n/tr.dart';

/// Shows driver assignment status on order detail / summary screens.
class OrderAssignedDriverSection extends StatelessWidget {
  const OrderAssignedDriverSection({
    super.key,
    required this.order,
  });

  final OrdersRecord order;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final driverRef = order.assignedDriver;

    if (driverRef == null) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: StreamBuilder<UsersRecord>(
        stream: UsersRecord.getDocument(driverRef),
        builder: (context, snapshot) {
          final driverName = snapshot.hasData
              ? _driverDisplayName(snapshot.data!)
              : null;

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  tr(context, 'order.driver.assignedDriver'),
                  style: theme.bodyMedium.override(
                    font: GoogleFonts.inter(fontWeight: FontWeight.w500),
                  ),
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: theme.success.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: theme.success.withValues(alpha: 0.35),
                      ),
                    ),
                    child: Text(
                      tr(context, 'order.driver.assigned'),
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: theme.success,
                      ),
                    ),
                  ),
                  if (driverName != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      driverName,
                      style: theme.bodyMedium.override(
                        font: GoogleFonts.inter(),
                        color: theme.secondaryText,
                      ),
                    ),
                  ] else if (!snapshot.hasData) ...[
                    const SizedBox(height: 4),
                    SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: theme.primary,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  String _driverDisplayName(UsersRecord driver) {
    if (driver.name.isNotEmpty) {
      return driver.name;
    }
    if (driver.email.isNotEmpty) {
      return driver.email;
    }
    return driver.reference.id;
  }
}
