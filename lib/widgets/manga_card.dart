import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../api.dart';
import '../models.dart';
import '../theme.dart';

class MangaCard extends StatelessWidget {
  final Manga manga;
  final VoidCallback onTap;
  final double width;

  const MangaCard({super.key, required this.manga, required this.onTap, this.width = 130});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: width,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: AspectRatio(
                aspectRatio: 3 / 4,
                child: CachedNetworkImage(
                  imageUrl: SonamiApi.px(manga.coverSmall),
                  fit: BoxFit.cover,
                  placeholder: (_, __) => Container(
                    color: SonamiTheme.card,
                    child: const Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))),
                  ),
                  errorWidget: (_, __, ___) => Container(
                    color: SonamiTheme.card,
                    child: const Center(child: Icon(Icons.broken_image_outlined, color: SonamiTheme.faint)),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(manga.title, maxLines: 2, overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600)),
            if (manga.lastChapter != null)
              Text('Ch. ${manga.lastChapter}', style: const TextStyle(fontSize: 11, color: SonamiTheme.muted)),
          ],
        ),
      ),
    );
  }
}

class SectionHeader extends StatelessWidget {
  final String title;
  final String eyebrow;
  const SectionHeader({super.key, required this.title, this.eyebrow = ''});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (eyebrow.isNotEmpty)
            Text(eyebrow.toUpperCase(),
                style: const TextStyle(fontSize: 11, letterSpacing: 1.4, color: SonamiTheme.accent, fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text(title, style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}

class ChapterTile extends StatelessWidget {
  final Chapter chapter;
  final bool read;
  final VoidCallback onTap;

  const ChapterTile({super.key, required this.chapter, required this.read, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      leading: Container(
        width: 44, height: 44,
        decoration: BoxDecoration(color: SonamiTheme.card, borderRadius: BorderRadius.circular(10), border: Border.all(color: SonamiTheme.line)),
        child: const Icon(Icons.menu_book_outlined, size: 20, color: SonamiTheme.muted),
      ),
      title: Text(chapter.label, maxLines: 1, overflow: TextOverflow.ellipsis,
          style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w600, color: read ? SonamiTheme.muted : SonamiTheme.text)),
      subtitle: Text(
        [if (chapter.group != null) chapter.group!, _ago(chapter.readableAt)].join(' · '),
        style: const TextStyle(fontSize: 12, color: SonamiTheme.muted),
      ),
      trailing: read
          ? const Icon(Icons.check_circle, color: SonamiTheme.accent, size: 20)
          : const Icon(Icons.chevron_right, color: SonamiTheme.faint),
    );
  }
}

String _ago(String iso) {
  try {
    final dt = DateTime.parse(iso).toLocal();
    final d = DateTime.now().difference(dt);
    if (d.inMinutes < 60) return '${d.inMinutes}m ago';
    if (d.inHours < 24) return '${d.inHours}h ago';
    if (d.inDays < 30) return '${d.inDays}d ago';
    return '${dt.day}/${dt.month}/${dt.year}';
  } catch (_) {
    return '';
  }
}
