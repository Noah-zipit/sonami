import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'store.dart';
import 'theme.dart';
import 'screens/home_screen.dart';
import 'screens/search_screen.dart';
import 'screens/browse_screen.dart';
import 'screens/library_screen.dart';

void main() {
  runApp(const SonamiApp());
}

class SonamiApp extends StatelessWidget {
  const SonamiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => LibraryStore()..load(),
      child: MaterialApp(
        title: 'Sonami',
        debugShowCheckedModeBanner: false,
        theme: SonamiTheme.dark,
        home: const RootNav(),
      ),
    );
  }
}

class RootNav extends StatefulWidget {
  const RootNav({super.key});
  @override
  State<RootNav> createState() => _RootNavState();
}

class _RootNavState extends State<RootNav> {
  int _idx = 0;

  static const _pages = [HomeScreen(), SearchScreen(), BrowseScreen(), LibraryScreen()];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: IndexedStack(index: _idx, children: _pages),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _idx,
        onTap: (i) => setState(() => _idx = i),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.search_outlined), activeIcon: Icon(Icons.search), label: 'Search'),
          BottomNavigationBarItem(icon: Icon(Icons.explore_outlined), activeIcon: Icon(Icons.explore), label: 'Browse'),
          BottomNavigationBarItem(icon: Icon(Icons.bookmark_outline), activeIcon: Icon(Icons.bookmark), label: 'Library'),
        ],
      ),
    );
  }
}
