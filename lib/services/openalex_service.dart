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
}
