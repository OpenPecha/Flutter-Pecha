import 'package:flutter/material.dart';
import 'package:flutter_pecha/features/recitation/data/models/recitation_model.dart';

class RecitationCard extends StatelessWidget {
  final RecitationModel recitation;
  final VoidCallback onTap;
  final VoidCallback? onMoreTap;

  const RecitationCard({
    super.key,
    required this.recitation,
    required this.onTap,
    this.onMoreTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 75,
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        border: Border.all(
          color: const Color(0xFFE4E4E4),
          width: 1,
        ),
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
                Expanded(
                  child: _buildRecitationTitle(context),
                ),
                if (onMoreTap != null) _buildMoreButton(context),
              ],
            ),
          ),
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
            left: 6,
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
          // Logo/Icon
          Positioned(
            left: 18,
            top: 44,
            child: Image.asset(
              'assets/images/pecha_logo.png',
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
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        height: 1.4,
      ),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildMoreButton(BuildContext context) {
    return IconButton(
      onPressed: onMoreTap,
      icon: const Icon(
        Icons.more_vert,
        size: 20,
      ),
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(
        minWidth: 32,
        minHeight: 32,
      ),
    );
  }
}



