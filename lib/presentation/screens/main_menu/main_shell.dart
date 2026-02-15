import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Main shell with bottom navigation
class MainShell extends ConsumerStatefulWidget {
  final Widget child;

  const MainShell({super.key, required this.child});

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell> {
  int _currentIndex = 0;

  final List<_NavItem> _navItems = const [
    _NavItem(
      path: '/main/home',
      icon: Icons.home_outlined,
      activeIcon: Icons.home,
      label: 'Дом',
    ),
    _NavItem(
      path: '/main/library',
      icon: Icons.library_books_outlined,
      activeIcon: Icons.library_books,
      label: 'Библиотека',
    ),
    _NavItem(
      path: '/main/statistics',
      icon: Icons.bar_chart_outlined,
      activeIcon: Icons.bar_chart,
      label: 'Статистика',
    ),
    _NavItem(
      path: '/main/profile',
      icon: Icons.person_outline,
      activeIcon: Icons.person,
      label: 'Профиль',
    ),
  ];

  void _onTap(int index) {
    setState(() => _currentIndex = index);
    context.go(_navItems[index].path);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Update current index based on location
    final location = GoRouterState.of(context).matchedLocation;
    final index = _navItems.indexWhere((item) => location.startsWith(item.path));
    if (index != -1 && index != _currentIndex) {
      setState(() => _currentIndex = index);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: widget.child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: _onTap,
        destinations: _navItems
            .map((item) => NavigationDestination(
                  icon: Icon(item.icon),
                  selectedIcon: Icon(item.activeIcon),
                  label: item.label,
                ))
            .toList(),
      ),
    );
  }
}

class _NavItem {
  final String path;
  final IconData icon;
  final IconData activeIcon;
  final String label;

  const _NavItem({
    required this.path,
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
}
