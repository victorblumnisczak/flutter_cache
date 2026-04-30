import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/product.dart';

class ProductLocalCache {
  static const _keyProducts = 'cached_products';
  static const _keyTimestamp = 'cached_products_at';

  final SharedPreferences _prefs;

  ProductLocalCache(this._prefs);

  Future<void> save(List<Product> products) async {
    final encoded = products.map((p) => jsonEncode(p.toMap())).toList();
    await _prefs.setStringList(_keyProducts, encoded);
    await _prefs.setString(_keyTimestamp, DateTime.now().toIso8601String());
  }

  List<Product>? getProducts() {
    final encoded = _prefs.getStringList(_keyProducts);
    if (encoded == null || encoded.isEmpty) return null;
    return encoded
        .map((s) => Product.fromMap(jsonDecode(s) as Map<String, dynamic>))
        .toList();
  }

  DateTime? getCachedAt() {
    final raw = _prefs.getString(_keyTimestamp);
    if (raw == null) return null;
    return DateTime.tryParse(raw);
  }

  Future<void> clear() async {
    await _prefs.remove(_keyProducts);
    await _prefs.remove(_keyTimestamp);
  }
}
