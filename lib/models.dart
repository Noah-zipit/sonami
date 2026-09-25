// Data models mirroring the Sonami web API normalisation (lib/mangadex.ts).

String _pickTitle(Map<String, dynamic> titles) {
  if (titles.isEmpty) return 'Unknown title';
  return (titles['en'] ??
          titles['ko-ro'] ??
          titles['ja-ro'] ??
          titles['zh-ro'] ??
          titles.values.firstOrNull ??
          'Unknown title')
      .toString();
}

Map<String, dynamic>? _relOf(Map<String, dynamic> e, String type) {
  final rels = (e['relationships'] as List?) ?? [];
  for (final r in rels) {
    if (r is Map<String, dynamic> && r['type'] == type) return r;
  }
  return null;
}

String? _coverUrl(String mangaId, String? fileName, int size) {
  if (fileName == null) return null;
  final suffix = size == 0 ? '' : '.$size.jpg';
  return 'https://uploads.mangadex.org/covers/$mangaId/$fileName$suffix';
}

class Manga {
  final String id;
  final String title;
  final List<String> altTitles;
  final String description;
  final String status;
  final int? year;
  final String contentRating;
  final List<String> tags;
  final String? author;
  final String? artist;
  final String? cover;
  final String? coverSmall;
  final String? coverLarge;
  final String originalLanguage;
  final String? lastChapter;

  Manga({
    required this.id,
    required this.title,
    required this.altTitles,
    required this.description,
    required this.status,
    required this.year,
    required this.contentRating,
    required this.tags,
    required this.author,
    required this.artist,
    required this.cover,
    required this.coverSmall,
    required this.coverLarge,
    required this.originalLanguage,
    required this.lastChapter,
  });

  factory Manga.fromJson(Map<String, dynamic> raw) {
    final a = (raw['attributes'] as Map<String, dynamic>?) ?? {};
    final coverRel = _relOf(raw, 'cover_art');
    final fileName = (coverRel?['attributes'] as Map?)?['fileName']?.toString();
    final authorRel = _relOf(raw, 'author') ?? _relOf(raw, 'artist');
    final artistRel = _relOf(raw, 'artist');
    final desc = (a['description'] as Map<String, dynamic>?) ?? {};
    final titles = (a['title'] as Map<String, dynamic>?) ?? {};
    return Manga(
      id: raw['id']?.toString() ?? '',
      title: _pickTitle(titles.map((k, v) => MapEntry(k.toString(), v))),
      altTitles: ((a['altTitles'] as List?) ?? [])
          .map((t) => _pickTitle((t as Map).map((k, v) => MapEntry(k.toString(), v))))
          .where((t) => t.isNotEmpty)
          .toList(),
      description: (desc['en'] ?? desc['ko-ro'] ?? desc.values.firstOrNull ?? '').toString(),
      status: (a['status'] ?? 'unknown').toString(),
      year: (a['year'] as num?)?.toInt(),
      contentRating: (a['contentRating'] ?? 'safe').toString(),
      tags: ((a['tags'] as List?) ?? [])
          .map((t) => ((t as Map)['attributes'] as Map?)?['name']?['en']?.toString())
          .whereType<String>()
          .toList(),
      author: (authorRel?['attributes'] as Map?)?['name']?.toString(),
      artist: (artistRel?['attributes'] as Map?)?['name']?.toString(),
      cover: _coverUrl(raw['id'].toString(), fileName, 512),
      coverSmall: _coverUrl(raw['id'].toString(), fileName, 256),
      coverLarge: _coverUrl(raw['id'].toString(), fileName, 0),
      originalLanguage: (a['originalLanguage'] ?? '??').toString(),
      lastChapter: a['lastChapter']?.toString(),
    );
  }
}

class Chapter {
  final String id;
  final String? chapter;
  final String? volume;
  final String? title;
  final int pages;
  final String language;
  final String? externalUrl;
  final String readableAt;
  final String? group;
  final String? mangaId;
  final String? mangaTitle;
  final String? mangaCover;

  Chapter({
    required this.id,
    required this.chapter,
    required this.volume,
    required this.title,
    required this.pages,
    required this.language,
    required this.externalUrl,
    required this.readableAt,
    required this.group,
    required this.mangaId,
    required this.mangaTitle,
    required this.mangaCover,
  });

  factory Chapter.fromJson(Map<String, dynamic> raw) {
    final a = (raw['attributes'] as Map<String, dynamic>?) ?? {};
    final groupRel = _relOf(raw, 'scanlation_group');
    final mangaRel = _relOf(raw, 'manga');
    final coverRel = _relOf(raw, 'cover_art');
    final mangaId = mangaRel?['id']?.toString();
    final mangaAttrs = mangaRel?['attributes'] as Map?;
    String? mangaCover;
    final cf = (coverRel?['attributes'] as Map?)?['fileName']?.toString();
    if (mangaId != null && cf != null) mangaCover = _coverUrl(mangaId, cf, 256);
    return Chapter(
      id: raw['id']?.toString() ?? '',
      chapter: a['chapter']?.toString(),
      volume: a['volume']?.toString(),
      title: a['title']?.toString(),
      pages: (a['pages'] as num?)?.toInt() ?? 0,
      language: (a['translatedLanguage'] ?? '?').toString(),
      externalUrl: a['externalUrl']?.toString(),
      readableAt: (a['readableAt'] ?? '').toString(),
      group: (groupRel?['attributes'] as Map?)?['name']?.toString(),
      mangaId: mangaId,
      mangaTitle: mangaAttrs != null
          ? _pickTitle((mangaAttrs['title'] as Map? ?? {}).map((k, v) => MapEntry(k.toString(), v)))
          : null,
      mangaCover: mangaCover,
    );
  }

  String get label {
    final c = chapter?.isNotEmpty == true ? 'Ch. $chapter' : 'Oneshot';
    if (title?.isNotEmpty == true) return '$c — $title';
    return c;
  }
}

double chapterNum(String? c) => double.tryParse(c ?? '') ?? -1;
