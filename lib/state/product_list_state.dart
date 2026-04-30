import '../models/product.dart';
import '../repository/product_repository.dart';

enum ProductListStatus {
  idle,
  loading,
  success,
  error,
  empty,
  refreshing,
}

class ProductListState {
  final ProductListStatus status;
  final List<Product> products;
  final String? message;
  final ProductSource? source;
  final DateTime? cachedAt;

  const ProductListState({
    required this.status,
    this.products = const [],
    this.message,
    this.source,
    this.cachedAt,
  });

  factory ProductListState.idle() =>
      const ProductListState(status: ProductListStatus.idle);

  ProductListState copyWith({
    ProductListStatus? status,
    List<Product>? products,
    String? message,
    ProductSource? source,
    DateTime? cachedAt,
    bool clearMessage = false,
  }) {
    return ProductListState(
      status: status ?? this.status,
      products: products ?? this.products,
      message: clearMessage ? null : message ?? this.message,
      source: source ?? this.source,
      cachedAt: cachedAt ?? this.cachedAt,
    );
  }
}
