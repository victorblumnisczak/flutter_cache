import 'package:flutter/foundation.dart';

import '../repository/product_repository.dart';
import '../state/product_list_state.dart';

class ProductListController extends ChangeNotifier {
  final ProductRepository repository;

  ProductListState _state = ProductListState.idle();
  ProductListState get state => _state;

  ProductListController(this.repository);

  Future<void> load({bool forceRefresh = false}) async {
    final hasData = _state.products.isNotEmpty;
    _emit(_state.copyWith(
      status: hasData ? ProductListStatus.refreshing : ProductListStatus.loading,
      clearMessage: true,
    ));

    try {
      await for (final result in repository.getProducts(forceRefresh: forceRefresh)) {
        if (result.products.isEmpty && result.isFresh) {
          _emit(_state.copyWith(
            status: ProductListStatus.empty,
            products: const [],
          ));
        } else {
          _emit(_state.copyWith(
            status: ProductListStatus.success,
            products: result.products,
            source: result.source,
            cachedAt: result.cachedAt,
            clearMessage: true,
          ));
        }
      }
    } catch (e) {
      if (_state.products.isNotEmpty) {
        _emit(_state.copyWith(
          status: ProductListStatus.success,
          message: 'Falha ao atualizar. Exibindo dados em cache.',
        ));
      } else {
        _emit(_state.copyWith(
          status: ProductListStatus.error,
          message: 'Falha ao carregar produtos: $e',
        ));
      }
    }
  }

  void _emit(ProductListState s) {
    _state = s;
    notifyListeners();
  }
}
