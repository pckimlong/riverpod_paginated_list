# Riverpod Paginated List

A lightweight pagination utility for Flutter with Riverpod. Provides efficient infinite scrolling with skeleton loading, external items injection, and support for both zero-based and one-based pagination.

## Features

- 🔄 **Infinite scrolling** - Automatic page loading as user scrolls
- 💀 **Skeleton loading** - Optional shimmer/skeleton placeholders during first page load
- 📦 **External items** - Inject headers, ads, or banners at specific positions
- 🔢 **Flexible pagination** - Support for both zero-based (0, 1, 2...) and one-based (1, 2, 3...) page numbering
- ⚡ **Efficient** - Only loads visible pages, disposes off-screen data

## Installation

Add to your `pubspec.yaml`:

```yaml
dependencies:
  riverpod_paginated_list:
    path: ../packages/riverpod_paginated_list
```

## Usage

### Basic Usage

```dart
import 'package:riverpod_paginated_list/riverpod_paginated_list.dart';

class ProductListPage extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pagingConfig = PaginatedListConfig<Product>(
      watchPage: (paging) => productsProvider(paging: paging),
    );

    if (pagingConfig.watchHasItems(ref) == false) {
      return const Center(child: Text('No products found.'));
    }

    return ListView.builder(
      itemBuilder: (context, index) {
        return pagingConfig.buildItem(
          context: context,
          ref: ref,
          viewIndex: index,
          builder: (product, dataIndex) => ProductTile(product),
        );
      },
    );
  }
}
```

### With Skeleton Loading

```dart
final pagingConfig = PaginatedListConfig<Product>(
  watchPage: (paging) => productsProvider(paging: paging),
  skeleton: SkeletonConfig(
    itemCount: 15,
    itemBuilder: (context, index) => const ProductSkeletonTile(),
  ),
);

return ListView.builder(
  physics: pagingConfig.getScrollPhysics(ref),
  itemCount: pagingConfig.getItemCount(ref),
  itemBuilder: (context, index) {
    return pagingConfig.buildItem(
      context: context,
      ref: ref,
      viewIndex: index,
      builder: (product, dataIndex) => ProductTile(product),
    );
  },
);
```

### With External Items (Headers, Ads)

```dart
final pagingConfig = PaginatedListConfig<Product>(
  watchPage: (paging) => productsProvider(paging: paging),
  externalItems: {
    0: (context) => const HeaderWidget(),
    5: (context) => const AdBanner(),
  }.lock,
);
```

### One-Based Pagination

Some APIs use 1-based page numbers. Configure like this:

```dart
final pagingConfig = PaginatedListConfig<Product>(
  watchPage: (paging) => productsProvider(paging: paging),
  firstPageIsZeroBased: false, // Pages: 1, 2, 3...
);
```

### Provider Example

```dart
@riverpod
Future<IList<Product>> products(Ref ref, {required Paging paging}) async {
  final response = await api.getProducts(
    offset: paging.offset,
    limit: paging.pageSize,
  );
  return response.toIList();
}
```

## API Reference

### Paging

An extension type representing pagination parameters.

- `page` - Current page number
- `pageSize` - Number of items per page
- `offset` - Calculated offset for database queries
- `firstPageIsZeroBased` - Whether first page is 0 or 1

### PaginatedListConfig

Configuration class for paginated lists.

| Property | Type | Description |
|----------|------|-------------|
| `watchPage` | `Function` | Provider factory for fetching pages |
| `pageSize` | `int` | Items per page (default: 30) |
| `firstPageIsZeroBased` | `bool` | Use 0-based pages (default: true) |
| `externalItems` | `ExternalItems?` | Map of positions to widget builders |
| `skeleton` | `SkeletonConfig?` | Skeleton loading configuration |

#### Methods

| Method | Returns | Description |
|--------|---------|-------------|
| `buildItem()` | `Widget?` | Builds item widget for given index |
| `watchIsLoading(ref)` | `bool` | True if first page is loading |
| `watchIsEmpty(ref)` | `bool?` | True if list is empty, null while loading |
| `watchHasItems(ref)` | `bool?` | True if list has items, null while loading |
| `getItemCount(ref)` | `int?` | Item count for skeleton mode, null otherwise |
| `getScrollPhysics(ref)` | `ScrollPhysics?` | Disabled physics during skeleton loading |

### SkeletonConfig

Configuration for skeleton/shimmer loading.

| Property | Type | Description |
|----------|------|-------------|
| `itemCount` | `int` | Number of skeleton items (default: 20) |
| `itemBuilder` | `Function` | Builder for skeleton widgets |
