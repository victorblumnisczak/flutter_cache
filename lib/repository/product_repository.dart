import '../models/product.dart';

enum ProductSource { memory, local, remote }

class ProductFetchResult {
  final List<Product> products;
  final ProductSource source;
  final DateTime? cachedAt;
  final bool isFresh;

  const ProductFetchResult({
    required this.products,
    required this.source,
    this.cachedAt,
    required this.isFresh,
  });
}

abstract class ProductRepository {
  Stream<ProductFetchResult> getProducts({bool forceRefresh = false});
}
