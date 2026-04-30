import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'controllers/product_list_controller.dart';
import 'data/product_api.dart';
import 'data/product_local_cache.dart';
import 'data/product_memory_cache.dart';
import 'pages/product_list_page.dart';
import 'repository/product_repository_impl.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();

  final api = ProductApi();
  final memoryCache = ProductMemoryCache();
  final localCache = ProductLocalCache(prefs);
  final repository = ProductRepositoryImpl(
    api: api,
    memoryCache: memoryCache,
    localCache: localCache,
  );
  final controller = ProductListController(repository);

  runApp(MyApp(controller: controller));
}

class MyApp extends StatelessWidget {
  final ProductListController controller;

  const MyApp({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Catálogo de Produtos',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: ProductListPage(controller: controller),
    );
  }
}
