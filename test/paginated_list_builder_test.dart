import 'dart:async';

import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod_paginated_list/riverpod_paginated_list.dart';

void main() {
  group('PaginatedListBuilder', () {
    testWidgets('shows skeleton count and lock physics when first page is loading', (tester) async {
      final map = <int, AsyncValue<IList<String>>>{
        0: const AsyncValue.loading(),
      };

      final config = PaginatedListConfig<String>(
        watchPage: (paging) =>
            Provider((ref) => map[paging.page] ?? const AsyncValue.data(IListConst([]))),
        skeleton: SkeletonConfig(
          itemCount: 5,
          itemBuilder: (context, index) => Text('skeleton:$index'),
        ),
        pageSize: 10,
      );

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: PaginatedListBuilder<String>(
                config: config,
                builder: (context, state) {
                  return Column(
                    children: [
                      Text('isLoading:${state.isLoading}'),
                      Text('count:${state.count}'),
                      Text('physics:${state.physics.runtimeType}'),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('isLoading:true'), findsOneWidget);
      expect(find.text('count:5'), findsOneWidget);
      expect(find.text('physics:NeverScrollableScrollPhysics'), findsOneWidget);
    });

    testWidgets('shows isEmpty:true when first page is empty', (tester) async {
      final map = <int, AsyncValue<IList<String>>>{
        0: const AsyncValue.data(IListConst([])),
      };

      final config = PaginatedListConfig<String>(
        watchPage: (paging) =>
            Provider((ref) => map[paging.page] ?? const AsyncValue.data(IListConst([]))),
        pageSize: 10,
      );

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: PaginatedListBuilder<String>(
                config: config,
                builder: (context, state) {
                  return Column(
                    children: [
                      Text('isLoading:${state.isLoading}'),
                      Text('isEmpty:${state.isEmpty}'),
                      Text('count:${state.count}'),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('isLoading:false'), findsOneWidget);
      expect(find.text('isEmpty:true'), findsOneWidget);
      expect(find.text('count:0'), findsOneWidget);
    });

    testWidgets('paginates lazily on itemAt and handles fetching/success/error', (tester) async {
      final controller = StreamController<IList<String>>();
      final page1Completer = Completer<IList<String>>();
      final scrollController = ScrollController();

      final map = <int, FutureOr<IList<String>>>{
        0: const IListConst(['item0', 'item1', 'item2', 'item3', 'item4', 'item5', 'item6', 'item7', 'item8', 'item9']),
        1: page1Completer.future,
      };

      final providers = <int, FutureProvider<IList<String>>>{};
      final config = PaginatedListConfig<String>(
        watchPage: (paging) => providers.putIfAbsent(paging.page, () {
          return FutureProvider((ref) async {
            ref.keepAlive();
            final res = map[paging.page];
            if (res is Future<IList<String>>) {
              return await res;
            }
            return res as IList<String>;
          });
        }),
        pageSize: 10,
      );

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: PaginatedListBuilder<String>(
                config: config,
                builder: (context, state) {
                  return Column(
                    children: [
                      Text('isFetchingNext:${state.isFetchingNext}'),
                      Text('nextPageError:${state.nextPageError != null}'),
                      Text('count:${state.count}'),
                      Expanded(
                        child: SizedBox(
                          height: 200,
                          child: ListView.builder(
                            controller: scrollController,
                            physics: state.physics,
                            cacheExtent: 0,
                            itemCount: state.count,
                            itemBuilder: (context, index) {
                              final item = state.itemAt(index);
                              return ListTile(
                                title: Text(item ?? 'loading_shimmer'),
                              );
                            },
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      );

      // Initially loads page 0
      await tester.pump(); // Start load
      await tester.pumpAndSettle(); // Settle load of page 0

      // Page 0 has 10 items (exactly pageSize). So hasMore is true.
      expect(find.text('item0'), findsOneWidget);
      expect(find.text('count:null'), findsOneWidget);
      expect(find.text('isFetchingNext:false'), findsOneWidget);

      // Scroll to trigger rendering of index 10 (which belongs to page 1)
      scrollController.jumpTo(500);
      await tester.pump(); // 1. layout and schedule setState
      await tester.pump(); // 2. run setState and watch provider
      await tester.pump(); // 3. render loading state

      // Page 1 is loading (via page1Completer)
      expect(find.text('isFetchingNext:true'), findsOneWidget);
      expect(find.text('loading_shimmer'), findsWidgets);

      // Resolve page 1 success
      page1Completer.complete(const IListConst(['item10', 'item11']));
      await tester.pumpAndSettle();

      // Page 1 has 2 items (< pageSize), so hasMore becomes false.
      expect(find.text('isFetchingNext:false'), findsOneWidget);
      expect(find.text('item10'), findsOneWidget);
      expect(find.text('item11'), findsOneWidget);
      expect(find.text('count:12'), findsOneWidget);
      
      controller.close();
    });

    testWidgets('exposes nextPageError and retries on retryNextPage()', (tester) async {
      int page1Attempts = 0;
      final completers = [
        Completer<IList<String>>(),
        Completer<IList<String>>(),
        Completer<IList<String>>(),
      ];
      final scrollController = ScrollController();

      final providers = <int, FutureProvider<IList<String>>>{};
      final config = PaginatedListConfig<String>(
        watchPage: (paging) => providers.putIfAbsent(paging.page, () {
          return FutureProvider((ref) async {
            ref.keepAlive();
            if (paging.page == 0) {
              return const IListConst(['item0', 'item1', 'item2', 'item3', 'item4', 'item5', 'item6', 'item7', 'item8', 'item9']);
            }
            
            page1Attempts++;
            final completer = completers[page1Attempts - 1];
            return await completer.future;
          });
        }),
        pageSize: 10,
      );

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: PaginatedListBuilder<String>(
                config: config,
                builder: (context, state) {
                  final hasError = state.nextPageError != null;

                  return Column(
                    children: [
                      Text('nextPageError:${state.nextPageError != null}'),
                      Text('count:${state.count}'),
                      Expanded(
                        child: SizedBox(
                          height: 200,
                          child: ListView.builder(
                            controller: scrollController,
                            cacheExtent: 0,
                            itemCount: state.count,
                            itemBuilder: (context, index) {
                              if (hasError && index == 10) {
                                return ElevatedButton(
                                  key: const Key('retry_button'),
                                  onPressed: () => config.retryNextPage(),
                                  child: Text('Retry: ${state.nextPageError}'),
                                );
                              }
                              if (hasError && index > 10) {
                                return null;
                              }

                              final item = state.itemAt(index);
                              return ListTile(
                                title: Text(item ?? 'loading_shimmer'),
                              );
                            },
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pumpAndSettle();

      // Trigger lazy load of page 1 by scrolling
      scrollController.jumpTo(500);
      await tester.pump(); // 1. layout and schedule setState
      await tester.pump(); // 2. run setState and watch provider
      await tester.pump(); // 3. render loading state

      expect(page1Attempts, 1);

      // Complete attempt 1 with error
      completers[0].completeError(Exception('fetch_failed'));
      await tester.pumpAndSettle();

      expect(find.text('nextPageError:true'), findsOneWidget);
      expect(find.byKey(const Key('retry_button')), findsOneWidget);

      // Click retry
      await tester.tap(find.byKey(const Key('retry_button')));
      await tester.pump(); // start load of retry (attempt 2)

      expect(page1Attempts, 3);

      // Complete attempt 3 with success
      completers[2].complete(const IListConst(['item10']));
      await tester.pumpAndSettle();

      expect(find.text('nextPageError:false'), findsOneWidget);
      expect(find.text('item10'), findsOneWidget);
      expect(find.byKey(const Key('retry_button')), findsNothing);
    });

    testWidgets('supports externalItems and adjusts counts and index lookups', (tester) async {
      final providers = <int, Provider<AsyncValue<IList<String>>>>{};
      final config = PaginatedListConfig<String>(
        watchPage: (paging) => providers.putIfAbsent(paging.page, () {
          return Provider<AsyncValue<IList<String>>>((ref) {
            if (paging.page == 0) {
              return const AsyncValue.data(IListConst(['A', 'B']));
            }
            return const AsyncValue.data(IListConst([]));
          });
        }),
        pageSize: 2,
        externalItems: {
          0: (context) => const Text('HeaderWidget'),
          3: (context) => const Text('AdWidget'),
        },
      );

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: PaginatedListBuilder<String>(
                config: config,
                builder: (context, state) {
                  return ListView.builder(
                    itemCount: state.count,
                    itemBuilder: (context, index) {
                      final external = config.externalItems?[index];
                      if (external != null) return external(context);

                      final item = state.itemAt(index);
                      if (item == null) return null;
                      return Text('data:$item');
                    },
                  );
                },
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Total view count calculation:
      // Page 0 has 2 items. Since page 0 has 2 items (equal to pageSize 2), hasMore is true initially.
      // But wait! When page 1 is requested, it resolves immediately to an empty list.
      // So hasMore becomes false.
      // Total data items = 2 (A, B).
      // Total view items = 4 (HeaderWidget, A, B, AdWidget).
      expect(find.text('HeaderWidget'), findsOneWidget);
      expect(find.text('data:A'), findsOneWidget);
      expect(find.text('data:B'), findsOneWidget);
      expect(find.text('AdWidget'), findsOneWidget);
      expect(find.textContaining('data:null'), findsNothing);
    });

    testWidgets('supports custom scroll physics when loaded', (tester) async {
      final config = PaginatedListConfig<String>(
        watchPage: (paging) => Provider((ref) => const AsyncValue.data(IListConst(['item0']))),
        pageSize: 10,
      );

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: PaginatedListBuilder<String>(
                config: config,
                physics: const BouncingScrollPhysics(),
                builder: (context, state) {
                  return Text('physics:${state.physics.runtimeType}');
                },
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text('physics:BouncingScrollPhysics'), findsOneWidget);
    });
  });
}
