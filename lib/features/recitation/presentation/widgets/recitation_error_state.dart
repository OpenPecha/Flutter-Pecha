import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/widgets/error_state_widget.dart';

/// A widget that displays an error state for recitation loading failures.
///
/// This is a wrapper around the generic ErrorStateWidget with recitation-specific messaging.
class RecitationErrorState extends StatelessWidget {
  /// The error object to display
  final Object error;

  /// Optional callback for retry action
  final VoidCallback? onRetry;

  const RecitationErrorState({
    super.key,
    required this.error,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return ErrorStateWidget(
      error: error,
      onRetry: onRetry,
      customMessage: _getRecitationSpecificMessage(error.toString()),
    );
  }

  /// Returns recitation-specific error messages for known error types
  String? _getRecitationSpecificMessage(String error) {
    if (error.contains('404')) {
      return 'This recitation content is currently unavailable.\nPlease try again later or contact support.';
    } else if (error.contains('401')) {
      return 'Please sign in to access this recitation.';
    }
    // Return null to use the generic error messages from ErrorStateWidget
    return null;
  }
}
