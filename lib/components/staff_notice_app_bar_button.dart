import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '/auth/firebase_auth/auth_util.dart';
import '/backend/dashboard_order_stats_helpers.dart';
import '/backend/operation_reminder_copy.dart';
import '/backend/schema/staff_notices_record.dart';
import '/backend/schema/users_record.dart';
import '/backend/staff_notice_helpers.dart';
import '/backend/user_query_helpers.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/index.dart';

/// Bell icon with unread badge and notice list for dashboard app bars.
class StaffNoticeAppBarButton extends StatefulWidget {
  const StaffNoticeAppBarButton({
    super.key,
    this.iconColor = Colors.white,
  });

  const StaffNoticeAppBarButton.onPrimary({super.key}) : iconColor = Colors.white;

  final Color iconColor;

  @override
  State<StaffNoticeAppBarButton> createState() =>
      _StaffNoticeAppBarButtonState();
}

class _StaffNoticeAppBarButtonState extends State<StaffNoticeAppBarButton> {
  DocumentReference? _recipientRef;

  @override
  void initState() {
    super.initState();
    _resolveRecipient();
  }

  Future<void> _resolveRecipient() async {
    if (!loggedIn) {
      return;
    }
    final profile = await resolveCurrentUserProfile();
    if (!mounted) {
      return;
    }
    final uid = currentUserUid.isNotEmpty
        ? currentUserUid
        : (profile?.uid.isNotEmpty == true ? profile!.uid : null);
    setState(() {
      _recipientRef =
          uid != null && uid.isNotEmpty ? UsersRecord.collection.doc(uid) : null;
    });
  }

  void _openNoticeSheet(List<StaffNoticesRecord> notices) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        final theme = FlutterFlowTheme.of(sheetContext);
        return Material(
          color: Colors.transparent,
          child: Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.sizeOf(sheetContext).height * 0.75,
            ),
            decoration: BoxDecoration(
              color: theme.secondaryBackground,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                  child: Text(
                    'Notices',
                    style: theme.titleLarge.override(
                      font: GoogleFonts.interTight(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
                if (notices.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      'No notices yet.',
                      style: theme.bodyMedium.override(
                        color: theme.secondaryText,
                      ),
                    ),
                  )
                else
                  Expanded(
                    child: ListView.separated(
                      padding: EdgeInsets.fromLTRB(
                        12,
                        0,
                        12,
                        12 + MediaQuery.paddingOf(sheetContext).bottom,
                      ),
                      itemCount: notices.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 4),
                      itemBuilder: (context, index) {
                        final notice = notices[index];
                        return _NoticeTile(
                          notice: notice,
                          onTap: () async {
                            Navigator.of(sheetContext).pop();
                            await markStaffNoticeRead(notice.reference);
                            if (!context.mounted) {
                              return;
                            }
                            if (notice.hasOrderRef()) {
                              context.pushNamed(
                                OrderDetailPageWidget.routeName,
                                queryParameters: {
                                  'orderRef': serializeParam(
                                    notice.orderRef,
                                    ParamType.DocumentReference,
                                  )!,
                                },
                                extra: {'orderRef': notice.orderRef},
                              );
                              return;
                            }
                            if (notice.hasNavTarget() &&
                                notice.navTarget ==
                                    StaffNoticeNavTarget.tomorrowPreparation) {
                              await openDashboardFilteredOrderList(
                                context,
                                DashboardOrderListFilter.tomorrowDeliveryOrders,
                              );
                            }
                          },
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_recipientRef == null) {
      return IconButton(
        onPressed: null,
        icon: Icon(Icons.notifications_outlined, color: widget.iconColor),
      );
    }

    return StreamBuilder<List<StaffNoticesRecord>>(
      stream: streamStaffNoticesForRecipient(_recipientRef!),
      builder: (context, snapshot) {
        final notices = snapshot.data ?? const [];
        final unread =
            notices.where((notice) => isStaffNoticeUnread(notice)).length;

        return IconButton(
          tooltip: 'Notices',
          onPressed: () => _openNoticeSheet(notices),
          icon: Badge(
            isLabelVisible: unread > 0,
            label: Text(unread > 99 ? '99+' : '$unread'),
            child: Icon(
              unread > 0
                  ? Icons.notifications_active_outlined
                  : Icons.notifications_outlined,
              color: widget.iconColor,
            ),
          ),
        );
      },
    );
  }
}

class _NoticeTile extends StatelessWidget {
  const _NoticeTile({
    required this.notice,
    required this.onTap,
  });

  final StaffNoticesRecord notice;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final unread = isStaffNoticeUnread(notice);
    return Card(
      color: unread
          ? theme.primary.withValues(alpha: 0.06)
          : theme.primaryBackground,
      child: ListTile(
        onTap: onTap,
        title: Text(
          staffNoticeTitle(notice, context),
          style: theme.titleSmall.override(
            font: GoogleFonts.interTight(fontWeight: FontWeight.w600),
          ),
        ),
        subtitle: Text(staffNoticeBody(notice, context)),
        isThreeLine: true,
        trailing: unread
            ? Icon(Icons.fiber_manual_record, size: 10, color: theme.primary)
            : null,
      ),
    );
  }
}
