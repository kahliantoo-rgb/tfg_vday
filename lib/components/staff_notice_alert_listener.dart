import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '/auth/firebase_auth/auth_util.dart';
import '/backend/schema/staff_notices_record.dart';
import '/backend/schema/users_record.dart';
import '/backend/staff_notice_alert_service.dart';
import '/backend/staff_notice_helpers.dart';
import '/backend/user_query_helpers.dart';
import '/flutter_flow/nav/nav.dart';

/// Listens for new staff notices app-wide and triggers sound + popup alerts.
class StaffNoticeAlertListener extends StatefulWidget {
  const StaffNoticeAlertListener({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  State<StaffNoticeAlertListener> createState() =>
      _StaffNoticeAlertListenerState();
}

class _StaffNoticeAlertListenerState extends State<StaffNoticeAlertListener> {
  StreamSubscription<List<StaffNoticesRecord>>? _subscription;
  final Set<String> _seenNoticeIds = {};
  bool _seeded = false;
  String? _listeningUid;

  @override
  void initState() {
    super.initState();
    unawaited(StaffNoticeAlertService.instance.initialize());
    AppStateNotifier.instance.addListener(_onAuthChanged);
    unawaited(_restartListener());
  }

  void _onAuthChanged() {
    unawaited(_restartListener());
  }

  Future<void> _restartListener() async {
    if (!loggedIn) {
      if (_listeningUid != null) {
        await _subscription?.cancel();
        _subscription = null;
        _listeningUid = null;
        _seeded = false;
        _seenNoticeIds.clear();
      }
      return;
    }

    final profile = await resolveCurrentUserProfile();
    if (!mounted) {
      return;
    }
    final uid = currentUserUid.isNotEmpty
        ? currentUserUid
        : (profile?.uid.isNotEmpty == true ? profile!.uid : null);
    if (uid == null || uid.isEmpty) {
      return;
    }
    if (_listeningUid == uid) {
      return;
    }

    await _subscription?.cancel();
    _seeded = false;
    _seenNoticeIds.clear();
    _listeningUid = uid;

    final recipientRef = UsersRecord.collection.doc(uid);
    _subscription = streamStaffNoticesForRecipient(recipientRef).listen(
      _handleNotices,
      onError: (error) {
        debugPrint('Staff notice stream error: $error');
      },
    );
  }

  void _handleNotices(List<StaffNoticesRecord> notices) {
    if (!_seeded) {
      _seenNoticeIds.addAll(notices.map((notice) => notice.reference.id));
      _seeded = true;
      return;
    }

    final freshUnread = notices.where((notice) {
      if (!isStaffNoticeUnread(notice)) {
        return false;
      }
      return !_seenNoticeIds.contains(notice.reference.id);
    }).toList();

    if (freshUnread.isEmpty) {
      return;
    }

    freshUnread.sort((a, b) {
      final aTime = a.createdTime ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bTime = b.createdTime ?? DateTime.fromMillisecondsSinceEpoch(0);
      return aTime.compareTo(bTime);
    });

    for (final notice in freshUnread) {
      _seenNoticeIds.add(notice.reference.id);
      unawaited(StaffNoticeAlertService.instance.alertForNotice(notice));
    }
  }

  @override
  void dispose() {
    AppStateNotifier.instance.removeListener(_onAuthChanged);
    unawaited(_subscription?.cancel());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
