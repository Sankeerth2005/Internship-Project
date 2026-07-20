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
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          height: 80,
          margin: const EdgeInsets.fromLTRB(20, 0, 20, 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.5),
                blurRadius: 20,
                spreadRadius: 1,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF161412).withValues(alpha: 0.85),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: const Color(0xFFFF6B00).withValues(alpha: 0.20),
                    width: 1.2,
                  ),
                ),
                child: NavigationBarTheme(
                  data: NavigationBarThemeData(
                    height: 80,
                    indicatorColor: const Color(0xFFFF6B00).withValues(alpha: 0.15),
                    labelTextStyle: WidgetStateProperty.resolveWith((states) {
                      if (states.contains(WidgetState.selected)) {
                        return const TextStyle(
                          color: Color(0xFFFF8C00),
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        );
                      }
                      return TextStyle(
                        color: Colors.white.withValues(alpha: 0.5),
                        fontSize: 11,
                        fontWeight: FontWeight.normal,
                      );
                    }),
                  ),
                  child: NavigationBar(
                    height: 80,
                    backgroundColor: Colors.transparent,
                    surfaceTintColor: Colors.transparent,
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
                        icon: Icon(Icons.home_outlined, size: 24, color: Colors.white60),
                        selectedIcon: Icon(Icons.home_rounded, size: 24, color: Color(0xFFFF8C00)),
                        label: 'Home',
                      ),
                      NavigationDestination(
                        icon: Icon(Icons.favorite_border_rounded, size: 24, color: Colors.white60),
                        selectedIcon: Icon(Icons.favorite_rounded, size: 24, color: Color(0xFFFF8C00)),
                        label: 'Favorites',
                      ),
                      NavigationDestination(
                        icon: Icon(Icons.person_outline_rounded, size: 24, color: Colors.white60),
                        selectedIcon: Icon(Icons.person_rounded, size: 24, color: Color(0xFFFF8C00)),
                        label: 'Profile',
                      ),
                      NavigationDestination(
                        icon: Icon(Icons.chat_bubble_outline_rounded, size: 24, color: Colors.white60),
                        selectedIcon: Icon(Icons.chat_bubble_rounded, size: 24, color: Color(0xFFFF8C00)),
                        label: 'AI Chat',
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
