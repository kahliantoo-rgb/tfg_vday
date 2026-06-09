import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '/backend/backend.dart';
import '/backend/custom_product_helpers.dart';
import '/backend/order_item_helpers.dart';
import '/backend/product_category_helpers.dart';
import '/backend/product_edit_helpers.dart';
import '/backend/product_selection_helpers.dart';
import '/backend/tenant_query_helpers.dart';
import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';
import '/flutter_flow/flutter_flow_widgets.dart';

/// Inline catalog picker + custom product form for editing order line items.
class OrderProductAddPanel extends StatefulWidget {
  const OrderProductAddPanel({
    super.key,
    required this.orderRef,
    required this.onItemsChanged,
  });

  final DocumentReference orderRef;
  final Future<void> Function() onItemsChanged;

  @override
  State<OrderProductAddPanel> createState() => _OrderProductAddPanelState();
}

class _OrderProductAddPanelState extends State<OrderProductAddPanel> {
  final _searchController = TextEditingController();
  final _customNameController = TextEditingController();
  final _customRemarkController = TextEditingController();
  final _customPriceController = TextEditingController();
  String? _selectedCategory;
  bool _addingCustom = false;

  @override
  void dispose() {
    _searchController.dispose();
    _customNameController.dispose();
    _customRemarkController.dispose();
    _customPriceController.dispose();
    super.dispose();
  }

