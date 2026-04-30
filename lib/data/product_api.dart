import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/product.dart';

class ProductApi {
  final http.Client _client;

  ProductApi({http.Client? client}) : _client = client ?? http.Client();

  Future<List<Product>> fetchProducts() async {
    // Delay artificial mantido intencionalmente para evidenciar o ganho do cache
    // em ambiente didático. Em produção, este delay não existiria.
    await Future.delayed(const Duration(seconds: 2));

    final response = await _client.get(
      Uri.parse('https://dummyjson.com/products?limit=30'),
    );

    if (response.statusCode != 200) {
      throw Exception('Erro ao buscar produtos: ${response.statusCode}');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final raw = data['products'] as List<dynamic>;
    return raw
        .map((item) => Product.fromMap(item as Map<String, dynamic>))
        .toList();
  }
}
