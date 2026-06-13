import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '/backend/product_import_helpers.dart';
import '/backend/tenant_query_helpers.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_widgets.dart';

Future<void> showProductImportPreviewDialog(
  BuildContext context,
  ProductImportParseResult parseResult,
) async {
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
            title: const Text('Import products'),
            content: SizedBox(
              width: double.maxFinite,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'File: ${parseResult.fileLabel}',
                      style: FlutterFlowTheme.of(context).bodyMedium,
                    ),
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
                              fontFamily: 'Outfit',
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
                            '${row.name} · ${row.sku} · '
                            '\$${row.price.toStringAsFixed(2)}'
                            '${row.category != null ? ' · ${row.category}' : ''}',
                          ),
                        ),
                      ),
                      if (validRows.length > previewRows.length)
                        Text(
                          '…and ${validRows.length - previewRows.length} more',
                          style: FlutterFlowTheme.of(context).bodySmall,
                        ),
                    ],
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: importing
                    ? null
                    : () => Navigator.pop(dialogContext),
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
                          final result =
                              await writeImportedProducts(parseResult.rows);
                          if (!context.mounted) {
                            return;
                          }
                          Navigator.pop(dialogContext);
                          final summary = StringBuffer()
                            ..write('Created ${result.created} product');
                          if (result.created == 1) {
                            summary.write('.');
                          } else {
                            summary.write('s.');
                          }
                          if (result.skippedDuplicates > 0) {
                            summary.write(
                              ' Skipped ${result.skippedDuplicates} duplicate SKU(s).',
                            );
                          }
                          if (result.failed > 0) {
                            summary.write(' ${result.failed} failed.');
                          }
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(summary.toString())),
                          );
                        } catch (error) {
                          if (!context.mounted) {
                            return;
                          }
                          setDialogState(() => importing = false);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Import failed: $error')),
                          );
                        }
                      },
                text: importing ? 'Importing...' : 'Import',
                options: FFButtonOptions(
                  height: 40,
                  padding: const EdgeInsetsDirectional.fromSTEB(16, 0, 16, 0),
                  color: const Color(0xFF6F61EF),
                  textStyle: FlutterFlowTheme.of(context).titleSmall.override(
                        fontFamily: 'Figtree',
                        color: Colors.white,
                      ),
                  elevation: 2,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ],
          );
        },
      );
    },
  );
}

class ProductImportButton extends StatelessWidget {
  const ProductImportButton({
    super.key,
    this.fullWidth = true,
  });

  final bool fullWidth;

  Future<void> _pickAndImport(BuildContext context) async {
    final picked = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['csv', 'xlsx'],
      withData: true,
      allowMultiple: false,
    );
    if (picked == null || picked.files.isEmpty) {
      return;
    }
    final file = picked.files.first;
    final bytes = file.bytes;
    if (bytes == null || bytes.isEmpty) {
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not read the selected file.')),
      );
      return;
    }

    try {
      final parsed = parseProductImportFile(
        bytes: bytes,
        filename: file.name,
      );
      if (!context.mounted) {
        return;
      }
      await showProductImportPreviewDialog(context, parsed);
    } on ProductImportException catch (error) {
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message)),
      );
    } catch (error) {
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Import failed: $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return FFButtonWidget(
      onPressed: () => _pickAndImport(context),
      text: 'Import from Excel / CSV',
      icon: const Icon(
        Icons.upload_file,
        size: 18,
        color: Color(0xFF6F61EF),
      ),
      options: FFButtonOptions(
        width: fullWidth ? double.infinity : null,
        height: 44,
        padding: const EdgeInsetsDirectional.fromSTEB(16, 0, 16, 0),
        iconPadding: const EdgeInsetsDirectional.fromSTEB(0, 0, 8, 0),
        color: Colors.white,
        textStyle: FlutterFlowTheme.of(context).titleSmall.override(
              fontFamily: 'Figtree',
              color: const Color(0xFF6F61EF),
              fontWeight: FontWeight.w500,
            ),
        elevation: 0,
        borderSide: const BorderSide(
          color: Color(0xFF6F61EF),
          width: 1,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }
}
