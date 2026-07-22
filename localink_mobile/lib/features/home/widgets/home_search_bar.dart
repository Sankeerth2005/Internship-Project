import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class HomeSearchBar extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final VoidCallback onVoiceTap;
  final List<String> recentSearches;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onClear;
  final Widget? suggestionsOverlay;
  final bool showHistory;

  const HomeSearchBar({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.onVoiceTap,
    required this.recentSearches,
    required this.onSearchChanged,
    required this.onClear,
    this.suggestionsOverlay,
    required this.showHistory,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              // Search Input Box
              Expanded(
                child: Container(
                  height: 48,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF9F8F6),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: focusNode.hasFocus
                          ? const Color(0xFFFF6600)
                          : const Color(0xFFEAE8E3),
                      width: focusNode.hasFocus ? 2.0 : 1.0,
                    ),
                  ),
                  child: TextField(
                    controller: controller,
                    focusNode: focusNode,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      color: Color(0xFF1A1918),
                      fontSize: 14,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Search business, category, area...',
                      hintStyle: const TextStyle(
                        fontFamily: 'Inter',
                        color: Color(0xFF9F9B96),
                        fontSize: 13,
                      ),
                      prefixIcon: const Icon(
                        Icons.search_rounded,
                        color: Color(0xFFFF6600),
                        size: 20,
                      ),
                      suffixIcon: controller.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(
                                Icons.clear_rounded,
                                color: Color(0xFF9F9B96),
                                size: 18,
                              ),
                              onPressed: () {
                                HapticFeedback.lightImpact();
                                onClear();
                              },
                            )
                          : null,
                      filled: false,
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onChanged: onSearchChanged,
                  ),
                ),
              ),
              const SizedBox(width: 10),

              // Voice Search Microphone Button
              GestureDetector(
                onTap: () {
                  HapticFeedback.mediumImpact();
                  onVoiceTap();
                },
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFF9E4F), Color(0xFFFF6600)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFF6600).withValues(alpha: 0.22),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      )
                    ],
                  ),
                  child: const Icon(
                    Icons.mic_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
              ),
            ],
          ),

          // Suggestion Dropdown Overlay (If any)
          ?suggestionsOverlay,

          // Recent Searches Chips
          if (showHistory && recentSearches.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: Row(
                  children: [
                    const Icon(
                      Icons.history_rounded,
                      color: Color(0xFF9F9B96),
                      size: 14,
                    ),
                    const SizedBox(width: 8),
                    ...recentSearches.map(
                      (term) => Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: ActionChip(
                          backgroundColor: const Color(0xFFF9F8F6),
                          label: Text(
                            term,
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              color: Color(0xFF5F5C58),
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                            side: const BorderSide(
                              color: Color(0xFFEAE8E3),
                            ),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                          onPressed: () {
                            HapticFeedback.lightImpact();
                            controller.text = term;
                            onSearchChanged(term);
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
