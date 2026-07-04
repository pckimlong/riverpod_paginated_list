import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod_paginated_list/riverpod_paginated_list.dart';

void main() {
  runApp(const ProviderScope(child: ExampleApp()));
}

class ExampleApp extends StatelessWidget {
  const ExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Riverpod Paginated List Example',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const ProductListPage(),
    );
  }
}

/// Example product model
class Product {
  const Product({
    required this.id,
    required this.name,
    required this.price,
  });

  final int id;
  final String name;
  final double price;
}

/// Simulated API call - replace with your actual data fetching logic
Future<IList<Product>> fetchProducts({
  required int offset,
  required int limit,
}) async {
  // Simulate network delay
  await Future.delayed(const Duration(seconds: 1));

  // Simulate a database with 100 products
  const totalProducts = 100;
  if (offset >= totalProducts) {
    return const IListConst([]);
  }

  final endIndex = (offset + limit).clamp(0, totalProducts);
  return List.generate(
    endIndex - offset,
    (index) => Product(
      id: offset + index,
      name: 'Product ${offset + index + 1}',
      price: (offset + index + 1) * 9.99,
    ),
  ).toIList();
}

/// Provider for fetching products - this is what you'd generate with @riverpod
final productsProvider =
    FutureProvider.family<IList<Product>, Paging>((ref, paging) async {
  return fetchProducts(
    offset: paging.offset,
    limit: paging.pageSize,
  );
});

/// Basic example - simple paginated list
class ProductListPage extends ConsumerWidget {
  const ProductListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pagingConfig = PaginatedListConfig<Product>(
      watchPage: (paging) => productsProvider(paging),
      pageSize: 20,
    );

    // Show empty state (only when confirmed empty, not while loading)
    final isEmpty = pagingConfig.watchIsEmpty(ref);
    if (isEmpty == true) {
      return Scaffold(
        appBar: AppBar(title: const Text('Products')),
        body: const Center(child: Text('No products found.')),
      );
    }

    // Show loading state for first page
    if (isEmpty == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Products')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Products'),
        actions: [
          IconButton(
            icon: const Icon(Icons.star),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const SkeletonExamplePage()),
              );
            },
            tooltip: 'Skeleton Example',
          ),
          IconButton(
            icon: const Icon(Icons.view_list),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                    builder: (_) => const ExternalItemsExamplePage()),
              );
            },
            tooltip: 'External Items Example',
          ),
        ],
      ),
      body: ListView.builder(
        itemBuilder: (context, index) {
          return pagingConfig.buildItem(
            context: context,
            ref: ref,
            viewIndex: index,
            builder: (product, dataIndex) => ProductTile(product: product),
            loadingBuilder: (isFirstItem) => const LoadingTile(),
            errorBuilder: (error, stack, paging) => ErrorTile(
              error: error,
              onRetry: () => ref.invalidate(productsProvider(paging)),
            ),
          );
        },
      ),
    );
  }
}

/// Example with skeleton loading
class SkeletonExamplePage extends ConsumerWidget {
  const SkeletonExamplePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pagingConfig = PaginatedListConfig<Product>(
      watchPage: (paging) => productsProvider(paging),
      pageSize: 20,
      skeleton: SkeletonConfig(
        itemCount: 10,
        itemBuilder: (context, index) => const SkeletonTile(),
      ),
    );

    if (pagingConfig.watchIsEmpty(ref) == true) {
      return Scaffold(
        appBar: AppBar(title: const Text('With Skeleton')),
        body: const Center(child: Text('No products found.')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('With Skeleton')),
      body: ListView.builder(
        physics: pagingConfig.getScrollPhysics(ref),
        itemCount: pagingConfig.getItemCount(ref),
        itemBuilder: (context, index) {
          return pagingConfig.buildItem(
            context: context,
            ref: ref,
            viewIndex: index,
            builder: (product, dataIndex) => ProductTile(product: product),
            loadingBuilder: (isFirstItem) => const LoadingTile(),
          );
        },
      ),
    );
  }
}

/// Example with external items (header, ads)
class ExternalItemsExamplePage extends ConsumerWidget {
  const ExternalItemsExamplePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pagingConfig = PaginatedListConfig<Product>(
      watchPage: (paging) => productsProvider(paging),
      pageSize: 20,
      externalItems: <int, Widget Function(BuildContext)>{
        0: (context) => const HeaderWidget(),
        6: (context) => const AdBanner(),
      },
    );

    final isEmpty = pagingConfig.watchIsEmpty(ref);
    if (isEmpty == true) {
      return Scaffold(
        appBar: AppBar(title: const Text('With External Items')),
        body: const Center(child: Text('No products found.')),
      );
    }

    if (isEmpty == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('With External Items')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('With External Items')),
      body: ListView.builder(
        itemBuilder: (context, index) {
          return pagingConfig.buildItem(
            context: context,
            ref: ref,
            viewIndex: index,
            builder: (product, dataIndex) => ProductTile(product: product),
            loadingBuilder: (isFirstItem) => const LoadingTile(),
          );
        },
      ),
    );
  }
}

// ============================================================================
// UI Components
// ============================================================================

class ProductTile extends StatelessWidget {
  const ProductTile({super.key, required this.product});

  final Product product;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(child: Text('${product.id}')),
      title: Text(product.name),
      subtitle: Text('\$${product.price.toStringAsFixed(2)}'),
      trailing: const Icon(Icons.chevron_right),
    );
  }
}

class LoadingTile extends StatelessWidget {
  const LoadingTile({super.key});

  @override
  Widget build(BuildContext context) {
    return const ListTile(
      leading: CircleAvatar(child: CircularProgressIndicator(strokeWidth: 2)),
      title: Text('Loading...'),
    );
  }
}

class SkeletonTile extends StatelessWidget {
  const SkeletonTile({super.key});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(backgroundColor: Colors.grey[300]),
      title: Container(
        height: 16,
        width: 150,
        decoration: BoxDecoration(
          color: Colors.grey[300],
          borderRadius: BorderRadius.circular(4),
        ),
      ),
      subtitle: Container(
        height: 12,
        width: 80,
        margin: const EdgeInsets.only(top: 4),
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(4),
        ),
      ),
    );
  }
}

class ErrorTile extends StatelessWidget {
  const ErrorTile({super.key, required this.error, required this.onRetry});

  final Object error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.error, color: Colors.red),
      title: Text('Error: $error'),
      trailing: TextButton(
        onPressed: onRetry,
        child: const Text('Retry'),
      ),
    );
  }
}

class HeaderWidget extends StatelessWidget {
  const HeaderWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.deepPurple[100],
      child: const Text(
        'Featured Products',
        style: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class AdBanner extends StatelessWidget {
  const AdBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 80,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.amber[100],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.amber),
      ),
      child: const Center(
        child: Text(
          '📢 Special Offer! 20% off all items',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
