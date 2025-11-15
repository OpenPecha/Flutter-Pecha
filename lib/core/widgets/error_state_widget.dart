import 'package:flutter/material.dart';

/// A reusable error state widget for displaying user-friendly error messages.
///
/// This widget is designed to be used across all API calls and async operations
/// throughout the app. It provides a consistent error UI with:
/// - An error icon
/// - A user-friendly title
/// - A contextual error message based on the error type
/// - Optional retry button
///
/// Usage:
/// ```dart
/// AsyncValue.when(
///   data: (data) => YourDataWidget(data),
///   loading: () => CircularProgressIndicator(),
///   error: (error, stack) => ErrorStateWidget(error: error),
/// )
/// ```
class ErrorStateWidget extends StatelessWidget {
  /// The error object to display
  final Object error;

  /// Optional callback for retry action
  final VoidCallback? onRetry;

  /// Optional custom error message (overrides auto-generated message)
  final String? customMessage;

  /// Optional custom title (overrides default title)
  final String? customTitle;

  const ErrorStateWidget({
    super.key,
    required this.error,
    this.onRetry,
    this.customMessage,
    this.customTitle,
  });

  @override
  Widget build(BuildContext context) {
    // Use custom message or generate user-friendly message
    final errorMessage = customMessage ?? _getUserFriendlyMessage(error.toString());
    final title = customTitle ?? 'Oops! Something went wrong';

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Error icon
            Icon(
              Icons.error_outline,
              size: 64,
              color: Theme.of(context).colorScheme.error.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),

            // Error title
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),

            // User-friendly error message
            Text(
              errorMessage,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),

            // Retry button (if callback provided)
            if (onRetry != null) ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Try Again'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Converts technical error messages into user-friendly text
  String _getUserFriendlyMessage(String error) {
    // 404 Not Found errors
    if (error.contains('404')) {
      return 'The requested content is currently unavailable.\nPlease try again later or contact support.';
    }
    // 401 Unauthorized errors
    else if (error.contains('401')) {
      return 'You need to sign in to access this content.\nPlease log in and try again.';
    }
    // 403 Forbidden errors
    else if (error.contains('403')) {
      return 'You don\'t have permission to access this content.\nPlease contact support if you believe this is an error.';
    }
    // 500/502/503 Server errors
    else if (error.contains('500') || error.contains('502') || error.contains('503')) {
      return 'Our servers are experiencing issues.\nPlease try again in a few moments.';
    }
    // Network connectivity errors
    else if (error.contains('No internet') ||
        error.contains('SocketException') ||
        error.contains('Failed host lookup') ||
        error.contains('Network is unreachable')) {
      return 'Please check your internet connection\nand try again.';
    }
    // Timeout errors
    else if (error.contains('timeout') || error.contains('Timeout')) {
      return 'The request took too long.\nPlease check your connection and try again.';
    }
    // Generic fallback
    else {
      return 'Unable to load content at this time.\nPlease try again later.';
    }
  }
}
