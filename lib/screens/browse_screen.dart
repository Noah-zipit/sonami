import 'package:flutter/material.dart';
import '../api.dart';
import '../models.dart';
import '../theme.dart';
import '../widgets/manga_card.dart';
import 'detail_screen.dart';

const _sorts = [
  ('popular', 'Popular'),
  ('rating', 'Top rated'),
  ('updated', 'Latest updated'),
  ('new', 'Recently added'),
];

const _statuses = [
  ('', 'All'),
  ('ongoing', 'Ongoing'),
  ('completed', 'Completed'),
  ('hiatus', 'Hiatus'),
  ('cancelled', 'Cancelled'),
];

const _langs = [
  ('', 'All'),
  ('ja', 'Manga'),
  ('ko', 'Manhwa'),
  ('zh', 'Manhua'),
];

class BrowseScreen extends StatefulWidget {
  const BrowseScreen({super.key});
  @override
  State<BrowseScreen> createState() => _BrowseScreenState();
}

class _BrowseScreenState extends State<BrowseScreen> {
  final _scroll = ScrollController();
  List<Manga> _items = [];
  int _total = 0;
  bool _loading = true;
  bool _loadingMore = false;
  String? _error;

  String _sort = 'popular';
  String _status = '';
  String _lang = '';
  final Set<String> _tagIds = {};
  List<({String id, String name})> _allTags = [];
  String _tagQuery = '';

  @override
  void initState() {
    super.initState();
    _scroll.addListener(() {
      if (_scroll.position.pixels >= _scroll.position.maxScrollExtent - 600 &&
          !_loading && !_loadingMore && _items.length < _total) {
        _loadMore();
      }
    });
    _reload();
    _loadTags();
  }

