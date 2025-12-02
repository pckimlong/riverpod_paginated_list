import 'package:flutter/widgets.dart';

/// Configuration for skeleton loading during first page fetch.
///
/// When provided to [PaginatedListConfig], the list will show skeleton
/// placeholder items while the first page is loading, providing a better
/// user experience than a simple loading spinner.
class SkeletonConfig {
  /// Creates a skeleton configuration.
  ///
  /// [itemBuilder] is required and defines how each skeleton item looks.
  /// [itemCount] defaults to 20 items.
  const SkeletonConfig({required this.itemBuilder, this.itemCount = 20});

  /// Number of skeleton items to display while loading first page.
  ///
  /// This should roughly match the number of items visible on screen
  /// to create a realistic loading appearance.
  final int itemCount;

  /// Builder for skeleton/shimmer items.
  ///
  /// [context] is the build context.
  /// [index] is the position in the skeleton list.
  ///
  /// Example:
  /// ```dart
  /// SkeletonConfig(
  ///   itemCount: 15,
  ///   itemBuilder: (context, index) => const ProductSkeletonTile(),
  /// )
  /// ```
  final Widget Function(BuildContext context, int index) itemBuilder;
}
