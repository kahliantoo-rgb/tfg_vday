import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '/backend/cash_payment_helpers.dart';
import '/backend/create_order_service.dart';
import '/backend/backend.dart';
import '/backend/price_list_helpers.dart';
import '/backend/price_list_import_helpers.dart';
import '/backend/tenant_context.dart';
import '/components/price_list_import_button.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/uploaded_file.dart';

class PriceListEditPageWidget extends StatefulWidget {
  const PriceListEditPageWidget({
    super.key,
    required this.priceListId,
  });

  final String priceListId;

  static String routeName = 'PriceListEditPage';
  static String routePath = '/priceListEdit/:priceListId';

  @override
  State<PriceListEditPageWidget> createState() =>
      _PriceListEditPageWidgetState();
}

class _PriceListEditPageWidgetState extends State<PriceListEditPageWidget> {
  final _nameController = TextEditingController();
  PriceListsRecord? _record;
  List<PriceListLine> _lines = const [];
  bool _loading = true;
  bool _savingName = false;
  String? _error;

  DocumentReference get _ref =>
      PriceListsRecord.collection.doc(widget.priceListId);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final record = await PriceListsRecord.getDocumentOnce(_ref);
      if (!mounted) {
        return;
      }
      setState(() {
        _record = record;
        _nameController.text = record.name;
        _lines = parsePriceListLines(record);
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

  Future<void> _saveName() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
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
    setState(() => _savingName = true);
    try {
      await updatePriceListName(priceListRef: _ref, name: name);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Price list name saved.')),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(describeFirestoreError(error))),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _savingName = false);
      }
    }
  }

  Future<void> _downloadTemplate() async {
    await downloadFile(
      filename: 'price_list_import_template.csv',
      uploadedFile: FFUploadedFile(
        name: 'price_list_import_template.csv',
        bytes: priceListImportTemplateBytes(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    return Scaffold(
      backgroundColor: theme.primaryBackground,
      appBar: AppBar(
        backgroundColor: theme.primaryBackground,
        title: Text(
          _record == null
              ? loc(context, en: 'Price list', zh: '价目表', ms: 'Senarai harga')
              : priceListLabel(_record!),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Text(
                      loc(
                        context,
                        en: 'Contract prices apply when adding products to orders '
                            'for customers linked to this list. '
                            'Editing prices on an order only affects that order.',
                        zh: '绑定此价目表的客户下单时，加产品会自动使用合约价。'
                            '在订单里改价只影响该订单。',
                        ms: 'Harga kontrak digunakan apabila menambah produk '
                            'untuk pelanggan yang dipautkan. '
                            'Edit harga dalam pesanan hanya menjejaskan pesanan itu.',
                      ),
                      style: theme.bodySmall.override(
                        color: theme.secondaryText,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        labelText: loc(context,
                            en: 'List name', zh: '价目表名称', ms: 'Nama senarai'),
                        border: const OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: _savingName ? null : _saveName,
                        child: Text(_savingName
                            ? loc(context,
                                en: 'Saving…', zh: '保存中…', ms: 'Menyimpan…')
                            : loc(context,
                                en: 'Save name',
                                zh: '保存名称',
                                ms: 'Simpan nama')),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        OutlinedButton.icon(
                          onPressed: _downloadTemplate,
                          icon: const Icon(Icons.download_outlined),
                          label: Text(loc(context,
                              en: 'Download template',
                              zh: '下载模板',
                              ms: 'Muat turun templat')),
                        ),
                        OutlinedButton.icon(
                          onPressed: () => pickAndImportPriceListFile(
                            context,
                            priceListRef: _ref,
                            onImported: _load,
                          ),
                          icon: const Icon(Icons.upload_file_outlined),
                          label: Text(loc(context,
                              en: 'Import Excel/CSV',
                              zh: '导入 Excel/CSV',
                              ms: 'Import Excel/CSV')),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      loc(
                        context,
                        en: 'Columns: SKU, Product Name (optional), Price. '
                            'Import merges by SKU.',
                        zh: '列：SKU、产品名称（可选）、价格。按 SKU 合并更新。',
                        ms: 'Lajur: SKU, Product Name (pilihan), Price. '
                            'Import digabung mengikut SKU.',
                      ),
                      style: theme.labelSmall.override(
                        color: theme.secondaryText,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      loc(context,
                          en: 'Contract prices',
                          zh: '合约价格',
                          ms: 'Harga kontrak'),
                      style: theme.titleMedium.override(
                        font: GoogleFonts.interTight(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (_lines.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 24),
                        child: Text(
                          loc(context,
                              en: 'No prices yet — import a file or add rows later.',
                              zh: '暂无价格 — 请导入文件。',
                              ms: 'Tiada harga lagi — import fail.'),
                          style: theme.bodyMedium.override(
                            color: theme.secondaryText,
                          ),
                        ),
                      )
                    else
                      ..._lines.map(
                        (line) => Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: theme.secondaryBackground,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: theme.alternate),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      line.sku,
                                      style: theme.titleSmall.override(
                                        font: GoogleFonts.interTight(
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                    if (line.productName.isNotEmpty)
                                      Text(
                                        line.productName,
                                        style: theme.bodySmall.override(
                                          color: theme.secondaryText,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              Text(
                                formatCashMoney(line.price),
                                style: theme.titleSmall.override(
                                  font: GoogleFonts.interTight(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
    );
  }
}
