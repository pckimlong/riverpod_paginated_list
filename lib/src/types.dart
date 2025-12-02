import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import 'package:flutter/widgets.dart';

/// A map of view indices to external widget builders.
///
/// Use this to inject non-paginated items (headers, ads, banners) at specific
/// positions in the list.
///
/// Example:
/// ```dart
/// externalItems: {
///   0: (context) => HeaderWidget(),
///   5: (context) => AdvertisementBanner(),
/// }.lock,
/// ```
typedef ExternalItems = IMap<int, Widget Function(BuildContext context)>;

/// Default page size for pagination.
const kDefaultPageSize = 30;
