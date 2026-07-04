import 'dart:async';

import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:hooks_riverpod/legacy.dart' as legacy;
import 'package:riverpod_paginated_list/riverpod_paginated_list.dart';

void main() {
  group('PaginatedListConfig (widget behaviors)', () {
    testWidgets('shows skeleton items while first page is loading', (
      tester,
    ) async {
      final map = <int, AsyncValue<IList<String>>>{
        // first page is page 0 in zero-based mode
        0: const AsyncValue.loading(),
      };

      final config = PaginatedListConfig<String>(
        watchPage: (paging) => Provider(
          (ref) => map[paging.page] ?? const AsyncValue.data(IListConst([])),
        ),
        skeleton: SkeletonConfig(
          itemCount: 3,
          itemBuilder: (c, i) => Text('skeleton:$i'),
        ),
        pageSize: 10,
        firstPageIsZeroBased: true,
      );

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: Consumer(
                builder: (context, ref, _) {
                  // buildItem should return the skeleton widget while first page loading
                  final item = config.buildItem(
                    context: context,
                    ref: ref,
                    viewIndex: 1,
                    builder: (s, i) => Text('item:$s#$i'),
                  );

                  // expose some helper values for assertions
                  final count = config.getItemCount(ref);
                  final physicsIsNever =
                      config.getScrollPhysics(ref)
                          is NeverScrollableScrollPhysics;

                  return Column(
                    children: [
                      item ?? const SizedBox.shrink(),
                      Text('count:$count'),
                      Text('never:$physicsIsNever'),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // skeleton for index 1 should be present
      expect(find.text('skeleton:1'), findsOneWidget);
      // itemCount should come from skeleton
      expect(find.text('count:3'), findsOneWidget);
      // scroll physics should be NeverScrollable when skeleton shown
      expect(find.text('never:true'), findsOneWidget);
    });

    testWidgets(
      'useCache=true renders cached items while first page is loading',
      (tester) async {
        final versionProvider = legacy.StateProvider<int>((ref) => 0);
        final pending = Completer<void>();

        final pageProvider = FutureProvider.family<IList<String>, Paging>((
          ref,
          paging,
        ) async {
          final version = ref.watch(versionProvider);
          if (version == 0) {
            return const IListConst(['A', 'B']);
          }
          await pending.future;
          return const IListConst(['A', 'B']);
        });

        final config = PaginatedListConfig<String>(
          watchPage: (paging) => pageProvider(paging),
          skeleton: SkeletonConfig(
            itemCount: 3,
            itemBuilder: (c, i) => Text('skeleton:$i'),
          ),
          pageSize: 10,
          firstPageIsZeroBased: true,
        );

        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              home: Scaffold(
                body: Consumer(
                  builder: (context, ref, _) {
                    final item = config.buildItem(
                      context: context,
                      ref: ref,
                      viewIndex: 0,
                      builder: (s, i) => Text('item:$s#$i'),
                    );

                    final count = config.getItemCount(ref);
                    final physicsIsNever =
                        config.getScrollPhysics(ref)
                            is NeverScrollableScrollPhysics;

                    return Column(
                      children: [
                        item ?? const SizedBox.shrink(),
                        Text('count:$count'),
                        Text('never:$physicsIsNever'),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        final container = ProviderScope.containerOf(
          tester.element(find.byType(Consumer).first),
        );
        container.read(versionProvider.notifier).state = 1;
        await tester.pump();

        // cached value should render, skeleton should not
        expect(find.text('item:A#0'), findsOneWidget);
        expect(find.textContaining('skeleton:'), findsNothing);
        expect(find.text('count:null'), findsOneWidget);
        expect(find.text('never:false'), findsOneWidget);
      },
    );

    testWidgets(
      'useCache=false shows skeleton while first page is loading even if cached',
      (tester) async {
        final versionProvider = legacy.StateProvider<int>((ref) => 0);
        final pending = Completer<void>();

        final pageProvider = FutureProvider.family<IList<String>, Paging>((
          ref,
          paging,
        ) async {
          final version = ref.watch(versionProvider);
          if (version == 0) {
            return const IListConst(['A', 'B']);
          }
          await pending.future;
          return const IListConst(['A', 'B']);
        });

        final config = PaginatedListConfig<String>(
          watchPage: (paging) => pageProvider(paging),
          useCache: false,
          skeleton: SkeletonConfig(
            itemCount: 3,
            itemBuilder: (c, i) => Text('skeleton:$i'),
          ),
          pageSize: 10,
          firstPageIsZeroBased: true,
        );

        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              home: Scaffold(
                body: Consumer(
                  builder: (context, ref, _) {
                    final item = config.buildItem(
                      context: context,
                      ref: ref,
                      viewIndex: 1,
                      builder: (s, i) => Text('item:$s#$i'),
                    );

                    final count = config.getItemCount(ref);
                    final physicsIsNever =
                        config.getScrollPhysics(ref)
                            is NeverScrollableScrollPhysics;

                    return Column(
                      children: [
                        item ?? const SizedBox.shrink(),
                        Text('count:$count'),
                        Text('never:$physicsIsNever'),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        final container = ProviderScope.containerOf(
          tester.element(find.byType(Consumer).first),
        );
        container.read(versionProvider.notifier).state = 1;
        await tester.pump();

        expect(find.text('skeleton:1'), findsOneWidget);
        expect(find.text('count:3'), findsOneWidget);
        expect(find.text('never:true'), findsOneWidget);
      },
    );

    testWidgets('external item at view index takes precedence', (tester) async {
      final map = <int, AsyncValue<IList<String>>>{
        0: AsyncValue.data(const IListConst(['A'])),
      };

      final external = <int, Widget Function(BuildContext)>{
        0: (_) => const Text('external'),
      };

      final config = PaginatedListConfig<String>(
        watchPage: (paging) => Provider(
          (ref) => map[paging.page] ?? const AsyncValue.data(IListConst([])),
        ),
        externalItems: external,
        pageSize: 10,
      );

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: Consumer(
                builder: (context, ref, _) {
                  final item = config.buildItem(
                    context: context,
                    ref: ref,
                    viewIndex: 0,
                    builder: (s, i) => Text('item:$s#$i'),
                  );

                  return item ?? const SizedBox.shrink();
                },
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // external item should be used instead of data
      expect(find.text('external'), findsOneWidget);
      expect(find.textContaining('item:'), findsNothing);
    });

    testWidgets(
      'buildItem returns data item when available and null when index missing',
      (tester) async {
        final map = <int, AsyncValue<IList<String>>>{
          0: AsyncValue.data(const IListConst(['A', 'B', 'C'])),
        };

        final config = PaginatedListConfig<String>(
          watchPage: (paging) => Provider(
            (ref) => map[paging.page] ?? const AsyncValue.data(IListConst([])),
          ),
          pageSize: 10,
        );

        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              home: Scaffold(
                body: Column(
                  children: [
                    Consumer(
                      builder: (context, ref, _) {
                        final item = config.buildItem(
                          context: context,
                          ref: ref,
                          viewIndex: 0,
                          builder: (s, i) => Text('item:$s#$i'),
                        );
                        return item ?? const SizedBox.shrink();
                      },
                    ),
                    // missing index -> should return null which we fallback to SizedBox
                    Consumer(
                      builder: (context, ref, _) {
                        final item = config.buildItem(
                          context: context,
                          ref: ref,
                          viewIndex: 99, // out of range
                          builder: (s, i) => Text('item:$s#$i'),
                        );
                        return item ?? const SizedBox(key: Key('missing'));
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.text('item:A#0'), findsOneWidget);
        // out of range should produce the fallback SizedBox with key
        expect(find.byKey(const Key('missing')), findsOneWidget);
      },
    );

    testWidgets(
      'loadingBuilder used correctly for subsequent pages (no next page)',
      (tester) async {
        // small page size so index 0 -> page 0, index 2 -> page 1
        final map = <int, AsyncValue<IList<String>>>{
          1: const AsyncValue.loading(),
        };

        final config = PaginatedListConfig<String>(
          watchPage: (paging) => Provider(
            (ref) => map[paging.page] ?? const AsyncValue.data(IListConst([])),
          ),
          pageSize: 2,
        );

        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              home: Scaffold(
                body: Consumer(
                  builder: (context, ref, _) {
                    // simulate asking for page 1 items at viewIndex that maps to dataIndex 2
                    final item = config.buildItem(
                      context: context,
                      ref: ref,
                      viewIndex: 2, // dataIndex 2 -> page 1 indexInPage 0
                      builder: (s, i) => Text('item:$s#$i'),
                      loadingBuilder: (isFirst) =>
                          Text('loading-first:$isFirst'),
                    );
                    return item ?? const SizedBox.shrink();
                  },
                ),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // when the page is loading and there is no next page, loadingBuilder(true) should be used
        expect(find.text('loading-first:true'), findsOneWidget);
      },
    );

    testWidgets('loadingBuilder used correctly for subsequent pages (with next page)', (
      tester,
    ) async {
      // page 1 is loading, page 2 exists -> showLoadingAllPageItems true
      final map = <int, AsyncValue<IList<String>>>{
        1: const AsyncValue.loading(),
        2: AsyncValue.data(const IListConst(['X', 'Y'])),
      };

      final config = PaginatedListConfig<String>(
        watchPage: (paging) => Provider(
          (ref) => map[paging.page] ?? const AsyncValue.data(IListConst([])),
        ),
        pageSize: 2,
      );

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: Consumer(
                builder: (context, ref, _) {
                  // ensure next page provider exists in the container so ref.exists returns true
                  ref.read(config.pageProvider(2));

                  // indexInPage == 0
                  final first = config.buildItem(
                    context: context,
                    ref: ref,
                    viewIndex: 2, // dataIndex 2 -> page 1 indexInPage 0
                    builder: (s, i) => Text('item:$s#$i'),
                    loadingBuilder: (isFirst) => Text('loading-first:$isFirst'),
                  );

                  // indexInPage == 1
                  final second = config.buildItem(
                    context: context,
                    ref: ref,
                    viewIndex: 3, // dataIndex 3 -> page 1 indexInPage 1
                    builder: (s, i) => Text('item:$s#$i'),
                    loadingBuilder: (isFirst) => Text('loading-first:$isFirst'),
                  );

                  return Column(
                    children: [
                      first ?? const SizedBox.shrink(),
                      second ?? const SizedBox.shrink(),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // when next page exists we should still get loadingBuilder for subsequent items
      expect(find.text('loading-first:true'), findsOneWidget);
      // second item may be rendered as a fallback or omitted depending on select behavior,
      // but we are guaranteed to have the first index rendered with loadingBuilder
    });

    testWidgets('errorBuilder used for page error on the first index in page', (
      tester,
    ) async {
      final map = <int, AsyncValue<IList<String>>>{
        0: AsyncValue<IList<String>>.error(
          Exception('failed'),
          StackTrace.empty,
        ),
      };

      final config = PaginatedListConfig<String>(
        watchPage: (paging) => Provider(
          (ref) => map[paging.page] ?? const AsyncValue.data(IListConst([])),
        ),
        pageSize: 2,
      );

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: Consumer(
                builder: (context, ref, _) {
                  final item = config.buildItem(
                    context: context,
                    ref: ref,
                    viewIndex: 0, // page 0 indexInPage == 0 and has error
                    builder: (s, i) => Text('item:$s#$i'),
                    errorBuilder: (err, st, paging) =>
                        Text('err:${err.runtimeType} page:${paging.page}'),
                  );
                  return item ?? const SizedBox.shrink();
                },
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.textContaining('err:'), findsOneWidget);
      expect(find.textContaining('page:0'), findsOneWidget);
    });

    testWidgets('watchIsEmpty and watchHasItems behavior', (tester) async {
      // first scenario: loading
      final mapLoading = <int, AsyncValue<IList<String>>>{
        0: const AsyncValue.loading(),
      };

      final configLoading = PaginatedListConfig<String>(
        watchPage: (paging) => Provider(
          (ref) =>
              mapLoading[paging.page] ?? const AsyncValue.data(IListConst([])),
        ),
        pageSize: 2,
      );

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: Consumer(
                builder: (context, ref, _) {
                  final isEmpty = configLoading.watchIsEmpty(ref);
                  final hasItems = configLoading.watchHasItems(ref);
                  return Column(
                    children: [Text('empty:$isEmpty'), Text('has:$hasItems')],
                  );
                },
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text('empty:null'), findsOneWidget);
      expect(find.text('has:null'), findsOneWidget);

      // second scenario: empty data
      final mapEmpty = <int, AsyncValue<IList<String>>>{
        0: AsyncValue.data(const IListConst([])),
      };

      final configEmpty = PaginatedListConfig<String>(
        watchPage: (paging) => Provider(
          (ref) =>
              mapEmpty[paging.page] ?? const AsyncValue.data(IListConst([])),
        ),
        pageSize: 2,
      );

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: Consumer(
                builder: (context, ref, _) {
                  final isEmpty = configEmpty.watchIsEmpty(ref);
                  final hasItems = configEmpty.watchHasItems(ref);
                  return Column(
                    children: [Text('empty:$isEmpty'), Text('has:$hasItems')],
                  );
                },
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text('empty:true'), findsOneWidget);
      expect(find.text('has:false'), findsOneWidget);

      // third scenario: non-empty data
      final mapItems = <int, AsyncValue<IList<String>>>{
        0: AsyncValue.data(const IListConst(['X'])),
      };

      final configItems = PaginatedListConfig<String>(
        watchPage: (paging) => Provider(
          (ref) =>
              mapItems[paging.page] ?? const AsyncValue.data(IListConst([])),
        ),
        pageSize: 2,
      );

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: Consumer(
                builder: (context, ref, _) {
                  final isEmpty = configItems.watchIsEmpty(ref);
                  final hasItems = configItems.watchHasItems(ref);
                  return Column(
                    children: [Text('empty:$isEmpty'), Text('has:$hasItems')],
                  );
                },
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text('empty:false'), findsOneWidget);
      expect(find.text('has:true'), findsOneWidget);
    });
  });
}
