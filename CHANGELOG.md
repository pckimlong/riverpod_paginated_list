# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.1.0] - 2025-12-02

### Added
- Initial release of riverpod_paginated_list package
- Lightweight pagination utility for Flutter with Riverpod integration
- Support for skeleton loading during data fetching
- External items injection capability
- Support for both zero-based and one-based pagination
- Configurable pagination parameters
- Type-safe data handling with generic types
- Comprehensive error handling for pagination scenarios
- Memory-efficient data management with fast_immutable_collections

### Features
- `PaginatedListConfig` class for configuring pagination behavior
- `SkeletonConfig` class for customizing loading states
- `Paging` utilities for managing paginated data
- Flexible data source integration
- Reactive state management with Riverpod

### Documentation
- Complete API documentation
- Example implementation in `example/` directory
- Comprehensive README with usage examples

### Dependencies
- hooks_riverpod: ">=2.6.1 <4.0.0"
- fast_immutable_collections: ">=10.2.4 <12.0.0"
- Flutter SDK: ">=3.24.0"
- Dart SDK: "^3.10.1"

## [0.1.1]

- Add more tests
- Remove overhead of using immutable collections for external items

## [0.1.2] - 2025-12-28

- `useCache` (default true) allows rendering cached/previous `AsyncValue.value` while loading (incl. Riverpod v3 `isFromCache`).
- Skeleton loading is shown only for true initial loads when no cached/previous value is available.

## [0.2.0] - 2026-07-04

- Implement Record-based `PaginatedListBuilder` and custom scroll physics.
- Add `useCache` option to control cached value rendering during loading.
- Improve external items handling in pagination.
- Reformat code and update dependency versions.