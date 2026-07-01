import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '/backend/backend.dart';
import '/backend/create_order_service.dart';
import '/backend/order_item_helpers.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import 'remark_model.dart';

export 'remark_model.dart';

class RemarkWidget extends StatefulWidget {
  const RemarkWidget({
    super.key,
    required this.orderRef,
    this.orderItemRef,
    this.initialRemark,
  });

  final DocumentReference? orderRef;
  final DocumentReference? orderItemRef;
  final String? initialRemark;

  @override
  State<RemarkWidget> createState() => _RemarkWidgetState();
}

class _RemarkWidgetState extends State<RemarkWidget> {
  late RemarkModel _model;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => RemarkModel());
    _model.textController ??=
        TextEditingController(text: widget.initialRemark?.trim() ?? '');
    _model.textFieldFocusNode ??= FocusNode();
  }

  @override
  void dispose() {
    _model.maybeDispose();
    super.dispose();
  }

  Future<void> _confirmRemark(DocumentReference itemRef) async {
    if (_submitting) {
      return;
    }
    setState(() => _submitting = true);
    try {
      await itemRef.update(
        createOrderItemRecordData(
          remark: _model.textController!.text.trim(),
        ),
      );
      if (!mounted) {
        return;
      }
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            tr(
              context,
              'product.select.remarkSaveError',
              params: {'error': describeFirestoreError(error)},
            ),
          ),
          backgroundColor: FlutterFlowTheme.of(context).error,
          duration: const Duration(seconds: 6),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }

  Widget _buildConfirmButton({required DocumentReference? itemRef}) {
    final theme = FlutterFlowTheme.of(context);
    return FFButtonWidget(
      onPressed: itemRef == null || _submitting
          ? null
          : () => _confirmRemark(itemRef),
      text: _submitting
          ? tr(context, 'common.saving')
          : tr(context, 'common.confirm'),
      options: FFButtonOptions(
        height: 40.0,
        padding: const EdgeInsetsDirectional.fromSTEB(16.0, 0.0, 16.0, 0.0),
        color: theme.primary,
        textStyle: theme.titleSmall.override(
          font: GoogleFonts.interTight(fontWeight: FontWeight.w600),
          color: Colors.white,
        ),
        borderRadius: BorderRadius.circular(8.0),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);

    return Container(
      width: 321.4,
      constraints: const BoxConstraints(minHeight: 200),
      decoration: BoxDecoration(
        color: theme.secondaryBackground,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            tr(context, 'product.select.remarkTitle'),
            textAlign: TextAlign.center,
            style: theme.bodyMedium.override(
              font: GoogleFonts.inter(fontWeight: FontWeight.bold),
              fontSize: 20.0,
            ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _model.textController,
            focusNode: _model.textFieldFocusNode,
            decoration: InputDecoration(
              isDense: true,
              hintText: tr(context, 'product.select.remark'),
              filled: true,
              fillColor: theme.secondaryBackground,
              enabledBorder: OutlineInputBorder(
                borderSide: const BorderSide(color: Color(0x00000000)),
                borderRadius: BorderRadius.circular(8.0),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: const BorderSide(color: Color(0x00000000)),
                borderRadius: BorderRadius.circular(8.0),
              ),
            ),
            style: theme.bodyMedium,
            maxLines: 6,
            minLines: 3,
            cursorColor: theme.primaryText,
          ),
          const SizedBox(height: 16),
          if (widget.orderItemRef != null)
            _buildConfirmButton(itemRef: widget.orderItemRef)
          else if (widget.orderRef == null)
            Text(
              tr(context, 'product.select.remarkItemMissing'),
              style: theme.bodySmall.override(color: theme.error),
            )
          else
            StreamBuilder<List<OrderItemRecord>>(
              stream: streamOrderItemsForOrder(widget.orderRef!),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Text(
                    describeFirestoreError(snapshot.error!),
                    style: theme.bodySmall.override(color: theme.error),
                  );
                }
                if (!snapshot.hasData) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(8),
                      child: SizedBox(
                        width: 28,
                        height: 28,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  );
                }
                final items = activeOrderItems(snapshot.data!);
                if (items.isEmpty) {
                  return Text(
                    tr(context, 'product.select.remarkItemMissing'),
                    style: theme.bodySmall.override(color: theme.error),
                  );
                }
                final itemRef = items.last.reference;
                return _buildConfirmButton(itemRef: itemRef);
              },
            ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: _submitting ? null : () => Navigator.of(context).pop(false),
            child: Text(tr(context, 'common.cancel')),
          ),
        ],
      ),
    );
  }
}

Future<void> showOrderItemRemarkDialog(
  BuildContext context, {
  required DocumentReference orderRef,
  required DocumentReference orderItemRef,
  String? initialRemark,
}) async {
  await showDialog<bool>(
    context: context,
    barrierDismissible: true,
    builder: (dialogContext) {
      return Dialog(
        elevation: 0,
        insetPadding: EdgeInsets.zero,
        backgroundColor: Colors.transparent,
        alignment: AlignmentDirectional.center.resolve(
          Directionality.of(context),
        ),
        child: GestureDetector(
          onTap: () {
            FocusScope.of(dialogContext).unfocus();
            FocusManager.instance.primaryFocus?.unfocus();
          },
          child: RemarkWidget(
            orderRef: orderRef,
            orderItemRef: orderItemRef,
            initialRemark: initialRemark,
          ),
        ),
      );
    },
  );
}
