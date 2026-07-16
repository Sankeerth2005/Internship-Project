import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'dart:ui';

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
      backgroundColor: const Color(0xFF0F0E0D),
      // Use extendBody: true so the Scaffold content flows behind our floating bottom bar
      extendBody: true,
      body: widget.navigationShell,
      bottomNavigationBar: Container(
        height: 75,
        margin: EdgeInsets.fromLTRB(
          20, 
          0, 
          20, 
          20 + MediaQuery.of(context).padding.bottom / 2
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.4),
              blurRadius: 25,
              spreadRadius: 2,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF161412).withValues(alpha: 0.85),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: const Color(0xFFFF6B00).withValues(alpha: 0.15),
                  width: 1.2,
                ),
              ),
              child: NavigationBarTheme(
                data: NavigationBarThemeData(
                  height: 75,
                  labelTextStyle: WidgetStateProperty.resolveWith((states) {
                    if (states.contains(WidgetState.selected)) {
                      return const TextStyle(
                        color: Color(0xFFFF8C00),
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                      );
                    }
                    return TextStyle(
                      color: Colors.white.withValues(alpha: 0.4),
                      fontSize: 10,
                      fontWeight: FontWeight.normal,
                    );
                  }),
                ),
                child: NavigationBar(
                  height: 75,
                  backgroundColor: Colors.transparent,
                  surfaceTintColor: Colors.transparent,
                  indicatorColor: const Color(0xFFFF6B00).withValues(alpha: 0.15),
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
                      icon: Icon(Icons.home_outlined, size: 24),
                      selectedIcon: Icon(Icons.home_rounded, size: 24),
                      label: 'Home',
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.favorite_border_rounded, size: 24),
                      selectedIcon: Icon(Icons.favorite_rounded, size: 24),
                      label: 'Favorites',
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.person_outline_rounded, size: 24),
                      selectedIcon: Icon(Icons.person_rounded, size: 24),
                      label: 'Profile',
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
