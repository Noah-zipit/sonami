import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Device-local library shelves + reading progress (mirrors web lib/store.ts).
class LibraryStore extends ChangeNotifier {
  static const _pKey = 'sonami:progress:v1';
  static const _lKey = 'sonami:library:v1';

  Map<String, dynamic> _progress = {};
  Map<String, dynamic> _library = {};
  bool ready = false;

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
    ready = true;
    notifyListeners();
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_pKey, json.encode(_progress));
    await prefs.setString(_lKey, json.encode(_library));
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
    notifyListeners();
    _save();
  }

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
}
