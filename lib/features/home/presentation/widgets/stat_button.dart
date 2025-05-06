import 'package:flutter/material.dart';

class StatButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const StatButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: Column(
        children: [
          Icon(icon, size: 18, color: Colors.white),
          SizedBox(height: 4),
          Text(label, style: TextStyle(fontSize: 14, color: Colors.white)),
        ],
      ),
    );
  }
}
