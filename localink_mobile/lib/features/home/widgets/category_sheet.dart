import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../business/data/models/business_models.dart';

class CategorySheet extends StatefulWidget {
  final List<CategoryDto> categories;
  final int? selectedCategoryId;
  final ValueChanged<int?> onCategorySelected;
  final IconData Function(String) iconResolver;

  const CategorySheet({
    super.key,
    required this.categories,
    required this.selectedCategoryId,
    required this.onCategorySelected,
    required this.iconResolver,
  });

  @override
  State<CategorySheet> createState() => _CategorySheetState();
}

class _CategorySheetState extends State<CategorySheet> {
  final _searchCtrl = TextEditingController();
  List<CategoryDto> _filteredCategories = [];
  final List<String> _recentSearches = ['Temples', 'Pooja Items', 'Vegetarian'];

  @override
  void initState() {
    super.initState();
    _filteredCategories = widget.categories;
    _searchCtrl.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final query = _searchCtrl.text.toLowerCase().trim();
    setState(() {
      if (query.isEmpty) {
        _filteredCategories = widget.categories;
      } else {
        _filteredCategories = widget.categories
            .where((c) => c.categoryName.toLowerCase().contains(query))
            .toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final hasActiveFilter = widget.selectedCategoryId != null;
    final isSearching = _searchCtrl.text.isNotEmpty;

    // We only display the "All Categories" option when not searching, or if it matches "all"
    final showAllCategoriesCard = !isSearching;

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          // Drag handle bar
          const SizedBox(height: 12),
          Container(
            width: 38,
            height: 4.5,
            decoration: BoxDecoration(
              color: const Color(0xFFEAE8E3),
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          const SizedBox(height: 16),

          // Title
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Explore All Categories',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    color: Color(0xFF1A1918),
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Row(
                  children: [
                    if (hasActiveFilter) ...[
                      TextButton.icon(
                        style: TextButton.styleFrom(
                          foregroundColor: const Color(0xFFFF6600),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed: () {
                          HapticFeedback.mediumImpact();
                          widget.onCategorySelected(null);
                          Navigator.pop(context);
                        },
                        icon: const Icon(Icons.clear_all_rounded, size: 16),
                        label: const Text(
                          'Clear Filter',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close_rounded, color: Color(0xFF5F5C58)),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // Search text field
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              decoration: BoxDecoration(
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF1A1918).withValues(alpha: 0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: TextField(
                controller: _searchCtrl,
                decoration: InputDecoration(
                  hintText: 'Search categories or services...',
                  hintStyle: const TextStyle(color: Color(0xFF9F9B96), fontSize: 13),
                  prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFFFF6600), size: 20),
                  suffixIcon: _searchCtrl.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded, color: Color(0xFF5F5C58), size: 18),
                          onPressed: () => _searchCtrl.clear(),
                        )
                      : null,
                  fillColor: const Color(0xFFF9F8F6),
                  filled: true,
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: Color(0xFFEAE8E3)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: Color(0xFFEAE8E3)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: Color(0xFFFF6600), width: 1.5),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // List / Grid Body
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Suggestions / Recents when search query is empty
                  if (!isSearching) ...[
                    const Text(
                      'Recent Searches',
                      style: TextStyle(
                        color: Color(0xFF5F5C58),
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: _recentSearches.map((tag) {
                        return GestureDetector(
                          onTap: () {
                            HapticFeedback.lightImpact();
                            _searchCtrl.text = tag;
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF9F8F6),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: const Color(0xFFEAE8E3)),
                            ),
                            child: Text(
                              tag,
                              style: const TextStyle(color: Color(0xFF5F5C58), fontSize: 12),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // Category title
                  Text(
                    isSearching ? 'Search Results' : 'All Categories',
                    style: const TextStyle(
                      color: Color(0xFF1A1918),
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 12),

                  if (_filteredCategories.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 40),
                      child: Center(
                        child: Column(
                          children: [
                            Icon(Icons.search_off_rounded, color: const Color(0xFFFF6600).withValues(alpha: 0.4), size: 48),
                            const SizedBox(height: 12),
                            const Text(
                              'No matching categories found',
                              style: TextStyle(color: Color(0xFF9F9B96), fontSize: 13, fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 1.45,
                      ),
                      itemCount: showAllCategoriesCard ? _filteredCategories.length + 1 : _filteredCategories.length,
                      itemBuilder: (context, index) {
                        final isAllCard = showAllCategoriesCard && index == 0;
                        final cat = isAllCard ? null : _filteredCategories[showAllCategoriesCard ? index - 1 : index];
                        
                        final label = isAllCard ? 'All Categories' : cat!.categoryName;
                        final icon = isAllCard ? Icons.apps_rounded : widget.iconResolver(label);
                        final isSelected = isAllCard
                            ? widget.selectedCategoryId == null
                            : widget.selectedCategoryId == cat!.categoryId;

                        return GestureDetector(
                          onTap: () {
                            HapticFeedback.mediumImpact();
                            widget.onCategorySelected(isAllCard ? null : cat!.categoryId);
                            Navigator.pop(context);
                          },
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: isSelected ? const Color(0xFFFFF0E6) : Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isSelected ? const Color(0xFFFF6600) : const Color(0xFFEAE8E3),
                                width: isSelected ? 2 : 1,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF1A1918).withValues(alpha: 0.02),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Stack(
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFFF6600).withValues(alpha: 0.08),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        icon,
                                        color: const Color(0xFFFF6600),
                                        size: 20,
                                      ),
                                    ),
                                    Text(
                                      label,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontFamily: 'Inter',
                                        color: const Color(0xFF1A1918),
                                        fontSize: 13,
                                        fontWeight: isSelected ? FontWeight.w900 : FontWeight.w800,
                                      ),
                                    ),
                                  ],
                                ),
                                if (isSelected)
                                  const Positioned(
                                    top: 0,
                                    right: 0,
                                    child: Icon(
                                      Icons.check_circle_rounded,
                                      color: Color(0xFFFF6600),
                                      size: 18,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
