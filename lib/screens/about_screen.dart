import 'package:flutter/material.dart';
import '../theme.dart';

/// About Sonami — what it is, where its data comes from, version.
class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('About')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const SizedBox(height: 8),
          Center(
            child: Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: const Color(0xFF0A0A0F),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: SonamiTheme.line),
              ),
              child: const Icon(Icons.menu_book_rounded, color: SonamiTheme.accent, size: 44),
            ),
          ),
          const SizedBox(height: 16),
          const Center(
            child: Text('Sonami', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800)),
          ),
          const SizedBox(height: 4),
          const Center(
            child: Text('Version 1.1.0', style: TextStyle(color: SonamiTheme.muted, fontSize: 13)),
          ),
          const SizedBox(height: 12),
          const Center(
            child: Text(
              'Read everything.',
              style: TextStyle(
                  color: SonamiTheme.accent, fontWeight: FontWeight.w700, fontSize: 15),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Sonami is a free manga and manhwa reader with tracking built in. '
            'Follow series across shelves, pick up exactly where you left off, '
            'and keep your lifetime reading stats — all stored on your device. '
            'No accounts, no ads.',
            textAlign: TextAlign.center,
            style: TextStyle(color: SonamiTheme.muted, fontSize: 14, height: 1.5),
          ),
          const SizedBox(height: 24),
          const Divider(color: SonamiTheme.line, height: 1),
          const SizedBox(height: 8),
          _row('Catalog data', 'MangaDex API'),
          _row('Chapter images', 'Proxied through the Sonami backend'),
          _row('Backend', 'sonami-dex-proto.vercel.app'),
          _row('Source code', 'github.com/Noah-zipit/sonami-flutter'),
          const SizedBox(height: 24),
          const Text(
            'Thanks to MangaDex and the scanlation groups who make '
            'these stories available.',
            textAlign: TextAlign.center,
            style: TextStyle(color: SonamiTheme.faint, fontSize: 12.5, height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(label,
                style: const TextStyle(color: SonamiTheme.muted, fontSize: 13.5)),
          ),
          Expanded(
            child: SelectableText(value,
                style: const TextStyle(
                    color: SonamiTheme.text, fontSize: 13.5, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}
