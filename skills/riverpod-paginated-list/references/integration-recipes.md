# Integration Recipes

## Basic List

Use this shape for the common case:

```dart
final pagingConfig = PaginatedListConfig<Product>(
  watchPage: (paging) => productsProvider(paging),
  pageSize: 20,
);

final isEmpty = pagingConfig.watchIsEmpty(ref);
if (isEmpty == true) {
  return const Center(child: Text('No products found.'));
}

if (isEmpty == null) {
  return const Center(child: CircularProgressIndicator());
}

return ListView.builder(
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
);
```

Notes:

- Use `watchIsEmpty` or `watchHasItems` before rendering an empty state.
- Do not pass a fixed `itemCount` for the normal infinite-scroll case.

## Skeleton-first List

Use `SkeletonConfig` only for the initial page:

```dart
final pagingConfig = PaginatedListConfig<Product>(
  watchPage: (paging) => productsProvider(paging),
  skeleton: SkeletonConfig(
    itemCount: 10,
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
      builder: (product, dataIndex) => ProductTile(product: product),
    );
  },
);
```

Notes:

- `getItemCount(ref)` is non-null only during skeleton loading.
- `getScrollPhysics(ref)` disables scrolling during skeleton loading.
- Keep `useCache: true` if refreshed data should keep showing instead of falling back to skeletons.

## External Items

Inject fixed widgets into the scrolling list without changing page fetches:

```dart
final pagingConfig = PaginatedListConfig<Product>(
  watchPage: (paging) => productsProvider(paging),
  externalItems: <int, Widget Function(BuildContext)>{
    0: (context) => const HeaderWidget(),
    6: (context) => const AdBanner(),
  },
);
```

Notes:

- The injected widgets consume `viewIndex` positions.
- The item builder receives the adjusted `dataIndex`.
- Keep this distinction in mind when showing row numbers or analytics events.

## One-Based APIs

Use this when the backend expects pages `1, 2, 3...`:

```dart
final pagingConfig = PaginatedListConfig<Product>(
  watchPage: (paging) => productsProvider(paging),
  firstPageIsZeroBased: false,
);

final productsProvider = FutureProvider.family<IList<Product>, Paging>((ref, paging) async {
  return api.fetchProducts(
    page: paging.page,
    offset: paging.offset,
    limit: paging.pageSize,
  );
});
```

Notes:

- `paging.offset` still starts at `0` for the first page.
- Only the page number changes between zero-based and one-based modes.

## Common Fixes

- Wrong backend offset:
  Use `paging.offset`, not `paging.page * someOtherPageSize`.
- Empty state flashes during load:
  Treat `watchIsEmpty(ref) == null` as loading.
- Refreshed data disappears during reload:
  Leave `useCache` at `true`.
- Header or ad shifts item numbering:
  Use the `dataIndex` provided to the item builder, not the `viewIndex`.
- Retry button does nothing:
  Invalidate the same provider instance produced by `watchPage(paging)`.
