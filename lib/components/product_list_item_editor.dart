import 'package:flutter/material.dart';

import '/backend/create_order_service.dart';
import '/backend/product_edit_helpers.dart';
import '/backend/schema/product_record.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/index.dart';

/// Tappable product row — opens the edit page on tap; delete when allowed.
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
  bool _deleting = false;

  ProductRecord get product => widget.product;

  void _openProductEdit(BuildContext context) {
    if (_deleting) {
      return;
    }
    context.pushNamed(
      ProductcreateWidget.routeName,
      queryParameters: {
        'productRef': serializeParam(
          product.reference,
          ParamType.DocumentReference,
        ),
      }.withoutNulls,
    );
  }

  Future<void> _confirmDelete(BuildContext context) async {
    if (_deleting) {
      return;
    }

    final label = product.name.isNotEmpty ? product.name : product.reference.id;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete product?'),
        content: Text(
          'Permanently delete "$label"?\n\n'
          'This cannot be undone. Existing orders that used this product '
          'keep their line items.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: TextButton.styleFrom(
              foregroundColor: FlutterFlowTheme.of(context).error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) {
      return;
    }

    setState(() => _deleting = true);
    try {
      await deleteProductRecord(product);
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Deleted "$label".')),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Delete failed: ${describeFirestoreError(error)}',
          ),
          duration: const Duration(seconds: 8),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _deleting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final priceText = product.price.truncateToDouble() == product.price
        ? product.price.toStringAsFixed(0)
        : product.price.toStringAsFixed(2);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            buildZoomableProductImage(
              context: context,
              imageUrl: productImageFromRecord(product),
              productRef: product.reference,
              title: product.name,
              width: 72.0,
              height: 72.0,
            ),
            const SizedBox(width: 12.0),
            Expanded(
              child: InkWell(
                onTap: () => _openProductEdit(context),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.name,
                        style: theme.titleMedium,
                      ),
                      if (product.sku.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 2.0),
                          child: Text(
                            'SKU: ${product.sku}',
                            style: theme.bodySmall,
                          ),
                        ),
                      Padding(
                        padding: const EdgeInsets.only(top: 6.0),
                        child: Text(
                          '\$$priceText · ${product.isActive ? "Active" : "Inactive"}',
                          style: theme.labelMedium,
                        ),
                      ),
                      if (product.category.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 2.0),
                          child: Text(
                            product.category,
                            style: theme.bodySmall,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
            if (_deleting)
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8.0),
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              )
            else ...[
              IconButton(
                tooltip: 'Delete product',
                icon: Icon(Icons.delete_outline, color: theme.error),
                onPressed: () => _confirmDelete(context),
              ),
              InkWell(
                onTap: () => _openProductEdit(context),
                child: Icon(
                  Icons.chevron_right_rounded,
                  color: theme.secondaryText,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
