import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '/auth/firebase_auth/auth_util.dart';
import '/backend/create_order_service.dart';
import '/backend/backend.dart';
import '/backend/price_list_helpers.dart';
import '/backend/tenant_context.dart';
import '/backend/tenant_query_helpers.dart';
import '/backend/user_query_helpers.dart';
import '/components/home_nav_button.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/index.dart';

class PriceListPageWidget extends StatefulWidget {
  const PriceListPageWidget({super.key});

  static String routeName = 'PriceListPage';
  static String routePath = '/priceListPage';

  @override
  State<PriceListPageWidget> createState() => _PriceListPageWidgetState();
}

class _PriceListPageWidgetState extends State<PriceListPageWidget> {
  List<PriceListsRecord> _lists = const [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrapAndLoad());
  }

  Future<void> _bootstrapAndLoad() async {
    if (loggedIn) {
      final profile = await resolveCurrentUserProfile();
      await TenantContext.instance.initialize(profile);
    }
    await _loadLists();
  }

  Future<void> _loadLists() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final lists = await queryTenantPriceListsRecordOnce();
      lists.sort(
        (a, b) => priceListLabel(a).toLowerCase().compareTo(
              priceListLabel(b).toLowerCase(),
            ),
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _lists = lists;
        _loading = false;
      });
    } catch (error) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = describeFirestoreError(error);
        });
      }
    }
  }

  Future<void> _createPriceList() async {
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('New price list'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'List name',
            hintText: 'e.g. Hotel Group A',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () =>
                Navigator.pop(dialogContext, controller.text.trim()),
            child: const Text('Create'),
          ),
        ],
      ),
    );
    if (name == null || name.isEmpty) {
      return;
    }
    final blocked = await TenantContext.instance.ensureReadyForTenantWrite();
    if (!mounted) {
      return;
    }
    if (blocked != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(blocked)),
      );
      return;
    }
    try {
      final ref = await createPriceList(name: name);
      if (!mounted) {
        return;
      }
      await context.pushNamed(
        PriceListEditPageWidget.routeName,
        pathParameters: {'priceListId': ref.id},
      );
      await _loadLists();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(describeFirestoreError(error))),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    return Scaffold(
      backgroundColor: theme.primaryBackground,
      appBar: AppBar(
        backgroundColor: theme.primaryBackground,
        title: Text(
          loc(context,
              en: 'Price lists', zh: '价目表', ms: 'Senarai harga'),
          style: theme.headlineMedium.override(
            font: GoogleFonts.interTight(fontWeight: FontWeight.w600),
          ),
        ),
        actions: const [
          HomeNavIconButton(),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createPriceList,
        icon: const Icon(Icons.add),
        label: Text(loc(context,
            en: 'New list', zh: '新建价目表', ms: 'Senarai baharu')),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : _lists.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          loc(
                            context,
                            en: 'No price lists yet.\nCreate one and import SKU prices from Excel.',
                            zh: '还没有价目表。\n创建后可用 Excel 导入 SKU 价格。',
                            ms: 'Tiada senarai harga lagi.\nCipta dan import harga SKU dari Excel.',
                          ),
                          textAlign: TextAlign.center,
                          style: theme.bodyMedium.override(
                            color: theme.secondaryText,
                          ),
                        ),
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadLists,
                      child: ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: _lists.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final list = _lists[index];
                          final lineCount = parsePriceListLines(list).length;
                          return Material(
                            color: theme.secondaryBackground,
                            borderRadius: BorderRadius.circular(12),
                            clipBehavior: Clip.antiAlias,
                            child: ListTile(
                              title: Text(
                                priceListLabel(list),
                                style: theme.titleMedium.override(
                                  font: GoogleFonts.interTight(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              subtitle: Text(
                                loc(
                                  context,
                                  en: '$lineCount contract price(s)',
                                  zh: '$lineCount 个合约价',
                                  ms: '$lineCount harga kontrak',
                                ),
                              ),
                              trailing: const Icon(Icons.chevron_right),
                              onTap: () async {
                                await context.pushNamed(
                                  PriceListEditPageWidget.routeName,
                                  pathParameters: {
                                    'priceListId': list.reference.id,
                                  },
                                );
                                await _loadLists();
                              },
                            ),
                          );
                        },
                      ),
                    ),
    );
  }
}
