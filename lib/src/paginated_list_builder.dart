import 'dart:math';

import 'package:flutter/widgets.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'paginated_list_config.dart';
import 'paging.dart';

/// The pagination state record containing all details needed by the builder.
typedef PaginatedListState<T> = ({
  /// Resolves the item at [index]. Returns `null` if the item belongs to a page
  /// that is currently loading (next page shimmers) or not yet fetched.
  T? Function(int index) itemAt,

  /// The total count of items that the scroll container should render.
  /// Normally: `loadedItemsCount + (hasMore ? skeletonCount : 0)`.
  int? count,

  /// Scroll physics that automatically locks scrolling (NeverScrollableScrollPhysics)
  /// during the initial loading phase, and unlocks it when loaded.
  ScrollPhysics physics,

  /// Initial load state (true if the first page is loading).
  bool isLoading,

  /// Empty state (true if the first page loaded successfully but has no items).
  bool isEmpty,

  /// True if a background request is currently fetching the next page.
  bool isFetchingNext,

  /// Contains the error object if fetching the next page failed.
  /// If non-null, the consumer can render a retry button at the bottom of the list.
  Object? nextPageError,
});

/// A layout-agnostic builder widget that monitors a paginated provider
/// and manages scroll/load triggers dynamically.
class PaginatedListBuilder<T> extends ConsumerStatefulWidget {
  /// Creates a paginated list builder.
  const PaginatedListBuilder({
    super.key,
    required this.config,
    required this.builder,
    this.physics,
  });

  /// The pagination configuration.
  final PaginatedListConfig<T> config;

  /// The builder function that yields the pagination state.
  final Widget Function(BuildContext context, PaginatedListState<T> state) builder;

  /// The base scroll physics to use when the list is not in a loading lock state.
  final ScrollPhysics? physics;

  @override
  ConsumerState<PaginatedListBuilder<T>> createState() => _PaginatedListBuilderState<T>();
}

class _PaginatedListBuilderState<T> extends ConsumerState<PaginatedListBuilder<T>> {
  final Set<int> _requestedPages = {};

  @override
  void initState() {
    super.initState();
    _requestedPages.add(widget.config.firstPage);
  }

  @override
  void didUpdateWidget(covariant PaginatedListBuilder<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.config.watchPage != widget.config.watchPage ||
        oldWidget.config.firstPage != widget.config.firstPage ||
        oldWidget.config.pageSize != widget.config.pageSize) {
      _requestedPages.clear();
      _requestedPages.add(widget.config.firstPage);
    }
  }

  @override
  Widget build(BuildContext context) {
    final firstPage = widget.config.firstPage;
    final pageSize = widget.config.pageSize;
    final skeletonCount = widget.config.skeleton?.itemCount ?? 3;

    // Reset requested pages if first page is loading from scratch (refresh/initial)
    final firstPageAsync = ref.watch(widget.config.firstPageProvider());
    if (firstPageAsync.isLoading && !firstPageAsync.hasValue) {
      _requestedPages.clear();
      _requestedPages.add(firstPage);
    }

    int loadedDataCount = 0;
    bool hasMore = true;
    bool isFetchingNext = false;
    Object? nextPageError;
    int? failedPage;

    // Sort to ensure we iterate pages in order
    final sortedRequestedPages = _requestedPages.toList()..sort();

    for (final page in sortedRequestedPages) {
      final pageAsync = ref.watch(widget.config.pageProvider(page));

      if (pageAsync.hasValue) {
        final list = pageAsync.value!;
        loadedDataCount += list.length;
        if (list.length < pageSize) {
          hasMore = false;
        }
      } else {
        if (pageAsync.isLoading) {
          if (page != firstPage) {
            isFetchingNext = true;
          }
          hasMore = true;
        }
        if (pageAsync.hasError) {
          if (page > firstPage) {
            nextPageError = pageAsync.error;
            failedPage = page;
          }
        }
        break;
      }
    }

    // If the last page in requested list loaded successfully and has exactly `pageSize` items,
    // we still have more data to load.
    if (sortedRequestedPages.isNotEmpty) {
      final lastRequestedPage = sortedRequestedPages.last;
      final lastPageAsync = ref.watch(widget.config.pageProvider(lastRequestedPage));
      if (lastPageAsync.hasValue && lastPageAsync.value!.length == pageSize) {
        hasMore = true;
      }
    }

    final isLoading = firstPageAsync.isLoading && !firstPageAsync.hasValue;
    final isEmpty = firstPageAsync.hasValue && firstPageAsync.value!.isEmpty;

    // Register retry callback on config
    if (failedPage != null) {
      PaginatedListConfig.retryCallbacks[widget.config] = () {
        ref.invalidate(widget.config.pageProvider(failedPage!));
      };
    } else {
      PaginatedListConfig.retryCallbacks[widget.config] = null;
    }

    // Determine count
    int? count;
    if (widget.config.skeleton != null && isLoading) {
      count = widget.config.skeleton!.itemCount;
    } else if (!hasMore) {
      count = _calculateCount(loadedDataCount, false, 0);
    } else {
      count = null;
    }

    // Determine scroll physics
    ScrollPhysics physics;
    if (widget.config.skeleton != null && isLoading) {
      physics = const NeverScrollableScrollPhysics();
    } else {
      physics = widget.physics ?? const ScrollPhysics();
    }

    T? itemAt(int viewIndex) {
      if (widget.config.externalItems?.containsKey(viewIndex) ?? false) {
        return null;
      }

      final dataIndex = widget.config.getDataIndex(viewIndex);
      if (dataIndex < 0) return null;

      // If we have loaded all data and this index is out of bounds, return null immediately
      if (!hasMore && dataIndex >= loadedDataCount) {
        return null;
      }

      final paging = Paging.ofIndex(
        dataIndex,
        pageSize: pageSize,
        firstPageIsZeroBased: widget.config.firstPageIsZeroBased,
      );
      final indexInPage = dataIndex % pageSize;

      // Check if page is requested. If not, request it.
      if (!_requestedPages.contains(paging.page)) {
        _requestedPages.add(paging.page);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) setState(() {});
        });
      }

      final pageAsync = ref.read(widget.config.pageProvider(paging.page));
      return pageAsync.value?.getOrNull(indexInPage);
    }

    final state = (
      itemAt: itemAt,
      count: count,
      physics: physics,
      isLoading: isLoading,
      isEmpty: isEmpty,
      isFetchingNext: isFetchingNext,
      nextPageError: nextPageError,
    );

    return widget.builder(context, state);
  }

  int _calculateCount(int dataCount, bool hasMore, int skeletonCount) {
    final external = widget.config.externalItems;
    if (external == null || external.isEmpty) {
      return dataCount + (hasMore ? skeletonCount : 0);
    }

    int targetDataCount = dataCount + (hasMore ? skeletonCount : 0);
    int viewIndex = 0;
    int dataIndex = 0;

    while (dataIndex < targetDataCount) {
      if (external.containsKey(viewIndex)) {
        viewIndex++;
      } else {
        viewIndex++;
        dataIndex++;
      }
    }

    if (!hasMore) {
      final maxExternalKey = external.keys.reduce((a, b) => a > b ? a : b);
      if (maxExternalKey >= viewIndex) {
        return maxExternalKey + 1;
      }
    }

    return viewIndex;
  }
}
