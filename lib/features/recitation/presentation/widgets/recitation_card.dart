import 'package:flutter/material.dart';
import 'package:flutter_pecha/features/recitation/data/models/recitation_model.dart';

class RecitationCard extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return Container(
      height: 75,
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
                _buildRecitationLogo(),
                const SizedBox(width: 12),
                Expanded(child: _buildRecitationTitle(context)),
                if (dragIndex != null) _buildDragHandle(context, dragIndex!),
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
      child: Padding(
        padding: const EdgeInsets.only(left: 8),
        child: Icon(
          Icons.drag_handle,
          color: Theme.of(context).iconTheme.color?.withValues(alpha: 0.5),
          size: 24,
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

  Widget _buildRecitationTitle(BuildContext context) {
    return Text(
      recitation.title,
      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }
}
