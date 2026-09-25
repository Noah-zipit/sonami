import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';
import 'package:provider/provider.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import '../api.dart';
import '../store.dart';
import '../theme.dart';

class ReaderScreen extends StatefulWidget {
  final String mangaId;
  final String chapterId;
  final String? prevId;
  final String? nextId;
  final int resumePage;

  const ReaderScreen({
    super.key,
    required this.mangaId,
    required this.chapterId,
    this.prevId,
    this.nextId,
    this.resumePage = 0,
  });

  @override
  State<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends State<ReaderScreen> {
  late Future<List<String>> _pages;
  final ItemScrollController _scroll = ItemScrollController();
  final ItemPositionsListener _positions = ItemPositionsListener.create();
  bool _chrome = true;
  int _current = 0;
  int _total = 0;
  String _mangaTitle = '';
  String? _mangaCover;
  String? _chapterLabel;
  Timer? _saveDeb;
  late LibraryStore _store;

  @override
  void initState() {
    super.initState();
    _store = context.read<LibraryStore>();
    _pages = _load();
    _positions.itemPositions.addListener(_onPos);
  }

  Future<List<String>> _load() async {
    final pages = await SonamiApi.getPages(widget.chapterId);
    _total = pages.length;
    // Fetch chapter meta for title (best-effort, cached by backend).
    try {
      final feed = await SonamiApi.getFeed(widget.mangaId);
      final ch = feed.where((c) => c.id == widget.chapterId).firstOrNull;
      if (ch != null) {
        _chapterLabel = ch.chapter;
        _mangaTitle = ch.mangaTitle ?? '';
      }
      if (_mangaTitle.isEmpty) {
        final m = await SonamiApi.getManga(widget.mangaId);
        _mangaTitle = m.title;
        _mangaCover = m.coverSmall;
      }
    } catch (_) {}
    if (mounted && widget.resumePage > 0 && widget.resumePage < _total) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scroll.isAttached) _scroll.jumpTo(index: widget.resumePage);
      });
      _current = widget.resumePage;
    }
    return pages;
  }

  void _onPos() {
    final pos = _positions.itemPositions.value;
    if (pos.isEmpty) return;
    final vis = pos.where((p) => p.itemTrailingEdge > 0.01);
    if (vis.isEmpty) return;
    var first = vis.reduce((a, b) => a.index < b.index ? a : b).index;
    // The trailing end-of-chapter nav item is not a page; clamp to last page.
    if (_total > 0 && first >= _total) first = _total - 1;
    if (first != _current) {
      setState(() => _current = first);
      _saveDeb?.cancel();
      _saveDeb = Timer(const Duration(seconds: 1), _persist);
    }
  }

  void _persist() {
    if (_total == 0) return;
    _store.saveProgress(
      mangaId: widget.mangaId,
      mangaTitle: _mangaTitle.isEmpty ? 'Unknown' : _mangaTitle,
      cover: _mangaCover,
      chapterId: widget.chapterId,
      chapter: _chapterLabel,
      page: _current,
    );
  }

  @override
  void dispose() {
    _saveDeb?.cancel();
    _persist();
    super.dispose();
  }

  void _go(String? id) {
    if (id == null) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => ReaderScreen(mangaId: widget.mangaId, chapterId: id)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pct = _total == 0 ? 0.0 : (_current + 1) / _total;
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          FutureBuilder<List<String>>(
            future: _pages,
            builder: (_, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator(color: SonamiTheme.accent));
              }
              if (snap.hasError || (snap.data ?? []).isEmpty) {
                return Center(
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    const Text('Couldn\'t load pages.', style: TextStyle(color: SonamiTheme.muted)),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () => setState(() => _pages = _load()),
                      child: const Text('Retry', style: TextStyle(color: SonamiTheme.accent)),
                    ),
                  ]),
                );
              }
              final pages = snap.data!;
              return GestureDetector(
                onTap: () => setState(() => _chrome = !_chrome),
                child: ScrollablePositionedList.builder(
                  itemScrollController: _scroll,
                  itemPositionsListener: _positions,
                  itemCount: pages.length + 1,
                  itemBuilder: (_, i) {
                    if (i == pages.length) return _endNav();
                    return GestureDetector(
                      onDoubleTap: () => _zoom(pages[i]),
                      child: CachedNetworkImage(
                        imageUrl: pages[i],
                        fit: BoxFit.fitWidth,
                        width: double.infinity,
                        placeholder: (_, __) => Container(
                          height: 400, color: Colors.black,
                          child: const Center(child: CircularProgressIndicator(strokeWidth: 2, color: SonamiTheme.accent)),
                        ),
                        errorWidget: (_, __, ___) => Container(
                          height: 200, color: Colors.black,
                          child: const Center(child: Icon(Icons.broken_image_outlined, color: SonamiTheme.faint)),
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          ),
          // top chrome
          AnimatedPositioned(
            duration: const Duration(milliseconds: 250),
            top: _chrome ? 0 : -120,
            left: 0, right: 0,
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter,
                    colors: [Colors.black87, Colors.transparent]),
              ),
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(4, 8, 12, 24),
                  child: Row(
                    children: [
                      IconButton(onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.arrow_back, color: Colors.white)),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(_mangaTitle, maxLines: 1, overflow: TextOverflow.ellipsis,
                                style: const TextStyle(color: Colors.white70, fontSize: 12)),
                            Text('Chapter ${_chapterLabel ?? '…'}',
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15)),
                          ],
                        ),
                      ),
                      Text('${_current + 1} / $_total', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                    ],
                  ),
                ),
              ),
            ),
          ),
          // bottom chrome
          AnimatedPositioned(
            duration: const Duration(milliseconds: 250),
            bottom: _chrome ? 0 : -120,
            left: 0, right: 0,
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(begin: Alignment.bottomCenter, end: Alignment.topCenter,
                    colors: [Colors.black87, Colors.transparent]),
              ),
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
                  child: Column(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: pct, color: SonamiTheme.accent,
                          backgroundColor: Colors.white12, minHeight: 4,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: widget.prevId == null ? null : () => _go(widget.prevId),
                              style: OutlinedButton.styleFrom(foregroundColor: Colors.white70,
                                  side: const BorderSide(color: SonamiTheme.line)),
                              child: const Text('← Prev'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: FilledButton(
                              onPressed: widget.nextId == null ? null : () => _go(widget.nextId),
                              style: FilledButton.styleFrom(backgroundColor: SonamiTheme.accent),
                              child: const Text('Next →'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _endNav() {
    return Container(
      color: Colors.black,
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
      child: Column(
        children: [
          Text('End of chapter ${_chapterLabel ?? ''}',
              style: const TextStyle(color: SonamiTheme.muted, fontSize: 14)),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: widget.prevId == null ? null : () => _go(widget.prevId),
                  style: OutlinedButton.styleFrom(foregroundColor: Colors.white70,
                      side: const BorderSide(color: SonamiTheme.line),
                      padding: const EdgeInsets.symmetric(vertical: 14)),
                  child: const Text('← Prev chapter'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: widget.nextId == null ? null : () => _go(widget.nextId),
                  style: FilledButton.styleFrom(backgroundColor: SonamiTheme.accent,
                      padding: const EdgeInsets.symmetric(vertical: 14)),
                  child: const Text('Next chapter →'),
                ),
              ),
            ],
          ),
          if (widget.nextId == null)
            const Padding(
              padding: EdgeInsets.only(top: 16),
              child: Text("You're all caught up.", style: TextStyle(color: SonamiTheme.faint, fontSize: 13)),
            ),
        ],
      ),
    );
  }

  void _zoom(String url) {
    showDialog(
      context: context,
      builder: (_) => Dialog.fullscreen(
        backgroundColor: Colors.black,
        child: Stack(
          children: [
            PhotoView(
              imageProvider: CachedNetworkImageProvider(url),
              minScale: PhotoViewComputedScale.contained,
              maxScale: PhotoViewComputedScale.covered * 3,
              backgroundDecoration: const BoxDecoration(color: Colors.black),
            ),
            Positioned(
              top: 8, right: 8,
              child: SafeArea(
                child: IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
