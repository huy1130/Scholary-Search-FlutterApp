import 'package:dio/dio.dart';
import '../core/constants.dart';
import '../models/work.dart';

class OpenAlexService {
  final Dio _dio;

  OpenAlexService()
    : _dio = Dio(
        BaseOptions(
          baseUrl: AppConstants.baseUrl,
          queryParameters: {'mailto': AppConstants.mailto},
        ),
      );

  // Search works (existing)
  Future<({List<Work> works, int totalCount})> searchWorks({
    required String query,
    int page = 1,
    int perPage = 20,
  }) async {
    final response = await _dio.get(
      '/works',
      queryParameters: {
        'search': query,
        'page': page,
        'per_page': perPage,
        'sort': 'cited_by_count:desc',
      },
    );
    final data = response.data as Map<String, dynamic>;
    final results = data['results'] as List<dynamic>;
    final totalCount = data['meta']['count'] as int? ?? 0;
    return (
      works: results.map((e) => Work.fromJson(e)).toList(),
      totalCount: totalCount,
    );
  }

  // Fetch up to 200 works for analysis
  Future<List<Work>> fetchWorksForAnalysis({required String query}) async {
    final List<Work> allWorks = [];
    for (int page = 1; page <= 2; page++) {
      final response = await _dio.get(
        '/works',
        queryParameters: {
          'search': query,
          'page': page,
          'per_page': 100,
          'sort': 'cited_by_count:desc',
        },
      );
      final data = response.data as Map<String, dynamic>;
      final results = data['results'] as List<dynamic>;
      if (results.isEmpty) break;
      allWorks.addAll(results.map((e) => Work.fromJson(e)));
    }
    return allWorks;
  }

  // Publication trend: count by year
  Map<int, int> getTrendByYear(List<Work> works) {
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

  // Top journals by publication count
  List<MapEntry<String, int>> getTopJournals(List<Work> works, {int top = 10}) {
    final map = <String, int>{};
    for (final w in works) {
      if (w.sourceName != null && w.sourceName!.isNotEmpty) {
        map[w.sourceName!] = (map[w.sourceName!] ?? 0) + 1;
      }
    }
    final sorted = map.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sorted.take(top).toList();
  }

  // Top authors by publication count
  List<MapEntry<String, int>> getTopAuthors(List<Work> works, {int top = 10}) {
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
    return sorted.take(top).toList();
  }

  // Dashboard summary
  Map<String, dynamic> getDashboardSummary(List<Work> works) {
    if (works.isEmpty) return {};

    final totalPublications = works.length;
    final avgCitations =
        works.map((w) => w.citedByCount).reduce((a, b) => a + b) /
        totalPublications;
    final trendByYear = getTrendByYear(works);
    final mostActiveYear = trendByYear.entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .key;
    final topJournal = getTopJournals(works, top: 1).firstOrNull?.key ?? 'N/A';
    final topAuthor = getTopAuthors(works, top: 1).firstOrNull?.key ?? 'N/A';
    final mostInfluential = works.reduce(
      (a, b) => a.citedByCount > b.citedByCount ? a : b,
    );

    return {
      'totalPublications': totalPublications,
      'avgCitations': avgCitations.toStringAsFixed(1),
      'mostActiveYear': mostActiveYear,
      'topJournal': topJournal,
      'topAuthor': topAuthor,
      'mostInfluentialTitle': mostInfluential.title,
      'mostInfluentialCitations': mostInfluential.citedByCount,
    };
  }
}
