import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '/backend/backend.dart';
import '/backend/order_item_helpers.dart';
import '/backend/order_list_display_helpers.dart';
import '/backend/partial_delivery_helpers.dart';
import '/custom_code/bluetooth_receipt_printer.dart';
import '/custom_code/delivery_order_pdf_printer.dart';
import '/flutter_flow/flutter_flow_icon_button.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import 'partial_delivery_page_model.dart';

export 'partial_delivery_page_model.dart';

class PartialDeliveryPageWidget extends StatefulWidget {
  const PartialDeliveryPageWidget({
    super.key,
    required this.orderRef,
  });

  final DocumentReference? orderRef;

  static String routeName = 'PartialDeliveryPage';
  static String routePath = '/partialDeliveryPage';

  @override
  State<PartialDeliveryPageWidget> createState() =>
      _PartialDeliveryPageWidgetState();
}

class _PartialDeliveryPageWidgetState extends State<PartialDeliveryPageWidget> {
  late PartialDeliveryPageModel _model;
  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => PartialDeliveryPageModel());
    WidgetsBinding.instance.addPostFrameCallback((_) => safeSetState(() {}));
  }

  @override
  void dispose() {
    _model.dispose();
    super.dispose();
  }

  int _deliverNowFor(OrderItemRecord item) {
    return _model.deliverNowByItemId[item.reference.id] ?? 0;
  }

  void _setDeliverNow(OrderItemRecord item, int value) {
    final remaining = remainingDeliveryQty(item);
    setState(() {
      _model.deliverNowByItemId[item.reference.id] =
          value.clamp(0, remaining);
    });
  }

  Future<void> _pickNextDeliveryDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _model.nextDeliveryDate ?? DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() => _model.nextDeliveryDate = picked);
    }
  }

  Future<void> _printDeliverySlip(
    OrdersRecord order,
    List<OrderItemRecord> printItems, {
    required bool thermal,
    String? deliveryIdOverride,
  }) async {
    if (printItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Select at least one item quantity to print.'),
        ),
      );
      return;
    }
    if (thermal) {
      await BluetoothReceiptPrinter.printDeliverySlip(
        context,
        order: order,
        items: printItems,
        deliveryIdOverride: deliveryIdOverride,
      );
    } else {
      await DeliveryOrderPdfPrinter.printDeliverySlipPdfA4ForItems(
        context,
        order: order,
        items: printItems,
        deliveryIdOverride: deliveryIdOverride,
      );
    }
  }

  Future<void> _printPartialDeliveryRun(
    OrdersRecord order,
    PartialDeliveryRun run, {
    required bool thermal,
  }) async {
    await _printDeliverySlip(
      order,
      orderItemsFromPartialDeliveryRun(run, order.reference),
      thermal: thermal,
      deliveryIdOverride: run.deliveryId,
    );
  }

  Future<void> _submit(
    OrdersRecord order,
    List<OrderItemRecord> items,
  ) async {
    if (widget.orderRef == null || _model.submitting) {
      return;
    }

    final lines = activeOrderItems(items)
        .where((item) => remainingDeliveryQty(item) > 0)
        .map(
          (item) => PartialDeliveryLineInput(
            item: item,
            deliverNow: _deliverNowFor(item),
          ),
        )
        .toList();

    final validationError = validatePartialDeliveryLines(lines);
    if (validationError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(validationError)),
      );
      return;
    }

    setState(() => _model.submitting = true);
    try {
      final result = await submitPartialDelivery(
        orderRef: widget.orderRef!,
        lines: lines,
        nextDeliveryDate: _model.nextDeliveryDate,
      );
      if (!mounted) {
        return;
      }
      final message = result.fullyDelivered
          ? 'All items delivered. Order completed.'
          : 'Recorded ${result.deliveredThisRun} item(s). '
              '${result.remainingQty} still to deliver.';
      if (result.run != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '$message Delivery ID: ${result.run!.deliveryId}',
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
      }

      if (!mounted) {
        return;
      }
      if (result.fullyDelivered) {
        context.safePop();
      } else {
        setState(() {
          _model.deliverNowByItemId.clear();
          _model.nextDeliveryDate = null;
        });
      }
    } on PartialDeliveryValidationException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.message)),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _model.submitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.orderRef == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Partial delivery')),
        body: const Center(child: Text('Order not found')),
      );
    }

    final theme = FlutterFlowTheme.of(context);

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        key: scaffoldKey,
        backgroundColor: theme.primaryBackground,
        appBar: AppBar(
          backgroundColor: theme.secondaryBackground,
          automaticallyImplyLeading: false,
          leading: FlutterFlowIconButton(
            borderColor: Colors.transparent,
            borderRadius: 30.0,
            borderWidth: 1.0,
            buttonSize: 60.0,
            icon: Icon(
              Icons.arrow_back_rounded,
              color: theme.primaryText,
              size: 30.0,
            ),
            onPressed: () => context.safePop(),
          ),
          title: Text(
            'Partial delivery',
            style: theme.titleLarge.override(
              font: GoogleFonts.interTight(fontWeight: FontWeight.w600),
            ),
          ),
          centerTitle: false,
          elevation: 0,
        ),
        body: StreamBuilder<OrdersRecord>(
          stream: OrdersRecord.getDocument(widget.orderRef!),
          builder: (context, orderSnapshot) {
            if (!orderSnapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final order = orderSnapshot.data!;

            return StreamBuilder<List<OrderItemRecord>>(
              stream: queryOrderItemRecord(
                queryBuilder: (query) =>
                    query.where('orderRef', isEqualTo: widget.orderRef),
              ),
              builder: (context, itemsSnapshot) {
                if (!itemsSnapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final items = activeOrderItems(itemsSnapshot.data!);
                final ordered = orderTotalOrderedQty(items);
                final delivered = orderTotalDeliveredQty(items);
                final remaining = orderTotalRemainingQty(items);
                final deliveryRuns = parsePartialDeliveryRunsFromOrder(order);

                return SafeArea(
                  child: Column(
                    children: [
                      Expanded(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                orderListOrderId(order),
                                style: theme.headlineSmall.override(
                                  font: GoogleFonts.interTight(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              if (order.clientName.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(order.clientName, style: theme.bodyLarge),
                              ],
                              if (order.address.isNotEmpty) ...[
                                const SizedBox(height: 8),
                                Text(
                                  order.address,
                                  style: theme.bodyMedium.override(
                                    color: theme.secondaryText,
                                  ),
                                ),
                              ],
                              const SizedBox(height: 16),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: theme.accent1,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Delivery progress',
                                      style: theme.labelMedium.override(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      '$delivered of $ordered delivered'
                                      '${remaining > 0 ? ' · $remaining left' : ''}',
                                      style: theme.titleMedium,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 16),
                              if (deliveryRuns.isNotEmpty) ...[
                                Text(
                                  'Delivery runs',
                                  style: theme.titleMedium.override(
                                    font: GoogleFonts.interTight(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                ...deliveryRuns.map((run) {
                                  final itemCount = run.items.fold<int>(
                                    0,
                                    (sum, item) =>
                                        sum + ((item['qty'] as num?)?.toInt() ?? 0),
                                  );
                                  final deliveredLabel = run.deliveredAt != null
                                      ? dateTimeFormat(
                                          'd/M/y HH:mm',
                                          run.deliveredAt,
                                        )
                                      : 'Recorded';
                                  return Card(
                                    margin: const EdgeInsets.only(bottom: 12),
                                    child: Padding(
                                      padding: const EdgeInsets.all(12),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.stretch,
                                        children: [
                                          Text(
                                            run.deliveryId,
                                            style: theme.titleSmall.override(
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            '$deliveredLabel · $itemCount item(s)',
                                            style: theme.bodySmall.override(
                                              color: theme.secondaryText,
                                            ),
                                          ),
                                          const SizedBox(height: 12),
                                          Row(
                                            children: [
                                              Expanded(
                                                child: FFButtonWidget(
                                                  onPressed: () =>
                                                      _printPartialDeliveryRun(
                                                    order,
                                                    run,
                                                    thermal: false,
                                                  ),
                                                  text: 'PDF',
                                                  icon: const Icon(
                                                    Icons.picture_as_pdf,
                                                    size: 18,
                                                  ),
                                                  options: FFButtonOptions(
                                                    height: 40,
                                                    color: theme.primary,
                                                    textStyle: theme.titleSmall
                                                        .override(
                                                      color: Colors.white,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                    ),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            8),
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 12),
                                              Expanded(
                                                child: FFButtonWidget(
                                                  onPressed: kIsWeb
                                                      ? null
                                                      : () =>
                                                          _printPartialDeliveryRun(
                                                        order,
                                                        run,
                                                        thermal: true,
                                                      ),
                                                  text: 'Thermal',
                                                  icon: const Icon(
                                                    Icons.print,
                                                    size: 18,
                                                  ),
                                                  options: FFButtonOptions(
                                                    height: 40,
                                                    color: theme
                                                        .secondaryBackground,
                                                    textStyle: theme.titleSmall
                                                        .override(
                                                      color: theme.primary,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                    ),
                                                    borderSide: BorderSide(
                                                      color: theme.primary,
                                                    ),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            8),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                }),
                                const SizedBox(height: 8),
                              ],
                              Text(
                                'Deliver today',
                                style: theme.titleMedium.override(
                                  font: GoogleFonts.interTight(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              if (items.isEmpty)
                                Text(
                                  'No products on this order.',
                                  style: theme.bodyMedium,
                                )
                              else
                                ...items.map((item) {
                                  final remainingQty =
                                      remainingDeliveryQty(item);
                                  final already = readDeliveredQty(item);
                                  final deliverNow = _deliverNowFor(item);

                                  return Card(
                                    margin: const EdgeInsets.only(bottom: 12),
                                    child: Padding(
                                      padding: const EdgeInsets.all(12),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            item.name.isNotEmpty
                                                ? item.name
                                                : 'Item',
                                            style: theme.titleSmall.override(
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          if (item.remark.trim().isNotEmpty)
                                            Padding(
                                              padding:
                                                  const EdgeInsets.only(top: 4),
                                              child: Text(
                                                item.remark.trim(),
                                                style: theme.bodySmall,
                                              ),
                                            ),
                                          const SizedBox(height: 8),
                                          Text(
                                            'Delivered $already / ${item.qty}'
                                            ' · Remaining $remainingQty',
                                            style: theme.bodySmall.override(
                                              color: theme.secondaryText,
                                            ),
                                          ),
                                          if (remainingQty <= 0)
                                            Padding(
                                              padding:
                                                  const EdgeInsets.only(top: 8),
                                              child: Text(
                                                'Fully delivered',
                                                style: theme.bodyMedium.override(
                                                  color: theme.success,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            )
                                          else ...[
                                            const SizedBox(height: 12),
                                            Row(
                                              children: [
                                                IconButton(
                                                  onPressed: deliverNow > 0
                                                      ? () => _setDeliverNow(
                                                            item,
                                                            deliverNow - 1,
                                                          )
                                                      : null,
                                                  icon: const Icon(
                                                    Icons.remove_circle_outline,
                                                  ),
                                                ),
                                                SizedBox(
                                                  width: 48,
                                                  child: Text(
                                                    '$deliverNow',
                                                    textAlign: TextAlign.center,
                                                    style: theme.titleMedium,
                                                  ),
                                                ),
                                                IconButton(
                                                  onPressed: deliverNow <
                                                          remainingQty
                                                      ? () => _setDeliverNow(
                                                            item,
                                                            deliverNow + 1,
                                                          )
                                                      : null,
                                                  icon: const Icon(
                                                    Icons.add_circle_outline,
                                                  ),
                                                ),
                                                const Spacer(),
                                                TextButton(
                                                  onPressed: () =>
                                                      _setDeliverNow(
                                                    item,
                                                    remainingQty,
                                                  ),
                                                  child: Text(
                                                    'All $remainingQty',
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                  );
                                }),
                              if (remaining > 0) ...[
                                const SizedBox(height: 8),
                                ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  title: const Text(
                                    'Next delivery date (optional)',
                                  ),
                                  subtitle: Text(
                                    _model.nextDeliveryDate == null
                                        ? 'Keep current schedule'
                                        : dateTimeFormat(
                                            'd/M/y',
                                            _model.nextDeliveryDate,
                                          ),
                                  ),
                                  trailing: IconButton(
                                    icon: const Icon(Icons.calendar_today),
                                    onPressed: _pickNextDeliveryDate,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        child: FFButtonWidget(
                          onPressed: remaining <= 0 || _model.submitting
                              ? null
                              : () => _submit(order, items),
                          text: _model.submitting
                              ? 'Saving...'
                              : 'Confirm partial delivery',
                          options: FFButtonOptions(
                            width: double.infinity,
                            height: 48,
                            color: theme.primary,
                            textStyle: theme.titleSmall.override(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
