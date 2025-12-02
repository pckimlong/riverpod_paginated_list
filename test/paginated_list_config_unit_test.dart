import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod_paginated_list/riverpod_paginated_list.dart';

void main() {
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
