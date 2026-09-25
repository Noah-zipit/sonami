import 'dart:async';
import 'package:flutter/material.dart';
import '../api.dart';
import '../models.dart';
import '../theme.dart';
import '../widgets/manga_card.dart';
import 'detail_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});
  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _ctrl = TextEditingController();
  Timer? _deb;
  List<Manga> _results = [];
  int _total = 0;
  bool _loading = false;
  bool _searched = false;
  String? _error;

  @override
  void dispose() {
    _deb?.cancel();
    _ctrl.dispose();
    super.dispose();
  }

  void _onChanged(String q) {
    _deb?.cancel();
    if (q.trim().length < 2) {
      setState(() { _results = []; _searched = false; _loading = false; });
      return;
    }
    setState(() => _loading = true);
    _deb = Timer(const Duration(milliseconds: 600), () => _run(q.trim()));
  }

  Future<void> _run(String q) async {
    try {
      final r = await SonamiApi.search(q);
      if (!mounted || _ctrl.text.trim() != q) return;
      setState(() {
        _results = r.items;
        _total = r.total;
        _searched = true;
        _loading = false;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() { _loading = false; _searched = true; _error = 'Search failed — check your connection.'; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
          child: TextField(
            controller: _ctrl,
            onChanged: _onChanged,
            textInputAction: TextInputAction.search,
            onSubmitted: (q) { if (q.trim().length >= 2) _run(q.trim()); },
            decoration: const InputDecoration(
              hintText: 'Search manga, manhwa, manhua…',
              prefixIcon: Icon(Icons.search, color: SonamiTheme.muted),
            ),
          ),
        ),
        if (_loading) const LinearProgressIndicator(color: SonamiTheme.accent, minHeight: 2),
        Expanded(
          child: _error != null
              ? Center(child: Text(_error!, style: const TextStyle(color: SonamiTheme.muted)))
              : !_searched
                  ? const Center(
                      child: Column(mainAxisSize: MainAxisSize.min, children: [
                        Icon(Icons.search, size: 44, color: SonamiTheme.faint),
                        SizedBox(height: 10),
                        Text('Type at least 2 characters', style: TextStyle(color: SonamiTheme.muted)),
                      ]),
                    )
                  : _results.isEmpty
                      ? const Center(child: Text('No results found.', style: TextStyle(color: SonamiTheme.muted)))
                      : GridView.builder(
                          padding: const EdgeInsets.all(16),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            childAspectRatio: 0.52,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 14,
                          ),
                          itemCount: _results.length,
                          itemBuilder: (_, i) => MangaCard(
                            manga: _results[i],
                            width: double.infinity,
                            onTap: () => Navigator.push(context,
                                MaterialPageRoute(builder: (_) => DetailScreen(mangaId: _results[i].id))),
                          ),
                        ),
        ),
        if (_searched && _results.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Text('$_total results', style: const TextStyle(color: SonamiTheme.faint, fontSize: 12)),
          ),
      ],
    );
  }
}
