import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../store.dart';
import '../theme.dart';

String _fmtDuration(int totalSeconds) {
  final h = totalSeconds ~/ 3600;
  final m = (totalSeconds % 3600) ~/ 60;
  if (h > 0) return '${h}h ${m}m';
  if (m > 0) return '${m}m';
  return '${totalSeconds}s';
}

String _fmtCount(int n) {
  if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
  if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
  return '$n';
}

/// Lifetime reading stats — chapters read, pages turned, time spent, shelves.
class StatsScreen extends StatelessWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = context.watch<LibraryStore>();
    final s = store.statsSummary();
    final tiles = [
      (Icons.menu_book_outlined, _fmtCount(s['chapters']!), 'Chapters read'),
      (Icons.find_in_page_outlined, _fmtCount(s['pages']!), 'Pages turned'),
      (Icons.schedule_outlined, _fmtDuration(s['seconds']!), 'Time reading'),
      (Icons.library_books_outlined, _fmtCount(s['series']!), 'Series started'),
    ];
    final shelves = [
      ('reading', 'Reading', Icons.playlist_play),
      ('completed', 'Completed', Icons.check_circle_outline),
      ('planned', 'Plan to read', Icons.bookmark_add_outlined),
      ('dropped', 'Dropped', Icons.remove_circle_outline),
    ];
    return Scaffold(
      appBar: AppBar(title: const Text('Reading stats')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2, childAspectRatio: 1.35, crossAxisSpacing: 12, mainAxisSpacing: 12),
            itemCount: tiles.length,
            itemBuilder: (_, i) {
              final t = tiles[i];
              return Container(
                decoration: BoxDecoration(
                  color: SonamiTheme.card,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: SonamiTheme.line),
                ),
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(t.$1, color: SonamiTheme.accent, size: 22),
                    const SizedBox(height: 8),
                    Text(t.$2,
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 2),
                    Text(t.$3, style: const TextStyle(color: SonamiTheme.muted, fontSize: 12.5)),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 20),
          const Text('Shelves',
              style: TextStyle(fontSize: 13, letterSpacing: 1.2, color: SonamiTheme.accent, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          ...shelves.map((sh) {
            final count = store.ready ? store.shelf(sh.$1).length : 0;
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: SonamiTheme.card,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: SonamiTheme.line),
              ),
              child: ListTile(
                leading: Icon(sh.$3, color: SonamiTheme.muted),
                title: Text(sh.$2, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                trailing: Text('$count',
                    style: const TextStyle(
                        color: SonamiTheme.accent, fontWeight: FontWeight.w800, fontSize: 16)),
              ),
            );
          }),
          const SizedBox(height: 12),
          const Text(
            'Stats are kept on this device only.',
            textAlign: TextAlign.center,
            style: TextStyle(color: SonamiTheme.faint, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
