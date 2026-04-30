import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_problematico_catalog/state/product_list_state.dart';

void main() {
  test('ProductListState.idle() inicializa com status idle e lista vazia', () {
    final state = ProductListState.idle();
    expect(state.status, ProductListStatus.idle);
    expect(state.products, isEmpty);
    expect(state.message, isNull);
  });

  test('copyWith preserva campos não alterados', () {
    final state = ProductListState.idle().copyWith(
      status: ProductListStatus.loading,
    );
    expect(state.status, ProductListStatus.loading);
    expect(state.products, isEmpty);
  });

  test('clearMessage apaga a mensagem existente', () {
    final withMsg = ProductListState.idle().copyWith(message: 'teste');
    final cleared = withMsg.copyWith(clearMessage: true);
    expect(cleared.message, isNull);
  });
}
