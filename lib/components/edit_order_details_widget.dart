import '/backend/backend.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Admin bottom sheet to correct order customer / delivery information.
class EditOrderDetailsWidget extends StatefulWidget {
  const EditOrderDetailsWidget({
    super.key,
    required this.orderRef,
    required this.order,
  });

  final DocumentReference orderRef;
  final OrdersRecord order;

  @override
  State<EditOrderDetailsWidget> createState() => _EditOrderDetailsWidgetState();
}

class _EditOrderDetailsWidgetState extends State<EditOrderDetailsWidget> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _clientNameController;
  late final TextEditingController _recipientNameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _addressController;
  late final TextEditingController _regionController;
  late final TextEditingController _postalCodeController;
  late final TextEditingController _timeSlotController;
  late final TextEditingController _cardMessageController;
  DateTime? _deliveryDate;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final order = widget.order;
    _clientNameController = TextEditingController(text: order.clientName);
    _recipientNameController =
        TextEditingController(text: order.recipientName);
    _phoneController =
        TextEditingController(text: order.customerPhoneNumber);
    _addressController = TextEditingController(text: order.address);
    _regionController = TextEditingController(text: order.region);
    _postalCodeController = TextEditingController(text: order.postalCode);
    _timeSlotController =
        TextEditingController(text: order.deliveryTimeSlot);
    _cardMessageController = TextEditingController(text: order.cardMessage);
    _deliveryDate = order.deliveryDate;
  }

  @override
  void dispose() {
    _clientNameController.dispose();
    _recipientNameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _regionController.dispose();
    _postalCodeController.dispose();
    _timeSlotController.dispose();
    _cardMessageController.dispose();
    super.dispose();
  }

  Future<void> _pickDeliveryDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _deliveryDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return wrapInMaterialDatePickerTheme(
          context,
          child!,
          headerBackgroundColor: FlutterFlowTheme.of(context).primary,
          headerForegroundColor: FlutterFlowTheme.of(context).info,
          headerTextStyle: FlutterFlowTheme.of(context).headlineLarge.override(
                font: GoogleFonts.interTight(
                  fontWeight: FontWeight.w600,
                  fontStyle:
                      FlutterFlowTheme.of(context).headlineLarge.fontStyle,
                ),
                fontSize: 32.0,
                letterSpacing: 0.0,
                fontWeight: FontWeight.w600,
                fontStyle:
                    FlutterFlowTheme.of(context).headlineLarge.fontStyle,
              ),
          pickerBackgroundColor:
              FlutterFlowTheme.of(context).secondaryBackground,
          pickerForegroundColor: FlutterFlowTheme.of(context).primaryText,
          selectedDateTimeBackgroundColor:
              FlutterFlowTheme.of(context).primary,
          selectedDateTimeForegroundColor:
              FlutterFlowTheme.of(context).info,
          actionButtonForegroundColor:
              FlutterFlowTheme.of(context).primaryText,
          iconSize: 24.0,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _deliveryDate = DateTime(picked.year, picked.month, picked.day);
      });
    }
  }

  Future<void> _save() async {
    if (_formKey.currentState == null || !_formKey.currentState!.validate()) {
      return;
    }
    final needsDeliveryDate = widget.order.orderType
        .toLowerCase()
        .contains('delivery');
    if (needsDeliveryDate && _deliveryDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a delivery date.')),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      await widget.orderRef.update(
        createOrdersRecordData(
          clientName: _clientNameController.text.trim(),
          recipientName: _recipientNameController.text.trim(),
          customerPhoneNumber: _phoneController.text.trim(),
          address: _addressController.text.trim(),
          region: _regionController.text.trim(),
          postalCode: _postalCodeController.text.trim(),
          deliveryDate: _deliveryDate ?? widget.order.deliveryDate,
          deliveryTimeSlot: _timeSlotController.text.trim(),
          cardMessage: _cardMessageController.text.trim(),
        ),
      );
      if (!mounted) {
        return;
      }
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Order details updated.')),
      );
    } catch (e) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  InputDecoration _fieldDecoration(BuildContext context, String label) {
    return InputDecoration(
      labelText: label,
      enabledBorder: OutlineInputBorder(
        borderSide: BorderSide(
          color: FlutterFlowTheme.of(context).alternate,
          width: 1.0,
        ),
        borderRadius: BorderRadius.circular(8.0),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: BorderSide(
          color: FlutterFlowTheme.of(context).primary,
          width: 1.0,
        ),
        borderRadius: BorderRadius.circular(8.0),
      ),
      filled: true,
      fillColor: FlutterFlowTheme.of(context).secondaryBackground,
      contentPadding: const EdgeInsetsDirectional.fromSTEB(16.0, 12.0, 16.0, 12.0),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.9,
        ),
        decoration: BoxDecoration(
          color: FlutterFlowTheme.of(context).secondaryBackground,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(16.0),
            topRight: Radius.circular(16.0),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(0.0, 12.0, 0.0, 0.0),
              child: Container(
                width: 50.0,
                height: 4.0,
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F4F8),
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(16.0, 16.0, 16.0, 0.0),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Edit Order Details',
                      style: FlutterFlowTheme.of(context).headlineSmall.override(
                            font: GoogleFonts.outfit(
                              fontWeight: FontWeight.w600,
                              fontStyle: FlutterFlowTheme.of(context)
                                  .headlineSmall
                                  .fontStyle,
                            ),
                            letterSpacing: 0.0,
                            fontWeight: FontWeight.w600,
                            fontStyle: FlutterFlowTheme.of(context)
                                .headlineSmall
                                .fontStyle,
                          ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsetsDirectional.fromSTEB(16.0, 8.0, 16.0, 16.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextFormField(
                        controller: _clientNameController,
                        decoration: _fieldDecoration(context, 'Customer name'),
                        validator: (v) =>
                            v == null || v.trim().isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: 12.0),
                      TextFormField(
                        controller: _recipientNameController,
                        decoration: _fieldDecoration(context, 'Recipient'),
                        textCapitalization: TextCapitalization.words,
                      ),
                      const SizedBox(height: 12.0),
                      TextFormField(
                        controller: _phoneController,
                        decoration: _fieldDecoration(context, 'Phone'),
                        keyboardType: TextInputType.phone,
                      ),
                      const SizedBox(height: 12.0),
                      TextFormField(
                        controller: _addressController,
                        decoration: _fieldDecoration(context, 'Delivery address'),
                        maxLines: 2,
                        validator: (v) =>
                            v == null || v.trim().isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: 12.0),
                      TextFormField(
                        controller: _regionController,
                        decoration: _fieldDecoration(context, 'Region'),
                      ),
                      const SizedBox(height: 12.0),
                      TextFormField(
                        controller: _postalCodeController,
                        decoration: _fieldDecoration(context, 'Postal code'),
                      ),
                      const SizedBox(height: 12.0),
                      InkWell(
                        onTap: _pickDeliveryDate,
                        child: InputDecorator(
                          decoration: _fieldDecoration(context, 'Delivery date'),
                          child: Text(
                            _deliveryDate == null
                                ? 'Select date'
                                : dateTimeFormat(
                                    'd/M/y',
                                    _deliveryDate!,
                                    locale: FFLocalizations.of(context)
                                        .languageCode,
                                  ),
                            style: FlutterFlowTheme.of(context).bodyMedium,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12.0),
                      TextFormField(
                        controller: _timeSlotController,
                        decoration:
                            _fieldDecoration(context, 'Delivery time slot'),
                      ),
                      const SizedBox(height: 12.0),
                      TextFormField(
                        controller: _cardMessageController,
                        decoration: _fieldDecoration(context, 'Card message'),
                        maxLines: 2,
                      ),
                      const SizedBox(height: 20.0),
                      FFButtonWidget(
                        onPressed: _saving ? null : _save,
                        text: _saving ? 'Saving...' : 'Save Changes',
                        options: FFButtonOptions(
                          width: double.infinity,
                          height: 48.0,
                          color: FlutterFlowTheme.of(context).primary,
                          textStyle: FlutterFlowTheme.of(context)
                              .titleSmall
                              .override(
                                font: GoogleFonts.interTight(
                                  fontWeight: FontWeight.w600,
                                  fontStyle: FlutterFlowTheme.of(context)
                                      .titleSmall
                                      .fontStyle,
                                ),
                                color: Colors.white,
                                letterSpacing: 0.0,
                                fontWeight: FontWeight.w600,
                                fontStyle: FlutterFlowTheme.of(context)
                                    .titleSmall
                                    .fontStyle,
                              ),
                          elevation: 0.0,
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

void showEditOrderDetailsSheet(
  BuildContext context, {
  required DocumentReference orderRef,
  required OrdersRecord order,
}) {
  showModalBottomSheet(
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    context: context,
    builder: (sheetContext) {
      return Padding(
        padding: MediaQuery.viewInsetsOf(sheetContext),
        child: EditOrderDetailsWidget(
          orderRef: orderRef,
          order: order,
        ),
      );
    },
  );
}
