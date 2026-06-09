import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '/auth/firebase_auth/auth_util.dart';
import '/auth/role_helpers.dart';
import '/backend/audit_log_helpers.dart';
import '/backend/audit_log_service.dart';
import '/backend/daily_sales_report_service.dart';
import '/backend/schema/audit_logs_record.dart';
import '/backend/tenant_context.dart';
import '/backend/tenant_query_helpers.dart';
import '/backend/user_query_helpers.dart';
import '/components/home_nav_button.dart';
import '/flutter_flow/flutter_flow_drop_down.dart';
import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/form_field_controller.dart';
import 'audit_log_page_model.dart';
export 'audit_log_page_model.dart';

class AuditLogPageWidget extends StatefulWidget {
  const AuditLogPageWidget({super.key});

  static String routeName = 'AuditLogPage';
  static String routePath = '/auditLogPage';

  @override
  State<AuditLogPageWidget> createState() => _AuditLogPageWidgetState();
}

class _AuditLogPageWidgetState extends State<AuditLogPageWidget> {
  late AuditLogPageModel _model;
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  final _searchController = TextEditingController();
  final _dateFormat = DateFormat('d MMM yyyy, HH:mm');

  List<AuditLogsRecord> _allLogs = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => AuditLogPageModel());
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (loggedIn) {
        final profile = await resolveCurrentUserProfile();
        await TenantContext.instance.initialize(profile);
      }
      await _loadLogs();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _model.dispose();
    super.dispose();
  }

  Future<void> _loadLogs() async {
    final role = AppStateNotifier.instance.userRole;
    if (!canViewAuditLog(role)) {
      if (!mounted) {
        return;
      }
      setState(() {
        _loading = false;
        _allLogs = const [];
        _error = 'You do not have permission to view audit logs.';
      });
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final logs = await queryTenantAuditLogsRecordOnce(
        queryBuilder: (query) => query.orderBy('createdAt', descending: true),
        limit: 500,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _allLogs = logs;
        _loading = false;
      });
    } on FirebaseException catch (e) {
      if (!mounted) {
        return;
      }
      if (e.code == 'failed-precondition') {
        setState(() {
          _loading = false;
          _error =
              'Audit log index is still building in Firebase. '
              'Wait a few minutes and tap refresh, or create the index from '
              'the link in the browser console.';
        });
        return;
      }
      setState(() {
        _loading = false;
        _error = 'Failed to load audit logs.';
      });
    } catch (e) {
      if (!mounted) {
        return;
      }
      setState(() {
        _loading = false;
        _error = 'Failed to load audit logs.';
      });
    }
  }

  List<AuditLogsRecord> get _filteredLogs {
    final query = _model.searchQuery.trim().toLowerCase();
    final start = _model.startDate != null
        ? calendarDay(_model.startDate!)
        : null;
    final end = _model.endDate != null
        ? calendarDay(_model.endDate!).add(const Duration(days: 1))
        : null;

    return _allLogs.where((log) {
      if (_model.actionFilter != null &&
          _model.actionFilter!.isNotEmpty &&
          log.action != _model.actionFilter) {
        return false;
      }
      if (_model.entityTypeFilter != null &&
          _model.entityTypeFilter!.isNotEmpty &&
          log.entityType != _model.entityTypeFilter) {
        return false;
      }
      if (_model.userNameFilter != null &&
          _model.userNameFilter!.isNotEmpty &&
          log.userName != _model.userNameFilter) {
        return false;
      }
      if (start != null || end != null) {
        final created = log.createdAt;
        if (created == null) {
          return false;
        }
        if (start != null && created.isBefore(start)) {
          return false;
        }
        if (end != null && !created.isBefore(end)) {
          return false;
        }
      }
      if (query.isNotEmpty) {
        final haystack = [
          log.entityId,
          log.entityLabel,
          log.description,
        ].join(' ').toLowerCase();
        if (!haystack.contains(query)) {
          return false;
        }
      }
      return true;
    }).toList(growable: false);
  }

  List<String> get _userNameOptions {
    final names = _allLogs
        .map((log) => log.userName)
        .where((name) => name.isNotEmpty)
        .toSet()
        .toList()
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    return names;
  }

  Future<void> _pickDateRange() async {
    final now = DateTime.now();
    final initialStart = _model.startDate ?? now.subtract(const Duration(days: 7));
    final initialEnd = _model.endDate ?? now;

    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: now,
      initialDateRange: DateTimeRange(start: initialStart, end: initialEnd),
    );
    if (picked == null) {
      return;
    }
    setState(() {
      _model.startDate = calendarDay(picked.start);
      _model.endDate = calendarDay(picked.end);
    });
  }

  void _clearDateRange() {
    setState(() {
      _model.startDate = null;
      _model.endDate = null;
    });
  }

  void _showDetailDialog(AuditLogsRecord log) {
    final theme = FlutterFlowTheme.of(context);
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          auditActionLabel(log.action),
          style: theme.titleMedium.override(
            font: GoogleFonts.interTight(fontWeight: FontWeight.w700),
          ),
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              _detailRow('Time', _formatTime(log.createdAt)),
              _detailRow('User', log.userName),
              _detailRow('Role', log.userRole),
              _detailRow('Entity', '${log.entityType} · ${log.entityLabel}'),
              if (log.description.isNotEmpty)
                _detailRow('Description', log.description),
              const SizedBox(height: 12),
              Text(
                'Previous value',
                style: theme.labelLarge.override(
                  font: GoogleFonts.interTight(fontWeight: FontWeight.w700),
                ),
              ),
              const SizedBox(height: 4),
              _valueBlock(theme, log.oldValue, log.beforeValue),
              const SizedBox(height: 12),
              Text(
                'New value',
                style: theme.labelLarge.override(
                  font: GoogleFonts.interTight(fontWeight: FontWeight.w700),
                ),
              ),
              const SizedBox(height: 4),
              _valueBlock(theme, log.newValue, log.afterValue),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    final theme = FlutterFlowTheme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 96,
            child: Text(
              label,
              style: theme.labelMedium.override(color: theme.secondaryText),
            ),
          ),
          Expanded(
            child: Text(
              value.isNotEmpty ? value : '—',
              style: theme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }

  Widget _valueBlock(
    FlutterFlowTheme theme,
    Map<String, dynamic>? mapValue,
    String legacyValue,
  ) {
    String text;
    if (mapValue != null && mapValue.isNotEmpty) {
      text = const JsonEncoder.withIndent('  ').convert(mapValue);
    } else if (legacyValue.isNotEmpty) {
      text = legacyValue;
    } else {
      text = '—';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: theme.primaryBackground,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: theme.alternate),
      ),
      child: SelectableText(
        text,
        style: theme.bodySmall.override(
          font: GoogleFonts.robotoMono(fontSize: 12),
        ),
      ),
    );
  }

  String _formatTime(DateTime? time) {
    if (time == null) {
      return '—';
    }
    return _dateFormat.format(time);
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final logs = _filteredLogs;
    final dateLabel = _model.startDate != null && _model.endDate != null
        ? '${DateFormat('d MMM').format(_model.startDate!)} – '
            '${DateFormat('d MMM yyyy').format(_model.endDate!)}'
        : 'All dates';

    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
        FocusManager.instance.primaryFocus?.unfocus();
      },
      child: Scaffold(
        key: _scaffoldKey,
        backgroundColor: theme.primaryBackground,
        appBar: AppBar(
          backgroundColor: theme.secondaryBackground,
          automaticallyImplyLeading: false,
          title: Text(
            'Audit Log',
            style: theme.headlineMedium.override(
              font: GoogleFonts.interTight(fontWeight: FontWeight.w600),
            ),
          ),
          actions: [
            FlutterFlowIconButton(
              borderRadius: 20,
              buttonSize: 40,
              icon: Icon(Icons.refresh, color: theme.primaryText, size: 24),
              onPressed: _loading ? null : _loadLogs,
            ),
            const HomeNavIconButton(),
          ],
          elevation: 1,
        ),
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: theme.secondaryBackground,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: theme.alternate),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText:
                              'Search entity ID, label, or description',
                          prefixIcon: const Icon(Icons.search),
                          filled: true,
                          fillColor: theme.primaryBackground,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onChanged: (value) => setState(
                          () => _model.searchQuery = value,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: FlutterFlowDropDown<String>(
                              controller: _model.actionFilterController ??=
                                  FormFieldController<String>(null),
                              options: const ['', ...AuditLogAction.all],
                              optionLabels: [
                                'All actions',
                                ...AuditLogAction.all.map(auditActionLabel),
                              ],
                              onChanged: (val) => setState(
                                () => _model.actionFilter =
                                    val == null || val.isEmpty ? null : val,
                              ),
                              width: double.infinity,
                              height: 44,
                              textStyle: theme.bodyMedium,
                              hintText: 'Action',
                              icon: Icon(
                                Icons.keyboard_arrow_down_rounded,
                                color: theme.primaryText,
                              ),
                              fillColor: theme.primaryBackground,
                              elevation: 0,
                              borderColor: theme.alternate,
                              borderWidth: 1,
                              borderRadius: 8,
                              margin: EdgeInsets.zero,
                              hidesUnderline: true,
                              isSearchable: false,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: FlutterFlowDropDown<String>(
                              controller: _model.entityTypeFilterController ??=
                                  FormFieldController<String>(null),
                              options: const [
                                '',
                                AuditLogEntityType.order,
                                AuditLogEntityType.staff,
                                AuditLogEntityType.report,
                                AuditLogEntityType.receipt,
                              ],
                              optionLabels: const [
                                'All entity types',
                                'Order',
                                'Staff',
                                'Report',
                                'Receipt',
                              ],
                              onChanged: (val) => setState(
                                () => _model.entityTypeFilter =
                                    val == null || val.isEmpty ? null : val,
                              ),
                              width: double.infinity,
                              height: 44,
                              textStyle: theme.bodyMedium,
                              hintText: 'Entity type',
                              icon: Icon(
                                Icons.keyboard_arrow_down_rounded,
                                color: theme.primaryText,
                              ),
                              fillColor: theme.primaryBackground,
                              elevation: 0,
                              borderColor: theme.alternate,
                              borderWidth: 1,
                              borderRadius: 8,
                              margin: EdgeInsets.zero,
                              hidesUnderline: true,
                              isSearchable: false,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: FlutterFlowDropDown<String>(
                              controller: _model.userNameFilterController ??=
                                  FormFieldController<String>(null),
                              options: ['', ..._userNameOptions],
                              optionLabels: [
                                'All users',
                                ..._userNameOptions,
                              ],
                              onChanged: (val) => setState(
                                () => _model.userNameFilter =
                                    val == null || val.isEmpty ? null : val,
                              ),
                              width: double.infinity,
                              height: 44,
                              textStyle: theme.bodyMedium,
                              hintText: 'User name',
                              icon: Icon(
                                Icons.keyboard_arrow_down_rounded,
                                color: theme.primaryText,
                              ),
                              fillColor: theme.primaryBackground,
                              elevation: 0,
                              borderColor: theme.alternate,
                              borderWidth: 1,
                              borderRadius: 8,
                              margin: EdgeInsets.zero,
                              hidesUnderline: true,
                              isSearchable: true,
                            ),
                          ),
                          const SizedBox(width: 8),
                          OutlinedButton.icon(
                            onPressed: _pickDateRange,
                            icon: const Icon(Icons.calendar_today, size: 16),
                            label: Text(dateLabel),
                          ),
                          if (_model.startDate != null)
                            IconButton(
                              tooltip: 'Clear dates',
                              onPressed: _clearDateRange,
                              icon: const Icon(Icons.clear, size: 18),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(child: _buildBody(theme, logs)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody(FlutterFlowTheme theme, List<AuditLogsRecord> logs) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            _error!,
            textAlign: TextAlign.center,
            style: theme.bodyLarge.override(color: theme.error),
          ),
        ),
      );
    }
    if (logs.isEmpty) {
      return Center(
        child: Text(
          'No audit logs match your filters.',
          style: theme.bodyLarge.override(color: theme.secondaryText),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadLogs,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        itemCount: logs.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final log = logs[index];
          return _logCard(theme, log);
        },
      ),
    );
  }

  Widget _logCard(FlutterFlowTheme theme, AuditLogsRecord log) {
    return InkWell(
      onTap: () => _showDetailDialog(log),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.secondaryBackground,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: theme.alternate),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        auditActionLabel(log.action),
                        style: theme.titleMedium.override(
                          font: GoogleFonts.interTight(
                            fontWeight: FontWeight.w700,
                          ),
                          color: theme.primary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${log.entityType} · ${log.entityLabel.isNotEmpty ? log.entityLabel : log.entityId}',
                        style: theme.bodySmall.override(
                          color: theme.secondaryText,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  _formatTime(log.createdAt),
                  style: theme.bodySmall.override(color: theme.secondaryText),
                ),
              ],
            ),
            const Divider(height: 20),
            Row(
              children: [
                Expanded(
                  child: Text(
                    log.userName.isNotEmpty ? log.userName : 'Unknown user',
                    style: theme.bodyMedium.override(
                      font: GoogleFonts.inter(fontWeight: FontWeight.w500),
                    ),
                  ),
                ),
                if (log.userRole.isNotEmpty)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: theme.alternate.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      log.userRole,
                      style: theme.labelSmall,
                    ),
                  ),
                const SizedBox(width: 8),
                Icon(Icons.chevron_right, color: theme.secondaryText, size: 20),
              ],
            ),
            if (log.description.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                log.description,
                style: theme.bodySmall.override(color: theme.secondaryText),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
