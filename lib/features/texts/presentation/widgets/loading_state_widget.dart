import 'package:flutter/material.dart';

/// Consistent loading indicator widget
/// Used across all text screens for uniform loading states
class LoadingStateWidget extends StatelessWidget {
  final String? message;
  final double? topPadding;

  const LoadingStateWidget({super.key, this.message, this.topPadding});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.only(top: topPadding ?? 40.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            if (message != null) ...[
              const SizedBox(height: 16),
              Text(message!, style: const TextStyle(fontSize: 16)),
            ],
          ],
        ),
      ),
    );
  }
}
