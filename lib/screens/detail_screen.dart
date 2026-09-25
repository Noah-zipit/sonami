import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../api.dart';
import '../models.dart';
import '../store.dart';
import '../theme.dart';
import '../widgets/manga_card.dart';
import 'reader_screen.dart';

class DetailScreen extends StatefulWidget {
  final String mangaId;
  const DetailScreen({super.key, required this.mangaId});

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  late Future<Manga> _manga;
  late Future<List<Chapter>> _feed;
  bool _newestFirst = true;
  bool _expanded = false;

  @override
  void initState() {
    super.initState();
    _manga = SonamiApi.getManga(widget.mangaId);
    _feed = SonamiApi.getFeed(widget.mangaId);
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<LibraryStore>();
    return Scaffold(
      body: FutureBuilder<Manga>(
        future: _manga,
        builder: (_, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                const Text('Failed to load.', style: TextStyle(color: SonamiTheme.muted)),
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Go back')),
              ]),
            );
          }
          final m = snap.data!;
          final shelf = store.ready ? store.shelfOf(m.id) : null;
          final prog = store.ready ? store.progressFor(m.id) : null;
          return CustomScrollView(
            slivers: [
              SliverAppBar(
                pinned: true,
                expandedHeight: 300,
                flexibleSpace: FlexibleSpaceBar(
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      CachedNetworkImage(
                        imageUrl: SonamiApi.px(m.coverLarge),
                        fit: BoxFit.cover,
                        errorWidget: (_, __, ___) => Container(color: SonamiTheme.surface),
                      ),
                      Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter, end: Alignment.bottomCenter,
                            colors: [Colors.transparent, Color(0xCC0A0A0F), Color(0xFF0A0A0F)],
                            stops: [0.3, 0.75, 1.0],
                          ),
                        ),
                      ),
                      Positioned(
                        left: 16, right: 16, bottom: 14,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: CachedNetworkImage(
                                imageUrl: SonamiApi.px(m.cover),
                                width: 92, height: 122, fit: BoxFit.cover,
                                errorWidget: (_, __, ___) => Container(width: 92, height: 122, color: SonamiTheme.card),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(m.title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                                  const SizedBox(height: 4),
                                  Text(
                                    [if (m.author != null) m.author!, m.status, if (m.year != null) '${m.year}']
                                        .join(' · '),
                                    style: const TextStyle(color: SonamiTheme.muted, fontSize: 12.5),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // shelf buttons
                      Wrap(
                        spacing: 8,
                        children: [
                          _shelfBtn(store, m, 'reading', 'Reading', shelf),
                          _shelfBtn(store, m, 'completed', 'Completed', shelf),
                          _shelfBtn(store, m, 'planned', 'Plan to read', shelf),
                        ],
                      ),
                      if (prog != null) ...[
                        const SizedBox(height: 10),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton.icon(
                            style: FilledButton.styleFrom(
                              backgroundColor: SonamiTheme.accent,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                            onPressed: () => Navigator.push(context, MaterialPageRoute(
                              builder: (_) => ReaderScreen(
                                mangaId: m.id,
                                chapterId: (prog['chapterId'] ?? '').toString(),
                                resumePage: (prog['page'] as num?)?.toInt() ?? 0,
                              ),
                            )),
                            icon: const Icon(Icons.play_arrow),
                            label: Text('Continue — Ch. ${prog['chapter'] ?? '?'}'),
                          ),
                        ),
                      ],
                      const SizedBox(height: 14),
                      // description
                      GestureDetector(
                        onTap: () => setState(() => _expanded = !_expanded),
                        child: Text(
                          m.description.isEmpty ? 'No description available.' : m.description,
                          maxLines: _expanded ? null : 4,
                          overflow: _expanded ? null : TextOverflow.ellipsis,
                          style: const TextStyle(color: SonamiTheme.muted, fontSize: 13.5, height: 1.5),
                        ),
                      ),
                      if (m.tags.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8, runSpacing: 8,
                          children: m.tags.take(12).map((t) => Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: SonamiTheme.card,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: SonamiTheme.line),
                            ),
                            child: Text(t, style: const TextStyle(fontSize: 12, color: SonamiTheme.muted)),
                          )).toList(),
                        ),
                      ],
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 8, 4),
                  child: Row(
                    children: [
                      const Text('Chapters', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                      const Spacer(),
                      TextButton.icon(
                        onPressed: () => setState(() => _newestFirst = !_newestFirst),
                        icon: Icon(_newestFirst ? Icons.arrow_downward : Icons.arrow_upward, size: 16),
                        label: Text(_newestFirst ? 'Newest' : 'Oldest',
                            style: const TextStyle(color: SonamiTheme.accent)),
                      ),
                    ],
                  ),
                ),
              ),
              FutureBuilder<List<Chapter>>(
                future: _feed,
                builder: (_, snap2) {
                  if (snap2.connectionState == ConnectionState.waiting) {
                    return const SliverToBoxAdapter(
                      child: SizedBox(height: 120, child: Center(child: CircularProgressIndicator())));
                  }
                  if (snap2.hasError || (snap2.data ?? []).isEmpty) {
                    return const SliverToBoxAdapter(
                      child: Padding(padding: EdgeInsets.all(24),
                        child: Text('No chapters available.', style: TextStyle(color: SonamiTheme.muted), textAlign: TextAlign.center)));
                  }
                  final list = snap2.data!;
                  final ordered = _newestFirst ? list.reversed.toList() : list;
                  return SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (_, i) {
                        final c = ordered[i];
                        if (c.externalUrl != null) return const SizedBox.shrink();
                        final idx = list.indexOf(c);
                        final prev = idx > 0 ? list[idx - 1].id : null;
                        final next = idx < list.length - 1 ? list[idx + 1].id : null;
                        final isRead = prog != null &&
                            chapterNum(prog['chapter']?.toString()) >= chapterNum(c.chapter);
                        return ChapterTile(
                          chapter: c, read: isRead,
                          onTap: () => Navigator.push(context, MaterialPageRoute(
                            builder: (_) => ReaderScreen(
                              mangaId: m.id, chapterId: c.id,
                              prevId: prev, nextId: next,
                            ),
                          )),
                        );
                      },
                      childCount: ordered.length,
                    ),
                  );
                },
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 32)),
            ],
          );
        },
      ),
    );
  }

  Widget _shelfBtn(LibraryStore store, Manga m, String value, String label, String? current) {
    final active = current == value;
    return ChoiceChip(
      label: Text(label),
      selected: active,
      onSelected: (_) => store.setShelf(m.id, active ? null : value, title: m.title, cover: m.coverSmall),
      selectedColor: SonamiTheme.accent,
      backgroundColor: SonamiTheme.card,
      side: BorderSide(color: active ? SonamiTheme.accent : SonamiTheme.line),
      labelStyle: TextStyle(color: active ? Colors.white : SonamiTheme.muted, fontSize: 13, fontWeight: FontWeight.w600),
    );
  }
}
