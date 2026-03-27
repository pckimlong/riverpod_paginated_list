# Package Contract

## Core Types

### `Paging`

- Use `Paging.of(page, pageSize: ..., firstPageIsZeroBased: ...)` when the page number is already known.
- Use `Paging.ofIndex(index, pageSize: ..., firstPageIsZeroBased: ...)` when translating a list position into a page request.
- Use `paging.offset` for `offset`/`limit` APIs.
- Expect equal offsets for zero-based and one-based modes at the same list index; only the visible page number changes.

### `PaginatedListConfig<T>`

- Provide `watchPage`, which must return `ProviderBase<AsyncValue<IList<T>>>` for a given `Paging`.
- Use `pageSize` to define both provider request size and page/index math.
- Set `firstPageIsZeroBased: false` only for APIs that number pages as `1, 2, 3...`.
- Use `externalItems` to reserve view slots for headers, ads, banners, or separators.
- Use `skeleton` to replace the initial loading state with placeholder rows.
- Leave `useCache` at `true` unless the UI must suppress cached data during refresh.

### `SkeletonConfig`

- Configure only first-page placeholder rendering.
- Expect `itemCount` to drive `ListView.builder.itemCount` only while the first page is loading with no cached value.

## `buildItem` Branch Order

`buildItem` resolves a slot in this order:

1. Return a skeleton widget when first-page skeleton loading is active.
2. Return an external widget when `externalItems[viewIndex]` exists.
3. Translate `viewIndex` to `dataIndex`, then resolve the page and index within the page.
4. Return the data widget when the item exists in the current page value.
5. Return `errorBuilder` only when the page has an error and `indexInPage == 0`.
6. Return `loadingBuilder` according to page-loading rules.
7. Return `null` when nothing should render for that slot.

Treat a `null` result as "no widget for this slot yet", not necessarily as a package error.

## Non-Obvious Behaviors

### Cache-aware loading

- `watchIsLoading` returns `true` only when the first page is loading and there is no cached value if `useCache` is enabled.
- With `useCache: true`, refreshed pages can keep rendering old items while Riverpod reports `isLoading`.
- With `useCache: false`, the same refresh can re-enter skeleton or loading states.

### Empty-state semantics

- `watchIsEmpty(ref)` returns:
  - `null` while the first page has no resolved value
  - `true` when the first page resolves to an empty list
  - `false` when the first page resolves to at least one item
- `watchHasItems(ref)` mirrors the same tri-state logic.

### External item index mapping

- `externalItems` changes only the UI positions, not provider page math.
- `viewIndex` counts everything in the list, including external widgets.
- `dataIndex` counts only paginated data items.
- Example:
  - External widget at `viewIndex 0`
  - Data item 0 appears at `viewIndex 1`
  - Builder receives `dataIndex == 0`

### Subsequent-page loading

- The package checks whether the next page provider already exists in the container.
- If it does, loading placeholders can render across the whole loading page to reduce flicker when the user scrolls backward into disposed items.
- If it does not, only the first slot of the loading page uses `loadingBuilder`.

## Source Map

- `lib/src/paging.dart`: page-number and offset math.
- `lib/src/paginated_list_config.dart`: integration contract, list slot resolution, cache and loading behavior.
- `lib/src/skeleton_config.dart`: first-page skeleton configuration.
- `lib/src/types.dart`: `ExternalItems` typedef and default page size.
- `example/lib/main.dart`: end-to-end usage patterns.
- `test/paging_test.dart`: page math invariants.
- `test/paginated_list_dataindex_test.dart`: external-item index translation.
- `test/paginated_list_widget_test.dart`: skeleton, cache, loading, error, and empty-state behavior.

## Change Guidance

- Preserve the `viewIndex` to `dataIndex` translation when modifying external-item behavior.
- Preserve the cache-aware first-page logic unless intentionally changing the public contract.
- Update widget tests when changing `buildItem` branch ordering or loading/error behavior.
