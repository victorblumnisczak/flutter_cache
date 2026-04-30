import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../controllers/product_list_controller.dart';
import '../models/product.dart';
import '../repository/product_repository.dart';
import '../state/product_list_state.dart';
import 'product_detail_page.dart';

class ProductListPage extends StatefulWidget {
  final ProductListController controller;

  const ProductListPage({super.key, required this.controller});

  @override
  State<ProductListPage> createState() => _ProductListPageState();
}

class _ProductListPageState extends State<ProductListPage> {
  @override
  void initState() {
    super.initState();
    widget.controller.load();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) {
        final state = widget.controller.state;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Catálogo de Produtos'),
            actions: [
              _SourceIndicator(source: state.source, cachedAt: state.cachedAt),
              IconButton(
                onPressed: () => widget.controller.load(forceRefresh: true),
                icon: const Icon(Icons.refresh),
                tooltip: 'Forçar atualização',
              ),
            ],
            bottom: state.status == ProductListStatus.refreshing
                ? const PreferredSize(
                    preferredSize: Size.fromHeight(3),
                    child: LinearProgressIndicator(),
                  )
                : null,
          ),
          body: _buildBody(state),
        );
      },
    );
  }

  Widget _buildBody(ProductListState state) {
    switch (state.status) {
      case ProductListStatus.loading:
        return const Center(child: CircularProgressIndicator());

      case ProductListStatus.error:
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  state.message ?? 'Erro desconhecido.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: () => widget.controller.load(),
                  child: const Text('Tentar novamente'),
                ),
              ],
            ),
          ),
        );

      case ProductListStatus.empty:
        return const Center(child: Text('Nenhum produto encontrado.'));

      case ProductListStatus.idle:
        return const SizedBox.shrink();

      case ProductListStatus.success:
      case ProductListStatus.refreshing:
        return _buildList(state);
    }
  }

  Widget _buildList(ProductListState state) {
    return Column(
      children: [
        if (state.message != null)
          Material(
            color: Colors.amber.shade100,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, size: 16),
                  const SizedBox(width: 8),
                  Expanded(child: Text(state.message!, style: const TextStyle(fontSize: 13))),
                ],
              ),
            ),
          ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () => widget.controller.load(forceRefresh: true),
            child: ListView.separated(
              itemCount: state.products.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                return _ProductTile(
                  product: state.products[index],
                  onTap: () => _openDetails(state.products[index]),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  void _openDetails(Product product) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProductDetailPage(product: product),
      ),
    );
    // Não recarrega ao voltar — o cache em memória mantém a lista intacta.
  }
}

class _ProductTile extends StatelessWidget {
  final Product product;
  final VoidCallback onTap;

  const _ProductTile({required this.product, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.all(12),
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: CachedNetworkImage(
          imageUrl: product.thumbnail,
          width: 72,
          height: 72,
          fit: BoxFit.cover,
          placeholder: (context, url) => Container(
            width: 72,
            height: 72,
            color: Colors.grey.shade200,
          ),
          errorWidget: (context, url, error) => Container(
            width: 72,
            height: 72,
            color: Colors.grey.shade300,
            child: const Icon(Icons.broken_image),
          ),
        ),
      ),
      title: Text(
        product.title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        '${product.category} • R\$ ${product.price.toStringAsFixed(2)}',
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      onTap: onTap,
    );
  }
}

class _SourceIndicator extends StatelessWidget {
  final ProductSource? source;
  final DateTime? cachedAt;

  const _SourceIndicator({this.source, this.cachedAt});

  @override
  Widget build(BuildContext context) {
    if (source == null) return const SizedBox.shrink();

    final (icon, label) = switch (source!) {
      ProductSource.memory => (Icons.memory, 'Memória'),
      ProductSource.local => (Icons.storage, 'Disco'),
      ProductSource.remote => (Icons.cloud_done, 'Rede'),
    };

    final when = cachedAt != null
        ? '${cachedAt!.hour.toString().padLeft(2, '0')}:${cachedAt!.minute.toString().padLeft(2, '0')}'
        : '';

    return Tooltip(
      message: 'Fonte: $label${when.isNotEmpty ? ' ($when)' : ''}',
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Icon(icon, size: 20),
      ),
    );
  }
}
