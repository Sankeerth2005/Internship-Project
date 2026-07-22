import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../business/providers/business_provider.dart';
import '../../business/data/models/business_models.dart';

class HomeCategoryChips extends ConsumerWidget {
  final List<CategoryDto> categories;
  final int? selectedCategoryId;
  final int? selectedSubcategoryId;
  final ValueChanged<int?> onCategoryChanged;
  final ValueChanged<int?> onSubcategoryChanged;
  final IconData Function(String) categoryIconResolver;
  final IconData Function(String) subcategoryIconResolver;

  const HomeCategoryChips({
    super.key,
    required this.categories,
    required this.selectedCategoryId,
    required this.selectedSubcategoryId,
    required this.onCategoryChanged,
    required this.onSubcategoryChanged,
    required this.categoryIconResolver,
    required this.subcategoryIconResolver,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Categories Heading
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Text(
            'Categories',
            style: TextStyle(
              fontFamily: 'Inter',
              color: Color(0xFF1A1918),
              fontSize: 16,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.2,
            ),
          ),
        ),

        // Horizontal Categories List
        SizedBox(
          height: 98,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 14),
            itemCount: categories.length + 1,
            itemBuilder: (context, index) {
              final isAll = index == 0;
              final isSelected = isAll
                  ? selectedCategoryId == null
                  : selectedCategoryId == categories[index - 1].categoryId;
              final label = isAll ? 'All' : categories[index - 1].categoryName;
              final catIcon = isAll ? Icons.apps_rounded : categoryIconResolver(label);

              return GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  if (isAll) {
                    onCategoryChanged(null);
                  } else {
                    onCategoryChanged(categories[index - 1].categoryId);
                  }
                },
                child: AnimatedScale(
                  scale: isSelected ? 1.05 : 1.0,
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOutCubic,
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isSelected ? const Color(0xFFFF6600) : const Color(0xFFF9F8F6),
                            border: Border.all(
                              color: isSelected ? const Color(0xFFFF6600) : const Color(0xFFEAE8E3),
                              width: 1.5,
                            ),
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color: const Color(0xFFFF6600).withValues(alpha: 0.25),
                                      blurRadius: 8,
                                      offset: const Offset(0, 3),
                                    )
                                  ]
                                : [],
                          ),
                          child: Icon(
                            catIcon,
                            color: isSelected ? Colors.white : const Color(0xFF5F5C58),
                            size: 22,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          label,
                          style: TextStyle(
                            fontFamily: 'Inter',
                            color: isSelected ? const Color(0xFFFF6600) : const Color(0xFF5F5C58),
                            fontSize: 11,
                            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),

        // Subcategories Chips Bar (shown dynamically when category is selected)
        if (selectedCategoryId != null) ...[
          const SizedBox(height: 4),
          _buildSubcategoriesSection(ref),
        ],
      ],
    );
  }

  Widget _buildSubcategoriesSection(WidgetRef ref) {
    final subcategoriesAsync = ref.watch(subcategoriesProvider(selectedCategoryId!));

    return subcategoriesAsync.when(
      data: (subcategories) {
        if (subcategories.isEmpty) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.only(top: 4, bottom: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                child: Text(
                  'Sub-Categories',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    color: Color(0xFFFF6600),
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.1,
                  ),
                ),
              ),
              SizedBox(
                height: 38,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: subcategories.length + 1,
                  itemBuilder: (context, index) {
                    final isAll = index == 0;
                    final isSelected = isAll
                        ? selectedSubcategoryId == null
                        : selectedSubcategoryId == subcategories[index - 1].subcategoryId;
                    final label = isAll ? 'All Sub-categories' : subcategories[index - 1].subcategoryName;
                    final subIcon = isAll ? Icons.tune_rounded : subcategoryIconResolver(label);

                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        selected: isSelected,
                        showCheckmark: false,
                        avatar: Icon(
                          subIcon,
                          size: 13,
                          color: isSelected ? Colors.white : const Color(0xFFFF6600),
                        ),
                        label: Text(
                          label,
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 11.5,
                            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                            color: isSelected ? Colors.white : const Color(0xFF5F5C58),
                          ),
                        ),
                        backgroundColor: const Color(0xFFF9F8F6),
                        selectedColor: const Color(0xFFFF6600),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                          side: BorderSide(
                            color: isSelected ? const Color(0xFFFF6600) : const Color(0xFFEAE8E3),
                          ),
                        ),
                        onSelected: (_) {
                          HapticFeedback.lightImpact();
                          if (isAll) {
                            onSubcategoryChanged(null);
                          } else {
                            onSubcategoryChanged(subcategories[index - 1].subcategoryId);
                          }
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (err, stack) => const SizedBox.shrink(),
    );
  }
}