  Future<void> _afterItemAdded(String message) async {
    await recalculateOrderTotals(widget.orderRef);
    await widget.onItemsChanged();
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _addCatalogProduct(ProductRecord product) async {
    await addCatalogProductToOrderItem(
      orderRef: widget.orderRef,
      product: product,
    );
    await _afterItemAdded('Added ${product.name}');
  }

  Future<void> _createCustomProduct() async {
    setState(() => _addingCustom = true);
    try {
      final added = await submitCustomProductWithPhotoChoice(
        context: context,
        orderRef: widget.orderRef,
        name: _customNameController.text,
        qty: 1,
        price: double.tryParse(_customPriceController.text.trim()),
        remark: _customRemarkController.text,
      );
      if (!added || !mounted) {
        return;
      }
      _customNameController.clear();
      _customRemarkController.clear();
      _customPriceController.clear();
      await _afterItemAdded('Custom product added');
    } finally {
      if (mounted) {
        setState(() => _addingCustom = false);
      }
    }
  }

  Widget _buildSearchAndFilter(
    BuildContext context,
    List<String> categories,
  ) {
    final theme = FlutterFlowTheme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search products',
              prefixIcon: const Icon(Icons.search),
              isDense: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onChanged: (_) => setState(() {}),
          ),
          if (categories.isNotEmpty) ...[
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Category',
                style: theme.labelMedium.override(
                  color: theme.secondaryText,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 6),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  FilterChip(
                    label: const Text('All'),
                    selected: _selectedCategory == null,
                    onSelected: (_) {
                      setState(() => _selectedCategory = null);
                    },
                  ),
                  for (final category in categories)
                    Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: FilterChip(
                        label: Text(category),
                        selected: _selectedCategory == category,
                        onSelected: (_) {
                          setState(() => _selectedCategory = category);
                        },
                      ),
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildProductGrid(
    BuildContext context,
    List<ProductRecord> products,
  ) {
    final theme = FlutterFlowTheme.of(context);
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.72,
      ),
      itemCount: products.length,
      itemBuilder: (context, index) {
        final product = products[index];
        final priceText = formatNumber(
          product.price,
          formatType: FormatType.decimal,
          decimalType: DecimalType.automatic,
          currency: '',
        );
        return Card(
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AspectRatio(
                aspectRatio: 1,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return buildZoomableProductImage(
                      context: context,
                      imageUrl: productImageFromRecord(product),
                      productRef: product.reference,
                      title: product.name,
                      width: constraints.maxWidth,
                      height: constraints.maxHeight,
                      fit: BoxFit.cover,
                      placeholderIcon: Icons.local_florist_outlined,
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
                child: Text(
                  product.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.labelLarge,
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 4, 8, 0),
                child: Text('\$$priceText', style: theme.titleSmall),
              ),
              Padding(
                padding: const EdgeInsets.all(8),
                child: FFButtonWidget(
                  onPressed: () => _addCatalogProduct(product),
                  text: 'Add',
                  options: FFButtonOptions(
                    width: double.infinity,
                    height: 36,
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
  }

  Widget _buildCustomProductSection(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Custom product',
            style: theme.titleSmall.override(
              font: GoogleFonts.interTight(fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _customNameController,
            decoration: InputDecoration(
              hintText: 'Custom product name',
              isDense: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _customRemarkController,
            decoration: InputDecoration(
              hintText: 'Remark',
              isDense: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _customPriceController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    hintText: 'Price',
                    isDense: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              FFButtonWidget(
                onPressed: _addingCustom ? null : _createCustomProduct,
                text: _addingCustom ? 'Adding...' : 'Create',
                options: FFButtonOptions(
                  width: 100,
                  height: 44,
                  color: theme.secondary,
                  textStyle: theme.titleSmall.override(
                    color: Colors.white,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    return Material(
      color: Colors.transparent,
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.92,
        ),
        decoration: BoxDecoration(
          color: theme.secondaryBackground,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 50,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFF1F4F8),
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 12, 8, 0),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Expanded(
                    child: Text(
                      'Add Products',
                      style: theme.headlineSmall,
                    ),
                  ),
                ],
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    StreamBuilder<List<ProductRecord>>(
                      stream: queryActiveProductsForTenant(),
                      builder: (context, snapshot) {
                        if (snapshot.hasError) {
                          return Padding(
                            padding: const EdgeInsets.all(16),
                            child: Text('Cannot load products: ${snapshot.error}'),
                          );
                        }
                        if (!snapshot.hasData) {
                          return const Padding(
                            padding: EdgeInsets.all(32),
                            child: Center(child: CircularProgressIndicator()),
                          );
                        }
                        final products = snapshot.data!;
                        if (products.isEmpty) {
                          return const Padding(
                            padding: EdgeInsets.all(16),
                            child: Text('No active products for your company.'),
                          );
                        }

                        final filteredProducts = applyProductSelectionFilters(
                          products: products,
                          searchQuery: _searchController.text,
                          category: _selectedCategory,
                        );

                        return StreamBuilder<List<String>>(
                          stream: streamTenantProductCategories(),
                          builder: (context, categorySnapshot) {
                            final categories = mergeProductCategoryOptions(
                              managedCategories: categorySnapshot.data ??
                                  defaultProductCategories,
                              productCategories:
                                  extractProductCategories(products),
                            );
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _buildSearchAndFilter(context, categories),
                                if (filteredProducts.isEmpty)
                                  Padding(
                                    padding: const EdgeInsets.all(24),
                                    child: Text(
                                      'No products match your search or filter.',
                                      textAlign: TextAlign.center,
                                      style: theme.bodyMedium,
                                    ),
                                  )
                                else
                                  _buildProductGrid(
                                    context,
                                    filteredProducts,
                                  ),
                              ],
                            );
                          },
                        );
                      },
                    ),
                    const Divider(height: 24),
                    _buildCustomProductSection(context),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

void showOrderProductAddPanel(
  BuildContext context, {
  required DocumentReference orderRef,
  required Future<void> Function() onItemsChanged,
}) {
  showModalBottomSheet(
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    context: context,
    builder: (sheetContext) {
      return Padding(
        padding: MediaQuery.viewInsetsOf(sheetContext),
        child: OrderProductAddPanel(
          orderRef: orderRef,
          onItemsChanged: onItemsChanged,
        ),
      );
    },
  );
}
