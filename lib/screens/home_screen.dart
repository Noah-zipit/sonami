import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../api.dart';
import '../models.dart';
import '../store.dart';
import '../theme.dart';
import '../widgets/continue_reading.dart';
import '../widgets/manga_card.dart';
import 'detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<List<Manga>> _trending;
  late Future<List<Chapter>> _latest;

  @override
  void initState() {
    super.initState();
    _trending = SonamiApi.trending();
    _latest = SonamiApi.latestChapters();
  }

  Future<void> _refresh() async {
    setState(() {
      _trending = SonamiApi.trending();
      _latest = SonamiApi.latestChapters();
    });
    await Future.wait([_trending, _latest]);
  }

  void _openManga(String id) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => DetailScreen(mangaId: id)));
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<LibraryStore>();
    final recent = store.ready ? store.recentProgress(limit: 6) : [];
    return RefreshIndicator(
      onRefresh: _refresh,
      color: SonamiTheme.accent,
      child: ListView(
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 18, 16, 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('SONAMI', style: TextStyle(fontSize: 12, letterSpacing: 3, color: SonamiTheme.accent, fontWeight: FontWeight.w800)),
                SizedBox(height: 4),
                Text('Read everything.', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800)),
              ],
            ),
          ),
          if (recent.isNotEmpty) ...[
            const SectionHeader(title: 'Continue reading', eyebrow: 'Pick up where you left off'),
            SizedBox(
              height: 196,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: recent.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (_, i) => ContinueReadingCard(progress: recent[i].value as Map),
              ),
            ),
          ],
          const SectionHeader(title: 'Trending now', eyebrow: 'Most followed'),
          FutureBuilder<List<Manga>>(
            future: _trending,
            builder: (_, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const SizedBox(height: 200, child: Center(child: CircularProgressIndicator()));
              }
              if (snap.hasError) return _err('Couldn\'t load trending.', _refresh);
              final items = snap.data!;
              return SizedBox(
                height: 236,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (_, i) => MangaCard(manga: items[i], onTap: () => _openManga(items[i].id)),
                ),
              );
            },
          ),
          const SectionHeader(title: 'Latest updates', eyebrow: 'Fresh chapters'),
          FutureBuilder<List<Chapter>>(
            future: _latest,
            builder: (_, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const SizedBox(height: 120, child: Center(child: CircularProgressIndicator()));
              }
              if (snap.hasError) return _err('Couldn\'t load updates.', _refresh);
              return Column(
                children: snap.data!.map((c) => ListTile(
                  onTap: () => _openManga(c.mangaId ?? ''),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: SizedBox(
                      width: 44, height: 60,
                      child: c.mangaCover != null
                          ? Image.network(SonamiApi.px(c.mangaCover), fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(color: SonamiTheme.card))
                          : Container(color: SonamiTheme.card, child: const Icon(Icons.image_not_supported_outlined, color: SonamiTheme.faint, size: 20)),
                    ),
                  ),
                  title: Text((c.mangaTitle ?? 'Unknown').toString(), maxLines: 1, overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                  subtitle: Text(c.label, style: const TextStyle(color: SonamiTheme.muted, fontSize: 12.5)),
                  trailing: const Icon(Icons.chevron_right, color: SonamiTheme.faint),
                )).toList(),
              );
            },
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _err(String msg, VoidCallback retry) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(children: [
          Text(msg, style: const TextStyle(color: SonamiTheme.muted)),
          TextButton(onPressed: retry, child: const Text('Retry', style: TextStyle(color: SonamiTheme.accent))),
        ]),
      );
}
