import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_pecha/core/config/locale/locale_notifier.dart';
import 'package:flutter_pecha/features/recitation/data/models/recitation_model.dart';
import 'package:flutter_pecha/shared/utils/helper_functions.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class RecitationCard extends ConsumerWidget {
  final RecitationModel recitation;
  final VoidCallback onTap;
  final int? dragIndex;

  const RecitationCard({
    super.key,
    required this.recitation,
    required this.onTap,
    this.dragIndex,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      height: 80,
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        border: Border.all(color: const Color(0xFFE4E4E4), width: 1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                if (dragIndex != null) _buildDragHandle(context, dragIndex!),
                const SizedBox(width: 12),
                _buildRecitationLogo(),
                const SizedBox(width: 6),
                Expanded(child: _buildRecitationTitle(context, ref)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDragHandle(BuildContext context, int index) {
    return ReorderableDragStartListener(
      index: index,
      child: GestureDetector(
        onTapDown: (_) => HapticFeedback.heavyImpact(),
        child: Icon(
          Icons.drag_handle,
          size: 26,
          fontWeight: FontWeight.w600,
          color: Theme.of(context).iconTheme.color?.withValues(alpha: 0.5),
        ),
      ),
    );
  }

  Widget _buildRecitationLogo() {
    return SizedBox(
      width: 70,
      height: 70,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Outer circle
          Positioned(
            left: 0,
            top: 10,
            child: Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: const Color(0xFFAD2424).withValues(alpha: 0.9),
                shape: BoxShape.circle,
              ),
            ),
          ),
          // Middle circle
          Positioned(
            left: 7,
            top: 18,
            child: Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: const Color(0xFF871C1C).withValues(alpha: 0.9),
                shape: BoxShape.circle,
              ),
            ),
          ),
          // Inner circle
          Positioned(
            left: 12,
            top: 26,
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: const Color(0xFF611414).withValues(alpha: 0.9),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            left: 17,
            top: 30,
            child: Image.asset(
              'assets/images/favicon-pecha.png',
              width: 26,
              height: 26,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                return Icon(
                  Icons.menu_book,
                  size: 26,
                  color: Colors.white.withValues(alpha: 0.9),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecitationTitle(BuildContext context, WidgetRef ref) {
    final systemLanguage = ref.watch(localeProvider).languageCode;
    final recitationLanguage = recitation.language;
    final language =
        recitationLanguage != null && recitationLanguage.isNotEmpty
            ? recitationLanguage
            : systemLanguage;
    final lineHeight = getLineHeight(language);
    final fontSize = language == 'bo' ? 22.0 : 18.0;
    return Text(
      recitation.title,
      style: TextStyle(
        fontSize: fontSize,
        fontWeight: FontWeight.w500,
        fontFamily: getFontFamily(language),
        height: lineHeight,
      ),
      overflow: TextOverflow.ellipsis,
    );
  }
}
