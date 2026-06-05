import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/work.dart';
import '../services/openalex_service.dart';

final openAlexServiceProvider = Provider<OpenAlexService>((ref) {
  return OpenAlexService();
});

class SearchState {
  final List<Work> works;
  final bool isLoading;
  final bool isLoadingMore;
  final String? error;
  final String query;
  final int currentPage;
  final int totalCount;
  final bool hasMore;

  const SearchState({
    this.works = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.error,
    this.query = '',
    this.currentPage = 1,
    this.totalCount = 0,
    this.hasMore = false,
  });

  SearchState copyWith({
    List<Work>? works,
    bool? isLoading,
    bool? isLoadingMore,
    String? error,
    String? query,
    int? currentPage,
    int? totalCount,
    bool? hasMore,
  }) {
    return SearchState(
      works: works ?? this.works,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      error: error,
      query: query ?? this.query,
      currentPage: currentPage ?? this.currentPage,
      totalCount: totalCount ?? this.totalCount,
      hasMore: hasMore ?? this.hasMore,
    );
  }
}

class SearchNotifier extends Notifier<SearchState> {
  @override
  SearchState build() => const SearchState();

  OpenAlexService get _service => ref.read(openAlexServiceProvider);

  Future<void> search(String query) async {
    if (query.trim().isEmpty) return;
    state = state.copyWith(isLoading: true, error: null, query: query);
    try {
      final result = await _service.searchWorks(query: query, page: 1);
      state = state.copyWith(
        works: result.works,
        isLoading: false,
        currentPage: 1,
        totalCount: result.totalCount,
        hasMore: result.works.length < result.totalCount,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> loadMore() async {
    if (state.isLoadingMore || !state.hasMore) return;
    state = state.copyWith(isLoadingMore: true);
    final nextPage = state.currentPage + 1;
    try {
      final result = await _service.searchWorks(
        query: state.query,
        page: nextPage,
      );
      final allWorks = [...state.works, ...result.works];
      state = state.copyWith(
        works: allWorks,
        isLoadingMore: false,
        currentPage: nextPage,
        hasMore: allWorks.length < state.totalCount,
      );
    } catch (e) {
      state = state.copyWith(isLoadingMore: false, error: e.toString());
    }
  }
}

final searchProvider = NotifierProvider<SearchNotifier, SearchState>(
  SearchNotifier.new,
);
