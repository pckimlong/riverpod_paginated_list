import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod_paginated_list/riverpod_paginated_list.dart';

void main() {
  group('Paging', () {
    group('zero-based (firstPageIsZeroBased = true)', () {
      const pageSize = 10;
      const zeroBased = true;

      test('page 0 has offset 0', () {
        final paging = Paging.ofIndex(0, pageSize: pageSize, firstPageIsZeroBased: zeroBased);
        expect(paging.page, 0);
        expect(paging.offset, 0);
      });

      test('index 9 (last item of page 0) stays on page 0', () {
        final paging = Paging.ofIndex(9, pageSize: pageSize, firstPageIsZeroBased: zeroBased);
        expect(paging.page, 0);
        expect(paging.offset, 0);
      });

      test('index 10 (first item of page 1) goes to page 1', () {
        final paging = Paging.ofIndex(10, pageSize: pageSize, firstPageIsZeroBased: zeroBased);
        expect(paging.page, 1);
        expect(paging.offset, 10);
      });

      test('index 25 goes to page 2 with offset 20', () {
        final paging = Paging.ofIndex(25, pageSize: pageSize, firstPageIsZeroBased: zeroBased);
        expect(paging.page, 2);
        expect(paging.offset, 20);
      });

      test('pageSize is preserved', () {
        final paging = Paging.ofIndex(0, pageSize: pageSize, firstPageIsZeroBased: zeroBased);
        expect(paging.pageSize, pageSize);
      });

      test('firstPageIsZeroBased is preserved', () {
        final paging = Paging.ofIndex(0, pageSize: pageSize, firstPageIsZeroBased: zeroBased);
        expect(paging.firstPageIsZeroBased, true);
      });
    });

    group('one-based (firstPageIsZeroBased = false)', () {
      const pageSize = 10;
      const oneBased = false;

      test('index 0 goes to page 1 with offset 0', () {
        final paging = Paging.ofIndex(0, pageSize: pageSize, firstPageIsZeroBased: oneBased);
        expect(paging.page, 1);
        expect(paging.offset, 0);
      });

      test('index 9 (last item of page 1) stays on page 1', () {
        final paging = Paging.ofIndex(9, pageSize: pageSize, firstPageIsZeroBased: oneBased);
        expect(paging.page, 1);
        expect(paging.offset, 0);
      });

      test('index 10 (first item of page 2) goes to page 2', () {
        final paging = Paging.ofIndex(10, pageSize: pageSize, firstPageIsZeroBased: oneBased);
        expect(paging.page, 2);
        expect(paging.offset, 10);
      });

      test('index 25 goes to page 3 with offset 20', () {
        final paging = Paging.ofIndex(25, pageSize: pageSize, firstPageIsZeroBased: oneBased);
        expect(paging.page, 3);
        expect(paging.offset, 20);
      });

      test('firstPageIsZeroBased is preserved', () {
        final paging = Paging.ofIndex(0, pageSize: pageSize, firstPageIsZeroBased: oneBased);
        expect(paging.firstPageIsZeroBased, false);
      });
    });

    group('different page sizes', () {
      test('pageSize 30 - index 0 is page 0', () {
        final paging = Paging.ofIndex(0, pageSize: 30);
        expect(paging.page, 0);
        expect(paging.offset, 0);
      });

      test('pageSize 30 - index 29 is still page 0', () {
        final paging = Paging.ofIndex(29, pageSize: 30);
        expect(paging.page, 0);
        expect(paging.offset, 0);
      });

      test('pageSize 30 - index 30 is page 1', () {
        final paging = Paging.ofIndex(30, pageSize: 30);
        expect(paging.page, 1);
        expect(paging.offset, 30);
      });

      test('pageSize 5 - index 12 is page 2 with offset 10', () {
        final paging = Paging.ofIndex(12, pageSize: 5);
        expect(paging.page, 2);
        expect(paging.offset, 10);
      });
    });

    group('offset calculation consistency', () {
      test('zero-based: offset always equals page * pageSize', () {
        for (var i = 0; i < 100; i++) {
          final paging = Paging.ofIndex(i, pageSize: 10, firstPageIsZeroBased: true);
          expect(paging.offset, paging.page * paging.pageSize);
        }
      });

      test('one-based: offset always equals (page - 1) * pageSize', () {
        for (var i = 0; i < 100; i++) {
          final paging = Paging.ofIndex(i, pageSize: 10, firstPageIsZeroBased: false);
          expect(paging.offset, (paging.page - 1) * paging.pageSize);
        }
      });

      test('both modes produce same offsets for same indices', () {
        for (var i = 0; i < 100; i++) {
          final zeroBased = Paging.ofIndex(i, pageSize: 10, firstPageIsZeroBased: true);
          final oneBased = Paging.ofIndex(i, pageSize: 10, firstPageIsZeroBased: false);
          expect(
            zeroBased.offset,
            oneBased.offset,
            reason: 'Index $i should have same offset regardless of page numbering',
          );
        }
      });
    });

    group('Paging.of factory', () {
      test('creates paging with correct values', () {
        final paging = Paging.of(2, pageSize: 20, firstPageIsZeroBased: true);
        expect(paging.page, 2);
        expect(paging.pageSize, 20);
        expect(paging.firstPageIsZeroBased, true);
        expect(paging.offset, 40);
      });

      test('creates one-based paging correctly', () {
        final paging = Paging.of(3, pageSize: 10, firstPageIsZeroBased: false);
        expect(paging.page, 3);
        expect(paging.offset, 20);
      });
    });
  });

  group('PaginatedListConfig', () {
    test('default pageSize is kDefaultPageSize', () {
      final config = PaginatedListConfig<String>(watchPage: (_) => throw UnimplementedError());
      expect(config.pageSize, kDefaultPageSize);
    });

    test('default firstPageIsZeroBased is true', () {
      final config = PaginatedListConfig<String>(watchPage: (_) => throw UnimplementedError());
      expect(config.firstPageIsZeroBased, true);
    });

    test('custom pageSize is preserved', () {
      final config = PaginatedListConfig<String>(
        watchPage: (_) => throw UnimplementedError(),
        pageSize: 50,
      );
      expect(config.pageSize, 50);
    });

    test('custom firstPageIsZeroBased is preserved', () {
      final config = PaginatedListConfig<String>(
        watchPage: (_) => throw UnimplementedError(),
        firstPageIsZeroBased: false,
      );
      expect(config.firstPageIsZeroBased, false);
    });

    test('firstPage is 0 when zero-based', () {
      final config = PaginatedListConfig<String>(
        watchPage: (_) => throw UnimplementedError(),
        firstPageIsZeroBased: true,
      );
      expect(config.firstPage, 0);
    });

    test('firstPage is 1 when one-based', () {
      final config = PaginatedListConfig<String>(
        watchPage: (_) => throw UnimplementedError(),
        firstPageIsZeroBased: false,
      );
      expect(config.firstPage, 1);
    });

    test('externalItems is null by default', () {
      final config = PaginatedListConfig<String>(watchPage: (_) => throw UnimplementedError());
      expect(config.externalItems, isNull);
    });

    test('externalItems can be set', () {
      final externalItems = <int, Widget Function(BuildContext)>{
        0: (_) => const Text('Header'),
        5: (_) => const Text('Ad'),
      }.lock;

      final config = PaginatedListConfig<String>(
        watchPage: (_) => throw UnimplementedError(),
        externalItems: externalItems,
      );
      expect(config.externalItems, externalItems);
      expect(config.externalItems!.length, 2);
    });

    test('skeleton is null by default', () {
      final config = PaginatedListConfig<String>(watchPage: (_) => throw UnimplementedError());
      expect(config.skeleton, isNull);
    });

    test('skeleton can be set', () {
      final config = PaginatedListConfig<String>(
        watchPage: (_) => throw UnimplementedError(),
        skeleton: SkeletonConfig(itemCount: 15, itemBuilder: (context, index) => const SizedBox()),
      );
      expect(config.skeleton, isNotNull);
      expect(config.skeleton!.itemCount, 15);
    });
  });

  group('PaginatedListConfig._getDataIndex', () {
    test('returns viewIndex when no external items', () {
      final config = _TestableConfig(externalItems: null);
      expect(config.getDataIndex(0), 0);
      expect(config.getDataIndex(5), 5);
      expect(config.getDataIndex(10), 10);
    });

    test('returns viewIndex when external items is empty', () {
      final config = _TestableConfig(externalItems: <int, Widget Function(BuildContext)>{}.lock);
      expect(config.getDataIndex(0), 0);
      expect(config.getDataIndex(5), 5);
    });

    test('adjusts index for single external item at start', () {
      final config = _TestableConfig(externalItems: {0: (_) => const SizedBox()}.lock);
      expect(config.getDataIndex(0), -1);
      expect(config.getDataIndex(1), 0);
      expect(config.getDataIndex(2), 1);
      expect(config.getDataIndex(5), 4);
    });

    test('adjusts index for multiple external items', () {
      final config = _TestableConfig(
        externalItems: {0: (_) => const SizedBox(), 5: (_) => const SizedBox()}.lock,
      );
      expect(config.getDataIndex(1), 0);
      expect(config.getDataIndex(4), 3);
      expect(config.getDataIndex(6), 4);
      expect(config.getDataIndex(10), 8);
    });

    test('handles external items not at start', () {
      final config = _TestableConfig(externalItems: {3: (_) => const SizedBox()}.lock);
      expect(config.getDataIndex(0), 0);
      expect(config.getDataIndex(2), 2);
      expect(config.getDataIndex(3), 2);
      expect(config.getDataIndex(4), 3);
      expect(config.getDataIndex(10), 9);
    });
  });

  group('SkeletonConfig', () {
    test('default itemCount is 20', () {
      final config = SkeletonConfig(itemBuilder: (context, index) => const SizedBox());
      expect(config.itemCount, 20);
    });

    test('custom itemCount is preserved', () {
      final config = SkeletonConfig(
        itemCount: 15,
        itemBuilder: (context, index) => const SizedBox(),
      );
      expect(config.itemCount, 15);
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
