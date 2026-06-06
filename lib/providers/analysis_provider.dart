import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/work.dart';
import '../services/openalex_service.dart';
import 'search_provider.dart';

class AnalysisState {
  final List<Work> works;
  final bool isLoading;
  final String? error;
  final String query;

  const AnalysisState({
    this.works = const [],
    this.isLoading = false,
    this.error,
    this.query = '',
  });

  AnalysisState copyWith({
    List<Work>? works,
    bool? isLoading,
    String? error,
    String? query,
  }) {
    return AnalysisState(
      works: works ?? this.works,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      query: query ?? this.query,
    );
  }

  // Computed getters
  Map<int, int> get trendByYear {
    final map = <int, int>{};
    for (final w in works) {
      if (w.publicationYear != null) {
        map[w.publicationYear!] = (map[w.publicationYear!] ?? 0) + 1;
      }
    }
    return Map.fromEntries(
      map.entries.toList()..sort((a, b) => a.key.compareTo(b.key)),
    );
  }

  List<MapEntry<String, int>> get topJournals {
    final map = <String, int>{};
    for (final w in works) {
      if (w.sourceName != null && w.sourceName!.isNotEmpty) {
        map[w.sourceName!] = (map[w.sourceName!] ?? 0) + 1;
      }
    }
    final sorted = map.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sorted.take(10).toList();
  }

  List<MapEntry<String, int>> get topAuthors {
    final map = <String, int>{};
    for (final w in works) {
      for (final author in w.authorNames) {
        if (author != 'Unknown') {
          map[author] = (map[author] ?? 0) + 1;
        }
      }
    }
    final sorted = map.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sorted.take(10).toList();
  }

  List<Work> get topInfluentialPapers {
    final sorted = [...works]
      ..sort((a, b) => b.citedByCount.compareTo(a.citedByCount));
    return sorted.take(10).toList();
  }

  Map<String, dynamic> get dashboardSummary {
    if (works.isEmpty) return {};
    final total = works.length;
    final avgCitations =
        works.map((w) => w.citedByCount).reduce((a, b) => a + b) / total;
    final trend = trendByYear;
    final mostActiveYear = trend.entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .key;
    final topJournal = topJournals.firstOrNull?.key ?? 'N/A';
    final topAuthor = topAuthors.firstOrNull?.key ?? 'N/A';
    final mostInfluential = topInfluentialPapers.firstOrNull;
    return {
      'totalPublications': total,
      'avgCitations': avgCitations.toStringAsFixed(1),
      'mostActiveYear': mostActiveYear,
      'topJournal': topJournal,
      'topAuthor': topAuthor,
      'mostInfluentialTitle': mostInfluential?.title ?? 'N/A',
      'mostInfluentialCitations': mostInfluential?.citedByCount ?? 0,
    };
  }
}

class AnalysisNotifier extends Notifier<AnalysisState> {
  @override
  AnalysisState build() => const AnalysisState();

  OpenAlexService get _service => ref.read(openAlexServiceProvider);

  Future<void> analyze(String query) async {
    if (query.trim().isEmpty) return;
    state = state.copyWith(isLoading: true, error: null, query: query);
    try {
      final works = await _service.fetchWorksForAnalysis(query: query);
      state = state.copyWith(works: works, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}

final analysisProvider = NotifierProvider<AnalysisNotifier, AnalysisState>(
  AnalysisNotifier.new,
);
