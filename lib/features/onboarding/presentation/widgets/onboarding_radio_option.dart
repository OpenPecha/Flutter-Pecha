import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/theme/app_colors.dart';

/// Reusable radio button option widget for single-select questions
class OnboardingRadioOption extends StatelessWidget {
  const OnboardingRadioOption({
    super.key,
    required this.id,
    required this.label,
    required this.selectedId,
    required this.onSelect,
  });

  final String id;
  final String label;
  final String? selectedId;
  final Function(String) onSelect;

  bool get isSelected => selectedId == id;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: InkWell(
        onTap: () => onSelect(id),
        borderRadius: BorderRadius.circular(8),
        child: Row(
          children: [
            _buildRadioButton(),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  letterSpacing: -0.306,
                  color: Color(0xFF171717),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRadioButton() {
    return Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: isSelected ? AppColors.primary : AppColors.greyMedium,
          width: 2,
        ),
        color: isSelected ? AppColors.primary : Colors.transparent,
      ),
      child:
          isSelected
              ? const Center(
                child: Icon(Icons.circle, size: 10, color: Colors.white),
              )
              : null,
    );
  }
}
