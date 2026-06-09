import 'package:flutter/material.dart';

import '/backend/product_edit_helpers.dart';
import '/backend/schema/product_record.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/index.dart';

/// Tappable product row — opens the edit page on tap.
class ProductListItemEditor extends StatelessWidget {
  const ProductListItemEditor({
    super.key,
    required this.product,
  });

  final ProductRecord product;

  void _openProductEdit(BuildContext context) {
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
              InkWell(
                onTap: () => _openProductEdit(context),
                child: Icon(
                  Icons.chevron_right_rounded,
                  color: theme.secondaryText,
                ),
              ),
            ],
        ),
      ),
    );
  }
}
