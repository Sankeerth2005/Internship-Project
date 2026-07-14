import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class MainShell extends StatefulWidget {
  final StatefulNavigationShell navigationShell;

  const MainShell({super.key, required this.navigationShell});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0C0C0C),
      body: widget.navigationShell,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF161616),
          border: Border(
            top: BorderSide(color: Colors.white.withValues(alpha: 0.06)),
          ),
        ),
        child: NavigationBar(
          backgroundColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
          indicatorColor: const Color(0xFFFF7A00).withValues(alpha: 0.15),
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
              icon: Icon(Icons.home_outlined, color: Colors.white38),
              selectedIcon: Icon(Icons.home, color: Color(0xFFFF7A00)),
              label: 'Home',
            ),
            NavigationDestination(
              icon: Icon(Icons.favorite_border, color: Colors.white38),
              selectedIcon: Icon(Icons.favorite, color: Color(0xFFFF7A00)),
              label: 'Favorites',
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outline, color: Colors.white38),
              selectedIcon: Icon(Icons.person, color: Color(0xFFFF7A00)),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}
