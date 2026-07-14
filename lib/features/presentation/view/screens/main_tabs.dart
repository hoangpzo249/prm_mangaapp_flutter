import 'package:flutter/material.dart';
import 'package:ionicons/ionicons.dart';

import '../../../../core/constants/app_colors.dart';
import 'explore/explore_screen.dart';
import 'history/history_screen.dart';
import 'home/home_screen.dart';

/// Lets descendants request a tab switch, optionally passing a sort mode
/// or genre filter to the Explore tab.
class TabsScope extends InheritedWidget {
  final void Function(int index, {String? sort, List<String>? genreIds}) goToTab;
  const TabsScope({super.key, required this.goToTab, required super.child});

  static TabsScope of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<TabsScope>()!;

  @override
  bool updateShouldNotify(TabsScope oldWidget) => false;
}

class MainTabs extends StatefulWidget {
  final int initialIndex;
  final String? exploreSort;
  final List<String>? exploreGenreIds;
  const MainTabs({
    super.key,
    this.initialIndex = 0,
    this.exploreSort,
    this.exploreGenreIds,
  });

  @override
  State<MainTabs> createState() => _MainTabsState();
}

class _MainTabsState extends State<MainTabs> {
  late int _index = widget.initialIndex;
  late String? _exploreSort = widget.exploreSort;
  late List<String>? _exploreGenreIds = widget.exploreGenreIds;
  final ValueNotifier<int> _historyRefresh = ValueNotifier<int>(0);

  @override
  void dispose() {
    _historyRefresh.dispose();
    super.dispose();
  }

  void _goToTab(int index, {String? sort, List<String>? genreIds}) {
    setState(() {
      _index = index;
      if (sort != null) _exploreSort = sort;
      if (genreIds != null) _exploreGenreIds = genreIds;
    });
    if (index == 2) _historyRefresh.value++;
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      const HomeScreen(),
      ExploreScreen(
        initialSort: _exploreSort,
        initialGenreIds: _exploreGenreIds,
      ),
      HistoryScreen(refreshTrigger: _historyRefresh),
    ];

    return TabsScope(
      goToTab: _goToTab,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: IndexedStack(index: _index, children: pages),
        bottomNavigationBar: Container(
          decoration: const BoxDecoration(
            color: AppColors.surface,
            border: Border(top: BorderSide(color: AppColors.card, width: 1)),
          ),
          child: SafeArea(
            top: false,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 70),
              child: Padding(
                padding: const EdgeInsets.only(top: 5, bottom: 10),
                child: Row(
                  children: [
                    _tab(0, Ionicons.home, 'Home'),
                    _tab(1, Ionicons.list, 'Manga List'),
                    _tab(2, Ionicons.time, 'History'),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _tab(int index, IconData icon, String label) {
    final active = _index == index;
    final color = active ? AppColors.primary : AppColors.textDim;
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => _goToTab(index),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 24, color: color),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
