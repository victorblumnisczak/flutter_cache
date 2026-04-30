import '../data/product_api.dart';
import '../data/product_local_cache.dart';
import '../data/product_memory_cache.dart';
import 'product_repository.dart';

class ProductRepositoryImpl implements ProductRepository {
  final ProductApi _api;
  final ProductMemoryCache _memoryCache;
  final ProductLocalCache _localCache;

  ProductRepositoryImpl({
    required ProductApi api,
    required ProductMemoryCache memoryCache,
    required ProductLocalCache localCache,
  })  : _api = api,
        _memoryCache = memoryCache,
        _localCache = localCache;

  @override
  Stream<ProductFetchResult> getProducts({bool forceRefresh = false}) async* {
    // Stale-While-Revalidate: emite cache imediatamente e revalida em background.

    // 1. Cache em memória dentro do TTL — sem forceRefresh
    if (!forceRefresh) {
      final memoryCached = _memoryCache.getIfValid();
      if (memoryCached != null) {
        yield ProductFetchResult(
          products: memoryCached,
          source: ProductSource.memory,
          cachedAt: _memoryCache.cachedAt,
          isFresh: false,
        );
        // Revalida em background e emite o resultado fresco
        yield* _fetchFromNetwork(hasLocalFallback: true);
        return;
      }
    }

    // 2. Cache local como conteúdo intermediário enquanto a rede carrega
    final localProducts = _localCache.getProducts();
    final hasLocalFallback = localProducts != null && localProducts.isNotEmpty;

    if (localProducts != null && localProducts.isNotEmpty) {
      _memoryCache.save(localProducts);
      yield ProductFetchResult(
        products: localProducts,
        source: ProductSource.local,
        cachedAt: _localCache.getCachedAt(),
        isFresh: false,
      );
    }

    // 3. Busca remota — sempre que não havia cache em memória válido
    yield* _fetchFromNetwork(hasLocalFallback: hasLocalFallback);
  }

  Stream<ProductFetchResult> _fetchFromNetwork({
    bool hasLocalFallback = false,
  }) async* {
    try {
      final products = await _api.fetchProducts();
      _memoryCache.save(products);
      await _localCache.save(products);
      yield ProductFetchResult(
        products: products,
        source: ProductSource.remote,
        cachedAt: DateTime.now(),
        isFresh: true,
      );
    } catch (e) {
      // Se já havia dados de cache sendo exibidos, a falha de rede é silenciosa.
      if (!hasLocalFallback) rethrow;
    }
  }
}
