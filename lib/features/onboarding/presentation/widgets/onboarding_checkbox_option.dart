import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/theme/app_colors.dart';

/// Reusable checkbox option widget for multi-select questions
class OnboardingCheckboxOption extends StatelessWidget {
  const OnboardingCheckboxOption({
    super.key,
    required this.id,
    required this.label,
    required this.isSelected,
    required this.isEnabled,
    required this.onTap,
  });

  final String id;
  final String label;
  final bool isSelected;
  final bool isEnabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: InkWell(
        onTap: isEnabled ? onTap : null,
        borderRadius: BorderRadius.circular(8),
        child: Row(
          children: [
            _buildCheckbox(),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  letterSpacing: -0.306,
                  color:
                      isEnabled
                          ? const Color(0xFF171717)
                          : AppColors.greyMedium,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCheckbox() {
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
                child: Icon(Icons.check, size: 14, color: Colors.white),
              )
              : null,
    );
  }
}
