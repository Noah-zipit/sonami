import 'package:flutter/material.dart';
import '../theme.dart';
import '../screens/reader_screen.dart';

/// The big "Continue reading" card with a Resume button, shared by Home
/// and Library so both show the same look.
class ContinueReadingCard extends StatelessWidget {
  final Map progress;
  final double width;

  const ContinueReadingCard({super.key, required this.progress, this.width = 250});

  void _resume(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ReaderScreen(
          mangaId: progress['mangaId'].toString(),
          chapterId: progress['chapterId'].toString(),
          resumePage: (progress['page'] as num?)?.toInt() ?? 0,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _resume(context),
      child: SizedBox(
        width: width,
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  (progress['mangaTitle'] ?? '').toString(),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                ),
                const SizedBox(height: 4),
                Text(
                  'Ch. ${progress['chapter'] ?? '?'} · page ${((progress['page'] as num?)?.toInt() ?? 0) + 1}',
                  style: const TextStyle(color: SonamiTheme.muted, fontSize: 12),
                ),
                const Spacer(),
                const Row(
                  children: [
                    Icon(Icons.play_circle_fill, color: SonamiTheme.accent, size: 20),
                    SizedBox(width: 6),
                    Text('Resume',
                        style: TextStyle(
                            color: SonamiTheme.accent, fontWeight: FontWeight.w700, fontSize: 13)),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
