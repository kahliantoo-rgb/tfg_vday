import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '/backend/product_edit_helpers.dart';
import '/backend/schema/product_record.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';
import '/index.dart';

/// Inline editor for one product: price, active toggle, photo upload.
class ProductListItemEditor extends StatefulWidget {
  const ProductListItemEditor({
    super.key,
    required this.product,
  });

  final ProductRecord product;

  @override
  State<ProductListItemEditor> createState() => _ProductListItemEditorState();
}

class _ProductListItemEditorState extends State<ProductListItemEditor> {
  late TextEditingController _priceController;
  late bool _isActive;
  bool _savingPrice = false;
  bool _uploading = false;
  String _imageUrl = '';

  @override
  void initState() {
    super.initState();
    _priceController = TextEditingController(
      text: widget.product.price.toStringAsFixed(
        widget.product.price.truncateToDouble() == widget.product.price ? 0 : 2,
      ),
    );
    _isActive = widget.product.isActive;
    _imageUrl = widget.product.image;
  }

  @override
  void didUpdateWidget(ProductListItemEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.product.reference != widget.product.reference) {
      _priceController.text = widget.product.price.toString();
      _isActive = widget.product.isActive;
      _imageUrl = widget.product.image;
    } else if (oldWidget.product.image != widget.product.image) {
      _imageUrl = widget.product.image;
    }
  }

  @override
  void dispose() {
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _savePrice() async {
    final price = double.tryParse(_priceController.text.trim());
    if (price == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid price')),
      );
      return;
    }
    setState(() => _savingPrice = true);
    try {
      await updateProductPrice(widget.product.reference, price);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Price saved')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _savingPrice = false);
      }
    }
  }

  Future<void> _onActiveChanged(bool value) async {
    setState(() => _isActive = value);
    await updateProductIsActive(widget.product.reference, value);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(value ? 'Product activated' : 'Product deactivated')),
      );
    }
  }

  Future<void> _uploadPhoto() async {
    setState(() => _uploading = true);
    try {
      final url = await pickAndUploadProductImage(
        context: context,
        productRef: widget.product.reference,
      );
      if (url != null && mounted) {
        setState(() => _imageUrl = url);
      }
    } finally {
      if (mounted) {
        setState(() => _uploading = false);
      }
    }
  }

  Widget _productImage() {
    final url = _imageUrl;
    if (!isUsableImageUrl(url)) {
      return Container(
        width: 72.0,
        height: 72.0,
        decoration: BoxDecoration(
          color: FlutterFlowTheme.of(context).alternate,
          borderRadius: BorderRadius.circular(8.0),
        ),
        child: Icon(
          Icons.image_not_supported_outlined,
          color: FlutterFlowTheme.of(context).secondaryText,
        ),
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(8.0),
      child: Image.network(
        url,
        width: 72.0,
        height: 72.0,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(
          width: 72.0,
          height: 72.0,
          color: FlutterFlowTheme.of(context).alternate,
          child: const Icon(Icons.broken_image_outlined),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _productImage(),
                const SizedBox(width: 12.0),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.product.name,
                        style: FlutterFlowTheme.of(context).titleMedium,
                      ),
                      if (widget.product.sku.isNotEmpty)
                        Text(
                          'SKU: ${widget.product.sku}',
                          style: FlutterFlowTheme.of(context).bodySmall,
                        ),
                      const SizedBox(height: 8.0),
                      Row(
                        children: [
                          const Text('Active'),
                          const SizedBox(width: 8.0),
                          Switch.adaptive(
                            value: _isActive,
                            onChanged: _onActiveChanged,
                            activeColor: FlutterFlowTheme.of(context).primary,
                          ),
                          Text(
                            _isActive ? 'Active' : 'Inactive',
                            style: FlutterFlowTheme.of(context).labelMedium,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12.0),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _priceController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                        RegExp(r'^\d*\.?\d{0,2}'),
                      ),
                    ],
                    decoration: InputDecoration(
                      labelText: 'Price',
                      isDense: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8.0),
                FFButtonWidget(
                  onPressed: _savingPrice ? null : _savePrice,
                  text: _savingPrice ? '...' : 'Save',
                  options: FFButtonOptions(
                    height: 40.0,
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    color: FlutterFlowTheme.of(context).primary,
                    textStyle: FlutterFlowTheme.of(context).titleSmall.override(
                          font: GoogleFonts.interTight(),
                          color: Colors.white,
                        ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8.0),
            Row(
              children: [
                Expanded(
                  child: FFButtonWidget(
                    onPressed: _uploading ? null : _uploadPhoto,
                    text: _uploading ? 'Uploading...' : 'Upload Photo',
                    icon: const Icon(
                      Icons.upload,
                      size: 18.0,
                      color: Colors.white,
                    ),
                    options: FFButtonOptions(
                      height: 40.0,
                      color: FlutterFlowTheme.of(context).secondary,
                      textStyle:
                          FlutterFlowTheme.of(context).titleSmall.override(
                                font: GoogleFonts.interTight(),
                                color: Colors.white,
                              ),
                    ),
                  ),
                ),
                const SizedBox(width: 8.0),
                FFButtonWidget(
                  onPressed: () {
                    context.pushNamed(
                      ProductcreateWidget.routeName,
                      queryParameters: {
                        'productRef': serializeParam(
                          widget.product.reference,
                          ParamType.DocumentReference,
                        ),
                      }.withoutNulls,
                    );
                  },
                  text: 'Edit',
                  options: FFButtonOptions(
                    height: 40.0,
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    color: FlutterFlowTheme.of(context).primary,
                    textStyle:
                        FlutterFlowTheme.of(context).titleSmall.override(
                              font: GoogleFonts.interTight(),
                              color: Colors.white,
                            ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
