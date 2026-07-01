import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '/backend/customer_import_helpers.dart';
import '/backend/tenant_query_helpers.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';

Future<void> showCustomerImportPreviewDialog(
  BuildContext context,
  CustomerImportParseResult parseResult, {
  required bool allowCreditCustomers,
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
            title: Text(tr(context, 'customer.import.title')),
            content: SizedBox(
              width: double.maxFinite,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tr(context, 'customer.import.fileLine',
                          params: {'label': parseResult.fileLabel}),
                      style: FlutterFlowTheme.of(context).bodyMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      tr(context, 'customer.import.summaryLine', params: {
                        'total': '${parseResult.rows.length}',
                        'ready': '${parseResult.validCount}',
                        'errors': '${parseResult.errorCount}',
                      }),
                    ),
                    if (!allowCreditCustomers)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          tr(context, 'customer.import.creditAsRegular'),
                          style: FlutterFlowTheme.of(context).bodySmall,
                        ),
                      ),
                    if (parseResult.errorCount > 0) ...[
                      const SizedBox(height: 8),
                      Text(
                        tr(context, 'customer.import.errorsSkipped'),
                        style: FlutterFlowTheme.of(context).bodySmall.override(
                              fontFamily: 'Outfit',
                              color: FlutterFlowTheme.of(context).error,
                            ),
                      ),
                    ],
                    if (previewRows.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Text(
                        tr(context, 'customer.import.preview'),
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 8),
                      ...previewRows.map(
                        (row) => Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Text(
                            tr(context, 'customer.import.previewRow', params: {
                              'name': row.name,
                              'phone': row.phone,
                              'credit': row.isCreditCustomer
                                  ? tr(context,
                                      'customer.import.previewCreditSuffix')
                                  : '',
                            }),
                          ),
                        ),
                      ),
                      if (validRows.length > previewRows.length)
                        Text(
                          tr(context, 'customer.import.previewMore', params: {
                            'count':
                                '${validRows.length - previewRows.length}',
                          }),
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
                child: Text(tr(context, 'common.cancel')),
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
                          final result = await writeImportedCustomers(
                            parseResult.rows,
                            allowCreditCustomers: allowCreditCustomers,
                          );
                          if (!context.mounted) {
                            return;
                          }
                          Navigator.pop(dialogContext);
                          var summary = tr(
                            context,
                            result.created == 1
                                ? 'customer.import.successOne'
                                : 'customer.import.successMany',
                            params: {'count': '${result.created}'},
                          );
                          if (result.skippedDuplicates > 0) {
                            summary += tr(
                              context,
                              'customer.import.skippedDuplicates',
                              params: {
                                'count': '${result.skippedDuplicates}',
                              },
                            );
                          }
                          if (result.failed > 0) {
                            summary += tr(
                              context,
                              'customer.import.failedCount',
                              params: {'count': '${result.failed}'},
                            );
                          }
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(summary)),
                          );
                        } catch (error) {
                          if (!context.mounted) {
                            return;
                          }
                          setDialogState(() => importing = false);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                tr(context, 'customer.import.failed',
                                    params: {'error': '$error'}),
                              ),
                            ),
                          );
                        }
                      },
                text: importing
                    ? tr(context, 'customer.import.importing')
                    : tr(context, 'customer.import.button'),
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

class CustomerImportButton extends StatelessWidget {
  const CustomerImportButton({
    super.key,
    this.fullWidth = true,
    this.allowCreditCustomers = false,
  });

  final bool fullWidth;
  final bool allowCreditCustomers;

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
        SnackBar(content: Text(tr(context, 'customer.import.readFailed'))),
      );
      return;
    }

    try {
      final parsed = parseCustomerImportFile(
        bytes: bytes,
        filename: file.name,
      );
      if (!context.mounted) {
        return;
      }
      await showCustomerImportPreviewDialog(
        context,
        parsed,
        allowCreditCustomers: allowCreditCustomers,
      );
    } on CustomerImportException catch (error) {
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
        SnackBar(
          content: Text(
            tr(context, 'customer.import.failed', params: {'error': '$error'}),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return FFButtonWidget(
      onPressed: () => _pickAndImport(context),
      text: tr(context, 'customer.import.fromFile'),
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