  Future<void> _loadTags() async {
    try {
      final t = await SonamiApi.fetchTags();
      if (mounted) setState(() => _allTags = t);
    } catch (_) {
      // Tags are optional garnish; browse works without them.
    }
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _reload() async {
    setState(() { _loading = true; _error = null; });
    try {
      final r = await SonamiApi.browse(
        sort: _sort,
        status: _status.isEmpty ? [] : [_status],
        langs: _lang.isEmpty ? [] : [_lang],
        tagIds: _tagIds.toList(),
      );
      if (!mounted) return;
      setState(() { _items = r.items; _total = r.total; _loading = false; });
    } catch (e) {
      if (!mounted) return;
      setState(() { _loading = false; _error = 'Could not load — check your connection.'; });
    }
  }

  Future<void> _loadMore() async {
    setState(() => _loadingMore = true);
    try {
      final r = await SonamiApi.browse(
        offset: _items.length,
        sort: _sort,
        status: _status.isEmpty ? [] : [_status],
        langs: _lang.isEmpty ? [] : [_lang],
        tagIds: _tagIds.toList(),
      );
      if (!mounted) return;
      setState(() {
        _items = [..._items, ...r.items];
        _total = r.total;
        _loadingMore = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loadingMore = false);
    }
  }

  void _setSort(String v) { setState(() => _sort = v); _reload(); }
  void _setStatus(String v) { setState(() => _status = v); _reload(); }
  void _setLang(String v) { setState(() => _lang = v); _reload(); }

  void _openTagSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: SonamiTheme.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) {
          final q = _tagQuery.toLowerCase();
          final tags = _allTags.where((t) => q.isEmpty || t.name.toLowerCase().contains(q)).toList();
          return DraggableScrollableSheet(
            expand: false,
            initialChildSize: 0.8,
            builder: (_, sc) => Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const Expanded(
                        child: Text('Genres & themes', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: SonamiTheme.text)),
                      ),
                      TextButton(
                        onPressed: () {
                          setSheet(() => _tagQuery = '');
                          setState(() => _tagIds.clear());
                          _reload();
                        },
                        child: const Text('Clear', style: TextStyle(color: SonamiTheme.accent)),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('Done', style: TextStyle(color: SonamiTheme.accent)),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: TextField(
                    onChanged: (v) => setSheet(() => _tagQuery = v),
                    decoration: const InputDecoration(
                      hintText: 'Filter tags…',
                      prefixIcon: Icon(Icons.search, color: SonamiTheme.muted),
                      isDense: true,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: tags.isEmpty
                      ? const Center(child: Text('Loading tags…', style: TextStyle(color: SonamiTheme.muted)))
                      : ListView.builder(
                          controller: sc,
                          itemCount: tags.length,
                          itemBuilder: (_, i) {
                            final t = tags[i];
                            final sel = _tagIds.contains(t.id);
                            return CheckboxListTile(
                              dense: true,
                              value: sel,
                              activeColor: SonamiTheme.accent,
                              title: Text(t.name, style: const TextStyle(color: SonamiTheme.text)),
                              onChanged: (v) {
                                setSheet(() {
                                  if (v == true) {
                                    _tagIds.add(t.id);
                                  } else {
                                    _tagIds.remove(t.id);
                                  }
                                });
                                setState(() {});
                              },
                            );
                          },
                        ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      style: FilledButton.styleFrom(backgroundColor: SonamiTheme.accent),
                      onPressed: () { Navigator.pop(ctx); _reload(); },
                      child: Text('Apply (${_tagIds.length})'),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    ).then((_) => setState(() => _tagQuery = ''));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 16, 16, 4),
          child: Text('Browse', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: SonamiTheme.text)),
        ),
        // Sort + tag picker row
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                decoration: BoxDecoration(
                  color: SonamiTheme.card,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: SonamiTheme.line),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _sort,
                    dropdownColor: SonamiTheme.surface,
                    style: const TextStyle(color: SonamiTheme.text, fontSize: 14),
                    items: _sorts.map((s) => DropdownMenuItem(value: s.$1, child: Text(s.$2))).toList(),
                    onChanged: (v) { if (v != null) _setSort(v); },
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _openTagSheet,
                  icon: const Icon(Icons.tune, size: 18, color: SonamiTheme.accent),
                  label: Text(
                    _tagIds.isEmpty ? 'Genres' : 'Genres (${_tagIds.length})',
                    style: const TextStyle(color: SonamiTheme.text),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: SonamiTheme.line),
                    backgroundColor: SonamiTheme.card,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
        ),
        // Status chips
        _chipRow('Status', _statuses, _status, _setStatus),
        // Language chips
        _chipRow('Origin', _langs, _lang, _setLang),
        const Divider(color: SonamiTheme.line, height: 1),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator(color: SonamiTheme.accent))
              : _error != null
                  ? Center(child: Text(_error!, style: const TextStyle(color: SonamiTheme.muted)))
                  : _items.isEmpty
                      ? const Center(child: Text('Nothing matches those filters.', style: TextStyle(color: SonamiTheme.muted)))
                      : GridView.builder(
                          controller: _scroll,
                          padding: const EdgeInsets.all(16),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            childAspectRatio: 0.52,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 14,
                          ),
                          itemCount: _items.length + (_loadingMore ? 1 : 0),
                          itemBuilder: (_, i) {
                            if (i >= _items.length) {
                              return const Center(child: CircularProgressIndicator(color: SonamiTheme.accent));
                            }
                            final m = _items[i];
                            return MangaCard(
                              manga: m,
                              width: double.infinity,
                              onTap: () => Navigator.push(context,
                                  MaterialPageRoute(builder: (_) => DetailScreen(mangaId: m.id))),
                            );
                          },
                        ),
        ),
      ],
    );
  }

  Widget _chipRow(String label, List<(String, String)> options, String current, void Function(String) onPick) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 2, 16, 2),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            SizedBox(
              width: 52,
              child: Text(label, style: const TextStyle(color: SonamiTheme.faint, fontSize: 12)),
            ),
            ...options.map((o) {
              final sel = o.$1 == current;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(o.$2),
                  selected: sel,
                  onSelected: (_) => onPick(o.$1),
                  selectedColor: SonamiTheme.accentDeep,
                  backgroundColor: SonamiTheme.card,
                  side: BorderSide(color: sel ? SonamiTheme.accent : SonamiTheme.line),
                  labelStyle: TextStyle(color: sel ? Colors.white : SonamiTheme.muted, fontSize: 13),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
