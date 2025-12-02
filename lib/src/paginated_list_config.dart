import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:hooks_riverpod/misc.dart' show ProviderListenable, ProviderBase;

import 'paging.dart';
import 'skeleton_config.dart';
import 'types.dart';

/// Configuration for a paginated list with Riverpod.
///
/// This class provides all the utilities needed to build an efficient
/// infinite scrolling list with:
/// - Automatic page loading
/// - Skeleton loading placeholders
/// - External items (headers, ads) injection
/// - Support for zero-based and one-based pagination
///
/// Example:
/// ```dart
/// final config = PaginatedListConfig<Product>(
///   watchPage: (paging) => productsProvider(paging: paging),
///   skeleton: SkeletonConfig(
///     itemCount: 15,
///     itemBuilder: (context, index) => const ProductSkeleton(),
///   ),
/// );
///
/// ListView.builder(
///   physics: config.getScrollPhysics(ref),
///   itemCount: config.getItemCount(ref),
///   itemBuilder: (context, index) => config.buildItem(
///     context: context,
///     ref: ref,
///     viewIndex: index,
///     builder: (product, dataIndex) => ProductTile(product),
///   ),
/// );
/// ```
class PaginatedListConfig<T> {
  /// Creates a paginated list configuration.
  ///
  /// [watchPage] is required and should return a provider for the given page.
  const PaginatedListConfig({
    required this.watchPage,
    this.pageSize = kDefaultPageSize,
    this.firstPageIsZeroBased = true,
    this.externalItems,
    this.skeleton,
  });

  /// Factory function that returns a provider for a given [Paging].
  ///
  /// The provider should return `AsyncValue<IList<T>>` containing the
  /// items for that page.
  final ProviderBase<AsyncValue<IList<T>>> Function(Paging paging) watchPage;

  /// Number of items per page.
  ///
  /// Defaults to [kDefaultPageSize] (30).
  final int pageSize;

  /// Whether the first page is numbered 0 (true) or 1 (false).
  ///
  /// Set to `false` for APIs that use 1-based pagination.
  /// Defaults to `true`.
  final bool firstPageIsZeroBased;

  /// Optional map of view indices to external widget builders.
  ///
  /// When provided, these widgets will be injected at the specified positions,
  /// and data indices will be adjusted accordingly.
  ///
  /// Example:
  /// ```dart
  /// externalItems: {
  ///   0: (context) => const HeaderWidget(),
  ///   5: (context) => const AdBanner(),
  /// }.lock,
  /// ```
  final ExternalItems? externalItems;

  /// Optional skeleton loading configuration.
  ///
  /// When provided, enables skeleton-style loading for first page instead
  /// of showing a loading spinner.
  final SkeletonConfig? skeleton;

  /// The first page number (0 or 1 depending on [firstPageIsZeroBased]).
  int get firstPage => firstPageIsZeroBased ? 0 : 1;

  /// Calculates the data index from a view index, accounting for external items.
  int _getDataIndex(int viewIndex) {
    final external = externalItems;
    if (external == null || external.isEmpty) return viewIndex;
    return viewIndex - external.keys.where((pos) => pos <= viewIndex).length;
  }

  /// Returns a provider for the specified page number.
  ProviderListenable<AsyncValue<IList<T>>> pageProvider(int page) =>
      watchPage(Paging.of(page, pageSize: pageSize, firstPageIsZeroBased: firstPageIsZeroBased));

  /// Returns a provider for the first page.
  ProviderListenable<AsyncValue<IList<T>>> firstPageProvider() => watchPage(
    Paging.of(firstPage, pageSize: pageSize, firstPageIsZeroBased: firstPageIsZeroBased),
  );

  /// Returns true if first page is currently loading.
  bool watchIsLoading(WidgetRef ref) {
    return ref.watch(firstPageProvider()).isLoading;
  }

  /// Returns the item count for ListView.builder.
  ///
  /// - If skeleton mode and loading: returns skeleton itemCount
  /// - Otherwise: returns null (infinite list)
  int? getItemCount(WidgetRef ref) {
    if (skeleton != null && watchIsLoading(ref)) {
      return skeleton!.itemCount;
    }
    return null;
  }

