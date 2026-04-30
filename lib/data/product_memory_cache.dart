import '../models/product.dart';

class ProductMemoryCache {
  List<Product>? _products;
  DateTime? _cachedAt;
  final Duration ttl;

  ProductMemoryCache({this.ttl = const Duration(minutes: 5)});

  List<Product>? getIfValid() {
    if (_products == null || _cachedAt == null) return null;
    if (DateTime.now().difference(_cachedAt!) > ttl) return null;
    return _products;
  }

  void save(List<Product> products) {
    _products = products;
    _cachedAt = DateTime.now();
  }

  void clear() {
    _products = null;
    _cachedAt = null;
  }

  bool get hasData => _products != null && _products!.isNotEmpty;

  /// Retorna os produtos mesmo que o TTL tenha expirado (útil para Stale-While-Revalidate).
  List<Product>? get rawProducts => _products;

  DateTime? get cachedAt => _cachedAt;
}
