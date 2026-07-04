/// Represents pagination parameters for fetching a page of data.
///
/// This is an extension type that wraps a tuple of (page, pageSize, firstPageIsZeroBased).
/// It provides convenient getters and a factory for calculating page from list index.
extension type Paging._(
  (int page, int pageSize, bool firstPageIsZeroBased) param
) {
  /// The current page number.
  int get page => param.$1;

  /// The number of items per page.
  int get pageSize => param.$2;

  /// Whether the first page is numbered 0 (true) or 1 (false).
  bool get firstPageIsZeroBased => param.$3;

  /// Calculates the offset for database/API queries.
  ///
  /// For zero-based: offset = page * pageSize
  /// For one-based: offset = (page - 1) * pageSize
  int get offset =>
      firstPageIsZeroBased ? page * pageSize : (page - 1) * pageSize;

  /// Creates a [Paging] instance from a list index.
  ///
  /// This is useful when you have a ListView index and need to determine
  /// which page that item belongs to.
  ///
  /// Example:
  /// ```dart
  /// // For a list with pageSize 10:
  /// // index 0-9 -> page 0 (or 1 if one-based)
  /// // index 10-19 -> page 1 (or 2 if one-based)
  /// final paging = Paging.ofIndex(15, pageSize: 10);
  /// print(paging.page); // 1 (zero-based) or 2 (one-based)
  /// ```
  static Paging ofIndex(
    int index, {
    required int pageSize,
    bool firstPageIsZeroBased = true,
  }) {
    final page = index ~/ pageSize;
    final adjustedPage = firstPageIsZeroBased ? page : page + 1;
    return Paging._((adjustedPage, pageSize, firstPageIsZeroBased));
  }

  /// Creates a [Paging] instance directly from page number.
  static Paging of(
    int page, {
    required int pageSize,
    bool firstPageIsZeroBased = true,
  }) {
    return Paging._((page, pageSize, firstPageIsZeroBased));
  }
}
