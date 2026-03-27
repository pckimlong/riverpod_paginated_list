---
name: riverpod-paginated-list
description: Package-specific guidance for integrating, debugging, and extending `riverpod_paginated_list` in Flutter codebases. Use when Codex needs to add an infinite-scrolling Riverpod list, wire `PaginatedListConfig` to page providers, configure skeleton loading, inject headers or ads with `externalItems`, switch between zero-based and one-based pagination, or diagnose loading, empty, retry, and index-mapping behavior produced by this package.
---

# Riverpod Paginated List

## Overview

Use this skill to work from the package's actual contract instead of generic infinite-scroll assumptions. Follow the workflow below, then load the references that match the task.

## Quick Workflow

1. Confirm the page provider contract.
   `watchPage` must map `Paging` to `ProviderBase<AsyncValue<IList<T>>>`.
2. Decide page numbering before debugging offsets.
   Set `firstPageIsZeroBased` correctly for the backend API.
3. Handle the first page separately from later pages.
   Use `watchIsEmpty`, `watchHasItems`, `getItemCount`, and `getScrollPhysics` for the first-page experience.
4. Build rows through `buildItem`.
   Pass the `viewIndex`; let the package translate it to `dataIndex` and page membership.
5. Add retry, loading, and error UI at the page boundary.
   `loadingBuilder` and `errorBuilder` do not render for every slot in a page.

## Package Rules

- Treat `viewIndex` and `dataIndex` as different values when `externalItems` is set. External widgets occupy `viewIndex` slots and shift later data rows.
- Treat `watchIsEmpty` and `watchHasItems` returning `null` as "first page unresolved", not as empty data.
- Treat `getItemCount` as a skeleton-only helper. It returns a finite count only during first-page skeleton loading.
- Keep `useCache` enabled unless a hard reload is required. With `useCache: true`, cached or previous values keep rendering while a new value loads.
- Expect `errorBuilder` only on the first slot of an errored page. Other slots in that page return `null`.
- Expect `loadingBuilder` to be page-aware. When the next page already exists in the provider container, the package may render loading placeholders for every slot in the loading page to reduce backward-scroll flicker.

## References

- Read [references/package-contract.md](references/package-contract.md) for API semantics, source map, and test-backed behavior.
- Read [references/integration-recipes.md](references/integration-recipes.md) for common integration patterns and package-specific code snippets.

## Execution Notes

- Reuse `Paging.offset` when the backend expects `offset` and `limit`.
- Invalidate the exact page provider returned by `watchPage(paging)` when adding retry UI.
- Prefer `ListView.builder` without a fixed `itemCount` unless skeleton loading is active.
- Read the tests before changing behavior in this package; they encode the intended contract more precisely than the README.
