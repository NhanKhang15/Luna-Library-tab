import 'package:flutter/material.dart';

/// Category item model
class CategoryItem {
  final String id;
  final String label;
  final IconData icon;

  const CategoryItem({
    required this.id,
    required this.label,
    required this.icon,
  });
}

/// Category chips matching Figma exactly:
/// - Unselected: FLAT (no background, no border, grey text)
/// - Selected: white pill + very soft shadow + pinkish text/icon
class CategoryChips extends StatefulWidget {
  final String? selectedCategory;
  final ValueChanged<String>? onSelectionChanged;

  const CategoryChips({
    super.key,
    this.selectedCategory,
    this.onSelectionChanged,
  });

  @override
  State<CategoryChips> createState() => _CategoryChipsState();
}

class _CategoryChipsState extends State<CategoryChips> {
  late String _selectedCategory;

  // Categories matching tag names in dbo.Tags table
  static const List<CategoryItem> _categories = [
    CategoryItem(
      id: 'Tâm lý',
      label: 'Tâm lý',
      icon: Icons.cloud_outlined, // Cloud/brain icon
    ),
    CategoryItem(
      id: 'Sinh lý',
      label: 'Sinh lý',
      icon: Icons.favorite_border, // Heart icon for physiology
    ),
    CategoryItem(
      id: 'Pháp lý',
      label: 'Pháp lý',
      icon: Icons.balance_outlined, // Scales icon
    ),
  ];

  @override
  void initState() {
    super.initState();
    _selectedCategory = widget.selectedCategory ?? 'Sinh lý';
  }

  void _selectCategory(String id) {
    setState(() => _selectedCategory = id);
    widget.onSelectionChanged?.call(id);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: _categories.map((category) {
          final isSelected = _selectedCategory == category.id;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: _CategoryChip(
              category: category,
              isSelected: isSelected,
              onTap: () => _selectCategory(category.id),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final CategoryItem category;
  final bool isSelected;
  final VoidCallback onTap;

  // Figma colors
  static const Color _selectedColor = Color(0xFFCB62A2); // Pink from Figma
  static const Color _unselectedColor = Color(0xFF888888); // Grey for unselected

  const _CategoryChip({
    required this.category,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          // Selected: white background, Unselected: completely transparent
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(20), // More rounded like Figma
          // Selected: very soft subtle shadow
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                    spreadRadius: 0,
                  ),
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                    spreadRadius: 0,
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              category.icon,
              size: 18,
              color: isSelected ? _selectedColor : _unselectedColor,
            ),
            const SizedBox(width: 6),
            Text(
              category.label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? _selectedColor : _unselectedColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
