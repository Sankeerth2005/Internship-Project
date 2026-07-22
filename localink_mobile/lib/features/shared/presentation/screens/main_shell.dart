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
      backgroundColor: const Color(0xFFFFFFFF),
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
                color: const Color(0xFF1A1918).withValues(alpha: 0.07),
                blurRadius: 16,
                spreadRadius: 1,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFFFF).withValues(alpha: 0.88),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: const Color(0xFFEAE8E3),
                    width: 1.2,
                  ),
                ),
                child: NavigationBarTheme(
                  data: NavigationBarThemeData(
                    height: 80,
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
        ),
      ),
    );
  }
}
