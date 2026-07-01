import 'package:flutter/material.dart';

import '/flutter_flow/flutter_flow_theme.dart';
import '/flutter_flow/flutter_flow_util.dart';

/// Search box + horizontal category chips (shared by product list & selection).
class ProductSearchFilterPanel extends StatelessWidget {
  const ProductSearchFilterPanel({
    super.key,
    required this.searchController,
    required this.searchFocusNode,
    required this.selectedCategory,
    required this.categories,
    required this.onSearchChanged,
    required this.onCategoryChanged,
    this.padding = const EdgeInsets.fromLTRB(12, 12, 12, 8),
  });

  final TextEditingController searchController;
  final FocusNode searchFocusNode;
  final String? selectedCategory;
  final List<String> categories;
  final VoidCallback onSearchChanged;
  final ValueChanged<String?> onCategoryChanged;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final theme = FlutterFlowTheme.of(context);
    final hasSearchText = searchController.text.isNotEmpty;

    return Padding(
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: searchController,
            focusNode: searchFocusNode,
            onChanged: (_) => onSearchChanged(),
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              isDense: true,
              hintText: tr(context, 'product.select.searchHint'),
              prefixIcon: const Icon(Icons.search),
              suffixIcon: hasSearchText
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        searchController.clear();
                        onSearchChanged();
                      },
                    )
                  : null,
              filled: true,
              fillColor: theme.secondaryBackground,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: theme.alternate),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: theme.alternate),
              ),
            ),
          ),
          if (categories.isNotEmpty) ...[
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                tr(context, 'product.select.category'),
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
                    label: Text(tr(context, 'common.all')),
                    selected: selectedCategory == null,
                    onSelected: (_) => onCategoryChanged(null),
                  ),
                  for (final category in categories)
                    Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: FilterChip(
                        label: Text(category),
                        selected: selectedCategory == category,
                        onSelected: (_) => onCategoryChanged(category),
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
}
