import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Device-local library shelves + reading progress (mirrors web lib/store.ts),
/// plus lifetime reading stats.
class LibraryStore extends ChangeNotifier {
  static const _pKey = 'sonami:progress:v1';
  static const _lKey = 'sonami:library:v1';
  static const _sKey = 'sonami:stats:v1';

  Map<String, dynamic> _progress = {};
  Map<String, dynamic> _library = {};
  Map<String, dynamic> _stats = {'pages': 0, 'chapters': <String>[], 'seconds': 0};
  bool ready = false;
  Timer? _statsDeb;

  Map<String, dynamic> get progress => _progress;
  Map<String, dynamic> get library => _library;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    try {
      _progress = json.decode(prefs.getString(_pKey) ?? '{}');
    } catch (_) { _progress = {}; }
    try {
      _library = json.decode(prefs.getString(_lKey) ?? '{}');
    } catch (_) { _library = {}; }
    try {
      final s = json.decode(prefs.getString(_sKey) ?? '{}');
      if (s is Map<String, dynamic>) {
        _stats = {
          'pages': (s['pages'] as num?)?.toInt() ?? 0,
          'chapters': (s['chapters'] as List?)?.map((e) => e.toString()).toList() ?? <String>[],
          'seconds': (s['seconds'] as num?)?.toInt() ?? 0,
        };
      }
    } catch (_) {}
    ready = true;
    notifyListeners();
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_pKey, json.encode(_progress));
    await prefs.setString(_lKey, json.encode(_library));
  }

  Future<void> _saveStats() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_sKey, json.encode(_stats));
  }

  void _saveStatsSoon() {
    _statsDeb?.cancel();
    _statsDeb = Timer(const Duration(seconds: 3), _saveStats);
  }

  void saveProgress({
    required String mangaId,
    required String mangaTitle,
    required String? cover,
    required String chapterId,
    required String? chapter,
    required int page,
  }) {
    _progress[mangaId] = {
      'mangaId': mangaId, 'mangaTitle': mangaTitle, 'cover': cover,
      'chapterId': chapterId, 'chapter': chapter, 'page': page,
      'ts': DateTime.now().millisecondsSinceEpoch,
    };
    // Anything being read belongs on the Reading shelf unless the user
    // shelved it somewhere else themselves.
    if (shelfOf(mangaId) == null) {
      setShelf(mangaId, 'reading', title: mangaTitle, cover: cover);
    }
    notifyListeners();
    _save();
  }

  /// A page was turned in the reader.
  void recordPage() {
    _stats['pages'] = ((_stats['pages'] as num?)?.toInt() ?? 0) + 1;
    notifyListeners();
    _saveStatsSoon();
  }

  /// A chapter was read through (deduped).
  void recordChapter(String chapterId) {
    final list = (_stats['chapters'] as List?)?.map((e) => e.toString()).toList() ?? <String>[];
    if (!list.contains(chapterId)) {
      list.add(chapterId);
      _stats['chapters'] = list;
      notifyListeners();
      _saveStatsSoon();
    }
  }

  /// Seconds spent inside the reader.
  void addReadSeconds(int s) {
    if (s <= 0) return;
    _stats['seconds'] = ((_stats['seconds'] as num?)?.toInt() ?? 0) + s;
    notifyListeners();
    _saveStatsSoon();
  }

  /// Lifetime totals: pages, chapters, seconds, series (with progress).
  Map<String, int> statsSummary() => {
        'pages': (_stats['pages'] as num?)?.toInt() ?? 0,
        'chapters': (_stats['chapters'] as List?)?.length ?? 0,
        'seconds': (_stats['seconds'] as num?)?.toInt() ?? 0,
        'series': _progress.length,
      };

  Map<String, dynamic>? progressFor(String mangaId) {
    final p = _progress[mangaId];
    return p is Map<String, dynamic> ? p : null;
  }

  String? shelfOf(String mangaId) {
    final e = _library[mangaId];
    return e is Map ? e['shelf']?.toString() : null;
  }

  void setShelf(String mangaId, String? shelf, {String? title, String? cover}) {
    if (shelf == null) {
      _library.remove(mangaId);
    } else {
      final old = _library[mangaId];
      _library[mangaId] = {
        'title': title ?? (old is Map ? old['title'] : null) ?? 'Unknown',
        'cover': cover ?? (old is Map ? old['cover'] : null),
        'shelf': shelf,
        'ts': DateTime.now().millisecondsSinceEpoch,
      };
    }
    notifyListeners();
    _save();
  }

  List<MapEntry<String, dynamic>> shelf(String name) {
    final list = _library.entries
        .where((e) => e.value is Map && e.value['shelf'] == name)
        .toList();
    list.sort((a, b) => ((b.value['ts'] ?? 0) as num).compareTo((a.value['ts'] ?? 0) as num));
    return list;
  }

  List<MapEntry<String, dynamic>> recentProgress({int limit = 10}) {
    final list = _progress.entries.toList();
    list.sort((a, b) => ((b.value['ts'] ?? 0) as num).compareTo((a.value['ts'] ?? 0) as num));
    return list.take(limit).toList();
  }

  @override
  void dispose() {
    _statsDeb?.cancel();
    super.dispose();
  }
}
