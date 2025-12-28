import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod_paginated_list/riverpod_paginated_list.dart';

void main() {
  group('PaginatedListConfig._getDataIndex', () {
    test('returns viewIndex when no external items', () {
      final config = _TestableConfig(externalItems: null);
      expect(config.getDataIndex(0), 0);
      expect(config.getDataIndex(5), 5);
      expect(config.getDataIndex(10), 10);
    });

    test('returns viewIndex when external items is empty', () {
      final config = _TestableConfig(externalItems: <int, Widget Function(BuildContext)>{});
      expect(config.getDataIndex(0), 0);
      expect(config.getDataIndex(5), 5);
    });

    test('adjusts index for single external item at start', () {
      final config = _TestableConfig(externalItems: {0: (_) => const SizedBox()});
      expect(config.getDataIndex(0), -1);
      expect(config.getDataIndex(1), 0);
      expect(config.getDataIndex(2), 1);
      expect(config.getDataIndex(5), 4);
    });

    test('adjusts index for multiple external items', () {
      final config = _TestableConfig(
        externalItems: {0: (_) => const SizedBox(), 5: (_) => const SizedBox()},
      );
      expect(config.getDataIndex(1), 0);
      expect(config.getDataIndex(4), 3);
      expect(config.getDataIndex(6), 4);
      expect(config.getDataIndex(10), 8);
    });

    test('handles external items not at start', () {
      final config = _TestableConfig(externalItems: {3: (_) => const SizedBox()});
      expect(config.getDataIndex(0), 0);
      expect(config.getDataIndex(2), 2);
      expect(config.getDataIndex(3), 2);
      expect(config.getDataIndex(4), 3);
      expect(config.getDataIndex(10), 9);
    });
  });
}

/// Testable subclass to expose private _getDataIndex method
class _TestableConfig extends PaginatedListConfig<String> {
  _TestableConfig({super.externalItems}) : super(watchPage: (_) => throw UnimplementedError());

  int getDataIndex(int viewIndex) {
    final external = externalItems;
    if (external == null || external.isEmpty) return viewIndex;
    return viewIndex - external.keys.where((pos) => pos <= viewIndex).length;
  }
}
