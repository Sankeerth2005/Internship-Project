import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class MainShell extends ConsumerStatefulWidget {
  final StatefulNavigationShell navigationShell;

  const MainShell({super.key, required this.navigationShell});

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell> {
  // Stack to track tab navigation history for proper back button behavior
  final List<int> _tabHistory = [0];

  @override
  Widget build(BuildContext context) {
    final currentIndex = widget.navigationShell.currentIndex;
    final keyboardOpen = MediaQuery.viewInsetsOf(context).bottom > 0;

    // Track tab changes by adding to history stack
    if (_tabHistory.isEmpty || _tabHistory.last != currentIndex) {
      _tabHistory.add(currentIndex);
      // Keep history manageable
      if (_tabHistory.length > 10) {
        _tabHistory.removeAt(0);
      }
    }
    return PopScope(
      canPop: currentIndex == 0 && _tabHistory.length <= 1,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        // Pop the current tab from history
        if (_tabHistory.isNotEmpty) {
          _tabHistory.removeLast();
        }
        // Navigate back to the previous tab, or to home if no history
        final targetIndex = _tabHistory.isNotEmpty ? _tabHistory.last : 0;
        widget.navigationShell.goBranch(targetIndex);
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFFFFFFF),
        // Fixed bottom navigation (admin-style): stays put while content scrolls.
        // Hide while keyboard is open so composers (e.g. AI Chat) are not crushed.
        resizeToAvoidBottomInset: true,
        body: widget.navigationShell,
        bottomNavigationBar: keyboardOpen
            ? null
            : SafeArea(
                top: false,
                child: Container(
                  decoration: const BoxDecoration(
                    color: Color(0xFFFFFFFF),
                    border: Border(
                      top: BorderSide(color: Color(0xFFEAE8E3), width: 1),
                    ),
                  ),
                  child: NavigationBarTheme(
                    data: NavigationBarThemeData(
                      height: 64,
                      indicatorColor: const Color(0xFFFF6600).withValues(alpha: 0.12),
                      labelTextStyle: WidgetStateProperty.resolveWith((states) {
                        if (states.contains(WidgetState.selected)) {
                          return const TextStyle(
                            color: Color(0xFFFF6600),
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            fontFamily: 'Inter',
                          );
                        }
                        return const TextStyle(
                          color: Color(0xFF5F5C58),
                          fontSize: 11,
                          fontWeight: FontWeight.normal,
                          fontFamily: 'Inter',
                        );
                      }),
                    ),
                    child: NavigationBar(
                      height: 64,
                      backgroundColor: Colors.transparent,
                      surfaceTintColor: Colors.transparent,
                      elevation: 0,
                      selectedIndex: widget.navigationShell.currentIndex,
                      onDestinationSelected: (index) {
                        widget.navigationShell.goBranch(
                          index,
                          initialLocation: index == widget.navigationShell.currentIndex,
                        );
                      },
                      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
                      destinations: const [
                        NavigationDestination(
                          icon: Icon(Icons.home_outlined, size: 24, color: Color(0xFF5F5C58)),
                          selectedIcon: Icon(Icons.home_rounded, size: 24, color: Color(0xFFFF6600)),
                          label: 'Home',
                        ),
                        NavigationDestination(
                          icon: Icon(Icons.favorite_border_rounded, size: 24, color: Color(0xFF5F5C58)),
                          selectedIcon: Icon(Icons.favorite_rounded, size: 24, color: Color(0xFFFF6600)),
                          label: 'Favorites',
                        ),
                        NavigationDestination(
                          icon: Icon(Icons.forum_outlined, size: 24, color: Color(0xFF5F5C58)),
                          selectedIcon: Icon(Icons.forum_rounded, size: 24, color: Color(0xFFFF6600)),
                          label: 'Support',
                        ),
                        NavigationDestination(
                          icon: Icon(Icons.chat_bubble_outline_rounded, size: 24, color: Color(0xFF5F5C58)),
                          selectedIcon: Icon(Icons.chat_bubble_rounded, size: 24, color: Color(0xFFFF6600)),
                          label: 'AI Chat',
                        ),
                      ],
                    ),
                  ),
                ),
              ),
      ),
    );
  }
}
