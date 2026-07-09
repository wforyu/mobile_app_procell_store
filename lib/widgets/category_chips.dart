import 'package:flutter/material.dart';
import '../helpers/theme.dart';

class CategoryChips extends StatelessWidget {
  final List<Map<String, dynamic>> categories;
  final String? selectedSlug;
  final void Function(String? slug) onSelected;

  const CategoryChips({
    super.key,
    required this.categories,
    required this.selectedSlug,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: categories.length + 1,
        itemBuilder: (_, i) {
          final isSemua = i == 0;
          final selected = isSemua ? selectedSlug == null : selectedSlug == categories[i - 1]['slug'];
          final label = isSemua ? 'Semua' : (categories[i - 1]['name'] as String? ?? '');
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(label, style: TextStyle(fontSize: 13, color: selected ? Colors.white : AppColors.textSecondary)),
              selected: selected,
              onSelected: (_) => onSelected(isSemua ? null : categories[i - 1]['slug'] as String?),
              selectedColor: AppColors.primary,
              backgroundColor: Colors.white,
              side: BorderSide(color: selected ? AppColors.primary : AppColors.border),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              padding: const EdgeInsets.symmetric(horizontal: 8),
              visualDensity: VisualDensity.compact,
            ),
          );
        },
      ),
    );
  }
}
