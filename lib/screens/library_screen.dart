import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../api.dart';
import '../store.dart';
import '../theme.dart';
import 'detail_screen.dart';
import 'reader_screen.dart';

const _shelves = [
  ('reading', 'Reading'),
  ('completed', 'Completed'),
  ('planned', 'Plan to read'),
  ('dropped', 'Dropped'),
];

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});
  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> with SingleTickerProviderStateMixin {
  late TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: _shelves.length, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<LibraryStore>();
    return Column(
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 18, 16, 4),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text('My library', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800)),
          ),
        ),
        if (store.ready && store.recentProgress().isNotEmpty) ...[
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 12, 16, 6),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text('CONTINUE READING',
                  style: TextStyle(fontSize: 11, letterSpacing: 1.4, color: SonamiTheme.accent, fontWeight: FontWeight.w700)),
            ),
          ),
          SizedBox(
            height: 92,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: store.recentProgress().length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (_, i) {
                final e = store.recentProgress()[i];
                final p = e.value as Map;
                return GestureDetector(
                  onTap: () => Navigator.push(context, MaterialPageRoute(
                    builder: (_) => ReaderScreen(
                      mangaId: p['mangaId'].toString(),
                      chapterId: p['chapterId'].toString(),
                      resumePage: (p['page'] as num?)?.toInt() ?? 0,
                    ),
                  )),
                  child: Container(
                    width: 220,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: SonamiTheme.card,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: SonamiTheme.line),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text((p['mangaTitle'] ?? '').toString(), maxLines: 1, overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5)),
                        const SizedBox(height: 3),
                        Text('Ch. ${p['chapter'] ?? '?'} · page ${((p['page'] as num?)?.toInt() ?? 0) + 1}',
                            style: const TextStyle(color: SonamiTheme.accent, fontSize: 12)),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
        TabBar(
          controller: _tab,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          indicatorColor: SonamiTheme.accent,
          labelColor: SonamiTheme.text,
          unselectedLabelColor: SonamiTheme.muted,
          tabs: _shelves.map((s) => Tab(text: s.$2)).toList(),
        ),
        Expanded(
          child: TabBarView(
            controller: _tab,
            children: _shelves.map((s) {
              final items = store.ready ? store.shelf(s.$1) : [];
              if (items.isEmpty) {
                return const Center(
                  child: Text('Nothing here yet.\nAdd series from any manga page.',
                      textAlign: TextAlign.center, style: TextStyle(color: SonamiTheme.muted)),
                );
              }
              return GridView.builder(
                padding: const EdgeInsets.all(16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3, childAspectRatio: 0.55, crossAxisSpacing: 12, mainAxisSpacing: 14),
                itemCount: items.length,
                itemBuilder: (_, i) {
                  final id = items[i].key;
                  final v = items[i].value as Map;
                  final cover = (v['cover'] ?? '').toString();
                  return GestureDetector(
                    onTap: () => Navigator.push(context,
                        MaterialPageRoute(builder: (_) => DetailScreen(mangaId: id))),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: cover.isNotEmpty
                                ? CachedNetworkImage(
                                    imageUrl: SonamiApi.px(cover), fit: BoxFit.cover, width: double.infinity,
                                    errorWidget: (_, __, ___) => Container(color: SonamiTheme.card),
                                  )
                                : Container(color: SonamiTheme.card,
                                    child: const Center(child: Icon(Icons.image_not_supported_outlined, color: SonamiTheme.faint))),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text((v['title'] ?? '').toString(), maxLines: 2, overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  );
                },
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}
