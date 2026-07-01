import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '/backend/price_list_import_helpers.dart';
import '/backend/tenant_query_helpers.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_widgets.dart';

Future<void> showPriceListImportPreviewDialog(
  BuildContext context, {
  required DocumentReference priceListRef,
  required PriceListImportParseResult parseResult,
  VoidCallback? onImported,
}) async {
  final validRows =
      parseResult.rows.where((row) => row.isValid).toList(growable: false);
  final previewRows = validRows.take(8).toList(growable: false);
  var importing = false;

  await showDialog<void>(
    context: context,
    builder: (dialogContext) {
      return StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('Import price list'),
            content: SizedBox(
              width: double.maxFinite,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('File: ${parseResult.fileLabel}'),
                    const SizedBox(height: 8),
                    Text(
                      '${parseResult.rows.length} rows · '
                      '${parseResult.validCount} ready · '
                      '${parseResult.errorCount} with errors',
                    ),
                    if (parseResult.errorCount > 0) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Rows with errors will be skipped.',
                        style: FlutterFlowTheme.of(context).bodySmall.override(
                              color: FlutterFlowTheme.of(context).error,
                            ),
                      ),
                    ],
                    if (previewRows.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      const Text(
                        'Preview',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 8),
                      ...previewRows.map(
                        (row) => Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Text(
                            '${row.sku} · '
                            '\$${row.price.toStringAsFixed(2)}'
                            '${row.productName != null ? ' · ${row.productName}' : ''}',
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: importing ? null : () => Navigator.pop(dialogContext),
                child: const Text('Cancel'),
              ),
              FFButtonWidget(
                onPressed: importing || validRows.isEmpty
                    ? null
                    : () async {
                        if (!ensureActiveCompanyForWrite(context)) {
                          return;
                        }
                        setDialogState(() => importing = true);
                        try {
                          final result = await writeImportedPriceListLines(
                            priceListRef: priceListRef,
                            rows: parseResult.rows,
                          );
                          if (!context.mounted) {
                            return;
                          }
                          Navigator.pop(dialogContext);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(result.messages.join('\n'))),
                          );
                          onImported?.call();
                        } catch (error) {
                          if (!context.mounted) {
                            return;
                          }
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Import failed: $error'),
                              backgroundColor:
                                  FlutterFlowTheme.of(context).error,
                            ),
                          );
                        } finally {
                          if (dialogContext.mounted) {
                            setDialogState(() => importing = false);
                          }
                        }
                      },
                text: 'Import',
                options: FFButtonOptions(
                  height: 40,
                  color: FlutterFlowTheme.of(context).primary,
                  textStyle: FlutterFlowTheme.of(context).titleSmall.override(
                        color: Colors.white,
                      ),
                ),
              ),
            ],
          );
        },
      );
    },
  );
}

Future<void> pickAndImportPriceListFile(
  BuildContext context, {
  required DocumentReference priceListRef,
  VoidCallback? onImported,
}) async {
  if (!ensureActiveCompanyForWrite(context)) {
    return;
  }
  final picked = await FilePicker.platform.pickFiles(
    type: FileType.custom,
    allowedExtensions: const ['csv', 'xlsx'],
    withData: true,
  );
  if (picked == null || picked.files.isEmpty) {
    return;
  }
  final file = picked.files.first;
  final bytes = file.bytes;
  if (bytes == null) {
    if (!context.mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Could not read the selected file.')),
    );
    return;
  }
  final filename = file.name.isNotEmpty ? file.name : 'import.xlsx';
  final parseResult = parsePriceListImportFile(
    bytes: bytes,
    filename: filename,
  );
  if (!context.mounted) {
    return;
  }
  await showPriceListImportPreviewDialog(
    context,
    priceListRef: priceListRef,
    parseResult: parseResult,
    onImported: onImported,
  );
}
