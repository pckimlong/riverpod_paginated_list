import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod_paginated_list/riverpod_paginated_list.dart';

void main() {
  group('Paging', () {
    group('zero-based (firstPageIsZeroBased = true)', () {
      const pageSize = 10;
      const zeroBased = true;

      test('page 0 has offset 0', () {
        final paging = Paging.ofIndex(
          0,
          pageSize: pageSize,
          firstPageIsZeroBased: zeroBased,
        );
        expect(paging.page, 0);
        expect(paging.offset, 0);
      });

      test('index 9 (last item of page 0) stays on page 0', () {
        final paging = Paging.ofIndex(
          9,
          pageSize: pageSize,
          firstPageIsZeroBased: zeroBased,
        );
        expect(paging.page, 0);
        expect(paging.offset, 0);
      });

      test('index 10 (first item of page 1) goes to page 1', () {
        final paging = Paging.ofIndex(
          10,
          pageSize: pageSize,
          firstPageIsZeroBased: zeroBased,
        );
        expect(paging.page, 1);
        expect(paging.offset, 10);
      });

      test('index 25 goes to page 2 with offset 20', () {
        final paging = Paging.ofIndex(
          25,
          pageSize: pageSize,
          firstPageIsZeroBased: zeroBased,
        );
        expect(paging.page, 2);
        expect(paging.offset, 20);
      });

      test('pageSize is preserved', () {
        final paging = Paging.ofIndex(
          0,
          pageSize: pageSize,
          firstPageIsZeroBased: zeroBased,
        );
        expect(paging.pageSize, pageSize);
      });

      test('firstPageIsZeroBased is preserved', () {
        final paging = Paging.ofIndex(
          0,
          pageSize: pageSize,
          firstPageIsZeroBased: zeroBased,
        );
        expect(paging.firstPageIsZeroBased, true);
      });
    });

    group('one-based (firstPageIsZeroBased = false)', () {
      const pageSize = 10;
      const oneBased = false;

      test('index 0 goes to page 1 with offset 0', () {
        final paging = Paging.ofIndex(
          0,
          pageSize: pageSize,
          firstPageIsZeroBased: oneBased,
        );
        expect(paging.page, 1);
        expect(paging.offset, 0);
      });

      test('index 9 (last item of page 1) stays on page 1', () {
        final paging = Paging.ofIndex(
          9,
          pageSize: pageSize,
          firstPageIsZeroBased: oneBased,
        );
        expect(paging.page, 1);
        expect(paging.offset, 0);
      });

      test('index 10 (first item of page 2) goes to page 2', () {
        final paging = Paging.ofIndex(
          10,
          pageSize: pageSize,
          firstPageIsZeroBased: oneBased,
        );
        expect(paging.page, 2);
        expect(paging.offset, 10);
      });

      test('index 25 goes to page 3 with offset 20', () {
        final paging = Paging.ofIndex(
          25,
          pageSize: pageSize,
          firstPageIsZeroBased: oneBased,
        );
        expect(paging.page, 3);
        expect(paging.offset, 20);
      });

      test('firstPageIsZeroBased is preserved', () {
        final paging = Paging.ofIndex(
          0,
          pageSize: pageSize,
          firstPageIsZeroBased: oneBased,
        );
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
          final paging = Paging.ofIndex(
            i,
            pageSize: 10,
            firstPageIsZeroBased: true,
          );
          expect(paging.offset, paging.page * paging.pageSize);
        }
      });

      test('one-based: offset always equals (page - 1) * pageSize', () {
        for (var i = 0; i < 100; i++) {
          final paging = Paging.ofIndex(
            i,
            pageSize: 10,
            firstPageIsZeroBased: false,
          );
          expect(paging.offset, (paging.page - 1) * paging.pageSize);
        }
      });

      test('both modes produce same offsets for same indices', () {
        for (var i = 0; i < 100; i++) {
          final zeroBased = Paging.ofIndex(
            i,
            pageSize: 10,
            firstPageIsZeroBased: true,
          );
          final oneBased = Paging.ofIndex(
            i,
            pageSize: 10,
            firstPageIsZeroBased: false,
          );
          expect(
            zeroBased.offset,
            oneBased.offset,
            reason:
                'Index $i should have same offset regardless of page numbering',
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
}
