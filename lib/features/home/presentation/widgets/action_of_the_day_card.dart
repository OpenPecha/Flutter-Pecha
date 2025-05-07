import 'package:flutter/material.dart';

class ActionOfTheDayCard extends StatelessWidget {
  const ActionOfTheDayCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.iconWidget,
    this.isSpace = false,
    required this.onTap,
  });
  final String title;
  final String subtitle;
  final Widget iconWidget;
  final bool isSpace;
  final Function() onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.black12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title at the top left
          Text(
            title,
            style: TextStyle(
              color: Colors.black87,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          if (isSpace) const SizedBox(height: 16),
          // Centered icon, subtitle, and button
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                iconWidget,
                if (isSpace) const SizedBox(height: 16),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFFA63D3D),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  onPressed: onTap,
                  child: Text(
                    'Start now',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
