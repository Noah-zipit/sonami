import 'dart:convert';
import 'package:http/http.dart' as http;
import 'models.dart';

/// Client for the Sonami backend (https://sonami-dex-proto.vercel.app).
/// All MangaDex traffic goes through /api/md (rate-limited server-side);
/// all images go through /api/img (no hotlinking).
class SonamiApi {
  static const base = 'https://sonami-dex-proto.vercel.app';
  static const _ratings = 'contentRating[]=safe&contentRating[]=suggestive';
  static const _includes = 'includes[]=cover_art&includes[]=author&includes[]=artist';

  static Uri _u(String path, String query) => Uri.parse('$base$path?$query');

  static Future<Map<String, dynamic>> _getJson(Uri uri) async {
    final res = await http.get(uri, headers: {'Accept': 'application/json'});
    if (res.statusCode != 200) {
      throw Exception('API ${res.statusCode} on ${uri.path}');
    }
    return json.decode(res.body) as Map<String, dynamic>;
  }

  /// MangaDex genre/theme tag catalogue (id + English name).
  static Future<List<({String id, String name})>> fetchTags() async {
    final data = await _getJson(_u('/api/md/manga/tag', ''));
    final out = <({String id, String name})>[];
    for (final t in (data['data'] as List?) ?? []) {
      final a = t['attributes'] as Map<String, dynamic>?;
      final name = a?['name']?['en']?.toString();
      if (name != null && name.isNotEmpty) {
        out.add((id: t['id'].toString(), name: name));
      }
    }
    out.sort((a, b) => a.name.compareTo(b.name));
    return out;
  }

  /// Route any MangaDex CDN image through the proxy.
  static String px(String? src) {
    if (src == null || src.isEmpty) return '';
    return '$base/api/img?u=${Uri.encodeComponent(src)}';
  }

  static Future<List<Manga>> trending({int limit = 18}) async {
    final data = await _getJson(_u('/api/md/manga',
        'limit=$limit&$_ratings&order[followedCount]=desc&$_includes&hasAvailableChapters=true'));
    return ((data['data'] as List?) ?? []).map((m) => Manga.fromJson(m)).toList();
  }

  static Future<List<Chapter>> latestChapters({int limit = 18}) async {
    final data = await _getJson(_u('/api/md/chapter',
        'translatedLanguage[]=en&order[readableAt]=desc&limit=$limit&$_ratings&includes[]=manga&includes[]=scanlation_group'));
    final chapters = ((data['data'] as List?) ?? []).map((c) => Chapter.fromJson(c)).toList();
    // Backfill covers (the chapter feed never carries cover_art).
    final missing = chapters.where((c) => c.mangaId != null && c.mangaCover == null).map((c) => c.mangaId!).toSet().toList();
    if (missing.isNotEmpty) {
      try {
        final q = [...missing.map((id) => 'ids[]=${Uri.encodeComponent(id)}'), 'includes[]=cover_art', 'limit=${missing.length}', _ratings].join('&');
        final mdata = await _getJson(_u('/api/md/manga', q));
        final coverById = <String, String>{};
        for (final m in (mdata['data'] as List?) ?? []) {
          final mid = m['id'].toString();
          final rels = (m['relationships'] as List?) ?? [];
          for (final r in rels) {
            if (r['type'] == 'cover_art') {
              final fn = r['attributes']?['fileName']?.toString();
              if (fn != null) {
                coverById[mid] = 'https://uploads.mangadex.org/covers/$mid/$fn.256.jpg';
              }
            }
          }
        }
        for (var i = 0; i < chapters.length; i++) {
          final c = chapters[i];
          if (c.mangaCover == null && c.mangaId != null && coverById.containsKey(c.mangaId)) {
            chapters[i] = Chapter(
              id: c.id, chapter: c.chapter, volume: c.volume, title: c.title,
              pages: c.pages, language: c.language, externalUrl: c.externalUrl,
              readableAt: c.readableAt, group: c.group, mangaId: c.mangaId,
              mangaTitle: c.mangaTitle, mangaCover: coverById[c.mangaId],
            );
          }
        }
      } catch (_) {/* covers stay empty; placeholder shows */}
    }
    return chapters;
  }

