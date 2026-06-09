import '/backend/schema/product_record.dart';

String normalizeProductSearchText(String value) =>
    value.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');

List<ProductRecord> filterProductsBySearchQuery(
  List<ProductRecord> products,
  String input,
) {
  final query = normalizeProductSearchText(input);
  if (query.isEmpty) {
    return products;
  }
  return products.where((product) {
    final haystack = [
      product.name,
      product.sku,
      product.category,
    ].join(' ').toLowerCase();
    return haystack.contains(query);
  }).toList();
}

List<ProductRecord> filterProductsByCategory(
  List<ProductRecord> products,
  String? category,
) {
  if (category == null || category.isEmpty) {
    return products;
  }
  return products
      .where((product) => product.category == category)
      .toList();
}

List<String> extractProductCategories(List<ProductRecord> products) {
  final categories = products
      .map((product) => product.category.trim())
      .where((category) => category.isNotEmpty)
      .toSet()
      .toList()
    ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
  return categories;
}

List<ProductRecord> applyProductSelectionFilters({
  required List<ProductRecord> products,
  required String searchQuery,
  String? category,
}) {
  final searched = filterProductsBySearchQuery(products, searchQuery);
  final filtered = filterProductsByCategory(searched, category);
  return [...filtered]
    ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
}