  /// Returns scroll physics based on loading state.
  ///
  /// When skeleton loading, returns [NeverScrollableScrollPhysics] to disable
  /// scrolling. Otherwise returns the provided [physics] or null.
  ScrollPhysics? getScrollPhysics(WidgetRef ref, [ScrollPhysics? physics]) {
    if (skeleton != null && watchIsLoading(ref)) {
      return const NeverScrollableScrollPhysics();
    }
    return physics;
  }

  /// Watches the first page and returns true if the list has no data items.
  ///
  /// Useful for showing empty state in the UI.
  /// Returns `null` while loading, `true` if empty, `false` if has items.
  bool? watchIsEmpty(WidgetRef ref) {
    final firstPageAsync = ref.watch(firstPageProvider());
    return firstPageAsync.whenOrNull(data: (items) => items.isEmpty);
  }

  /// Watches the first page and returns true if the list has data items.
  ///
  /// Useful for conditionally rendering the list.
  /// Returns `null` while loading, `true` if has items, `false` if empty.
  bool? watchHasItems(WidgetRef ref) {
    final firstPageAsync = ref.watch(firstPageProvider());
    return firstPageAsync.whenOrNull(data: (items) => items.isNotEmpty);
  }

  /// Builds an item for the given view index.
  ///
  /// If [skeleton] is configured and first page is loading, returns skeleton item.
  /// If [externalItems] contains a widget at this index, returns that widget.
  /// Otherwise, fetches and builds the paginated data item.
  ///
  /// [context] is the build context.
  /// [ref] is the WidgetRef for watching providers.
  /// [viewIndex] is the index in the ListView (includes external items).
  /// [builder] builds the widget for a data item.
  /// [loadingBuilder] optional builder for loading state (subsequent pages).
  /// [errorBuilder] optional builder for error state.
  Widget? buildItem({
    required BuildContext context,
    required WidgetRef ref,
    required int viewIndex,
    required Widget Function(T item, int dataIndex) builder,
    Widget Function(bool isFirstItem)? loadingBuilder,
    Widget Function(Object error, StackTrace stack, Paging paging)? errorBuilder,
  }) {
    // Skeleton loading mode for first page
    if (skeleton != null && watchIsLoading(ref)) {
      return skeleton!.itemBuilder(context, viewIndex);
    }

    // Check for external item first
    final externalBuilder = externalItems?.get(viewIndex);
    if (externalBuilder != null) {
      return Builder(builder: externalBuilder);
    }

    final dataIndex = _getDataIndex(viewIndex);
    final paging = Paging.ofIndex(
      dataIndex,
      pageSize: pageSize,
      firstPageIsZeroBased: firstPageIsZeroBased,
    );
    final indexInPage = dataIndex % pageSize;

    final itemAsync = ref.watch(
      watchPage(paging).select((value) => value.whenData((list) => list.getOrNull(indexInPage))),
    );

    // Detect if scrolled backward, then we need full loading of disposed items, otherwise
    // it will show awkward flickering due to items being disposed
    final hasNextPage = ref.exists(
      watchPage(
        Paging.of(
          paging.page + 1,
          pageSize: paging.pageSize,
          firstPageIsZeroBased: firstPageIsZeroBased,
        ),
      ),
    );
    final showLoadingAllPageItems = hasNextPage;

    return itemAsync.when(
      data: (item) => item != null ? builder(item, dataIndex) : null,
      loading: () {
        if (indexInPage == 0 && !showLoadingAllPageItems) {
          return loadingBuilder?.call(true) ?? const Text('Loading...');
        }

        if (showLoadingAllPageItems) {
          return loadingBuilder?.call(indexInPage == 0) ?? const Text('Loading...');
        }

        return null;
      },
      error: (e, s) {
        if (indexInPage == 0) {
          return errorBuilder?.call(e, s, paging);
        }
        return null;
      },
    );
  }
}