  static Future<({List<Manga> items, int total})> search(String q, {int limit = 24, int offset = 0}) async {
    final data = await _getJson(_u('/api/md/manga',
        'title=${Uri.encodeComponent(q)}&limit=$limit&offset=$offset&$_ratings&order[relevance]=desc&$_includes'));
    final items = ((data['data'] as List?) ?? []).map((m) => Manga.fromJson(m)).toList();
    return (items: items, total: (data['total'] as num?)?.toInt() ?? 0);
  }

  static Future<Manga> getManga(String id) async {
    final data = await _getJson(_u('/api/md/manga/$id', _includes));
    return Manga.fromJson(data['data']);
  }

  /// Full English chapter feed, oldest → newest. Parallel pages like the web app.
  static Future<List<Chapter>> getFeed(String mangaId) async {
    String q(int offset) =>
        'translatedLanguage[]=en&order[chapter]=asc&limit=500&offset=$offset&$_ratings&includes[]=scanlation_group';
    final first = await _getJson(_u('/api/md/manga/$mangaId/feed', q(0)));
    final total = (first['total'] as num?)?.toInt() ?? 0;
    final pages = [first];
    final offsets = <int>[];
    for (var o = 500; o < total && o < 2000; o += 500) {
      offsets.add(o);
    }
    if (offsets.isNotEmpty) {
      final rest = await Future.wait(offsets.map((o) => _getJson(_u('/api/md/manga/$mangaId/feed', q(o)))));
      pages.addAll(rest);
    }
    final chapters = pages.expand((d) => ((d['data'] as List?) ?? []).map((c) => Chapter.fromJson(c))).toList();
    chapters.sort((a, b) => chapterNum(a.chapter).compareTo(chapterNum(b.chapter)));
    return chapters;
  }

  /// At-home page URLs (data-saver), proxied.
  static Future<List<String>> getPages(String chapterId) async {
    final data = await _getJson(_u('/api/md/at-home/server/$chapterId', ''));
    final baseUrl = data['baseUrl']?.toString() ?? '';
    final ch = data['chapter'] as Map<String, dynamic>? ?? {};
    final hash = ch['hash']?.toString() ?? '';
    final files = ((ch['dataSaver'] as List?) ?? []).map((f) => f.toString()).toList();
    return files.map((f) => px('$baseUrl/data-saver/$hash/$f')).toList();
  }

  /// Filtered, paginated catalogue browsing (mirrors web browseManga).
  static Future<({List<Manga> items, int total})> browse({
    int limit = 24,
    int offset = 0,
    String sort = 'popular',
    List<String> status = const [],
    List<String> langs = const [],
    List<String> tagIds = const [],
  }) async {
    const orders = {
      'popular': 'order[followedCount]=desc',
      'rating': 'order[rating]=desc',
      'updated': 'order[latestUploadedChapter]=desc',
      'new': 'order[createdAt]=desc',
    };
    final params = [
      'limit=$limit',
      'offset=$offset',
      orders[sort] ?? orders['popular']!,
      _ratings,
      _includes,
      'hasAvailableChapters=true',
      ...status.map((s) => 'status[]=${Uri.encodeComponent(s)}'),
      ...langs.map((l) => 'originalLanguage[]=${Uri.encodeComponent(l)}'),
      ...tagIds.map((t) => 'includedTags[]=${Uri.encodeComponent(t)}'),
    ];
    final data = await _getJson(_u('/api/md/manga', params.join('&')));
    final items = ((data['data'] as List?) ?? []).map((m) => Manga.fromJson(m)).toList();
    return (items: items, total: (data['total'] as num?)?.toInt() ?? 0);
  }
}
