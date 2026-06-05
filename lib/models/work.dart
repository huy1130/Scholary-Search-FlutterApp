class Work {
  final String id;
  final String title;
  final int? publicationYear;
  final int citedByCount;
  final String? doi;
  final bool isOpenAccess;
  final List<String> authorNames;
  final String? sourceName;
  final String? abstractText;

  Work({
    required this.id,
    required this.title,
    this.publicationYear,
    required this.citedByCount,
    this.doi,
    required this.isOpenAccess,
    required this.authorNames,
    this.sourceName,
    this.abstractText,
  });

  factory Work.fromJson(Map<String, dynamic> json) {
    // Lấy danh sách tác giả
    final authorships = json['authorships'] as List<dynamic>? ?? [];
    final authors = authorships
        .map((a) => a['author']?['display_name'] as String? ?? 'Unknown')
        .toList();

    // Lấy tên journal/source
    final primaryLocation = json['primary_location'];
    final sourceName = primaryLocation?['source']?['display_name'] as String?;

    // Lấy abstract (OpenAlex trả về dạng inverted index, cần reconstruct)
    final abstractInverted =
        json['abstract_inverted_index'] as Map<String, dynamic>?;
    String? abstractText;
    if (abstractInverted != null) {
      final wordPositions = <int, String>{};
      abstractInverted.forEach((word, positions) {
        for (final pos in positions) {
          wordPositions[pos as int] = word;
        }
      });
      final sortedKeys = wordPositions.keys.toList()..sort();
      abstractText = sortedKeys.map((k) => wordPositions[k]).join(' ');
    }

    return Work(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? 'No title',
      publicationYear: json['publication_year'] as int?,
      citedByCount: json['cited_by_count'] as int? ?? 0,
      doi: json['doi'] as String?,
      isOpenAccess: json['open_access']?['is_oa'] as bool? ?? false,
      authorNames: authors,
      sourceName: sourceName,
      abstractText: abstractText,
    );
  }
}
