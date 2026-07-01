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
import '/l10n/tr.dart';

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

  void _openNoticeSheet() {
    if (_recipientRef == null) {
      return;
    }
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return _StaffNoticeSheet(
          recipientRef: _recipientRef!,
          parentContext: context,
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
          tooltip: tr(context, 'notice.tooltip'),
          onPressed: _openNoticeSheet,
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

class _StaffNoticeSheet extends StatefulWidget {
  const _StaffNoticeSheet({
    required this.recipientRef,
    required this.parentContext,
  });

  final DocumentReference recipientRef;
  final BuildContext parentContext;

  @override
  State<_StaffNoticeSheet> createState() => _StaffNoticeSheetState();
}

class _StaffNoticeSheetState extends State<_StaffNoticeSheet> {
  var _clearing = false;

  Future<void> _clearUnreadNotices(List<StaffNoticesRecord> notices) async {
    if (_clearing) {
      return;
    }
    setState(() => _clearing = true);
    try {
      final cleared = await markAllStaffNoticesRead(notices);
      if (!mounted) {
        return;
      }
      if (cleared > 0 && widget.parentContext.mounted) {
        ScaffoldMessenger.of(widget.parentContext).showSnackBar(
          SnackBar(content: Text(tr(context, 'notice.sheet.cleared'))),
        );
      }
    } catch (_) {
      if (mounted && widget.parentContext.mounted) {
        ScaffoldMessenger.of(widget.parentContext).showSnackBar(
          SnackBar(
            content: Text(tr(context, 'notice.sheet.clearFailed')),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _clearing = false);
      }
    }
  }

  Future<void> _openNotice(StaffNoticesRecord notice) async {
    Navigator.of(context).pop();
    await markStaffNoticeRead(notice.reference);
    if (!widget.parentContext.mounted) {
      return;
    }
    if (notice.hasOrderRef()) {
      widget.parentContext.pushNamed(
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
        notice.navTarget == StaffNoticeNavTarget.tomorrowPreparation) {
      await openDashboardFilteredOrderList(
        widget.parentContext,
        DashboardOrderListFilter.tomorrowDeliveryOrders,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    return Material(
      color: Colors.transparent,
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.75,
        ),
        decoration: BoxDecoration(
          color: theme.secondaryBackground,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: StreamBuilder<List<StaffNoticesRecord>>(
          stream: streamStaffNoticesForRecipient(widget.recipientRef),
          builder: (context, snapshot) {
            final notices = snapshot.data ?? const [];
            final unreadNotices = notices
                .where((notice) => isStaffNoticeUnread(notice))
                .toList(growable: false);

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 8, 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          tr(context, 'notice.sheet.title'),
                          style: theme.titleLarge.override(
                            font: GoogleFonts.interTight(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      if (unreadNotices.isNotEmpty)
                        TextButton(
                          onPressed: _clearing
                              ? null
                              : () => _clearUnreadNotices(notices),
                          child: Text(
                            _clearing
                                ? tr(context, 'notice.sheet.clearing')
                                : tr(context, 'notice.sheet.clear'),
                          ),
                        ),
                    ],
                  ),
                ),
                if (unreadNotices.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      tr(context, 'notice.sheet.empty'),
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
                        12 + MediaQuery.paddingOf(context).bottom,
                      ),
                      itemCount: unreadNotices.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 4),
                      itemBuilder: (context, index) {
                        final notice = unreadNotices[index];
                        return _NoticeTile(
                          notice: notice,
                          onTap: () => _openNotice(notice),
                        );
                      },
                    ),
                  ),
              ],
            );
          },
        ),
      ),
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
