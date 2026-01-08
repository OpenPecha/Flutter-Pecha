/// Validation result for message validation
class ValidationResult {
  final bool isValid;
  final String? errorMessage;
  final String? sanitizedContent;

  const ValidationResult._({
    required this.isValid,
    this.errorMessage,
    this.sanitizedContent,
  });

  factory ValidationResult.valid(String sanitizedContent) {
    return ValidationResult._(
      isValid: true,
      sanitizedContent: sanitizedContent,
    );
  }

  factory ValidationResult.invalid(String errorMessage) {
    return ValidationResult._(
      isValid: false,
      errorMessage: errorMessage,
    );
  }
}

/// Message validation utilities for AI chat
class MessageValidator {
  MessageValidator._(); // Private constructor to prevent instantiation

  /// Maximum allowed message length
  static const int maxLength = 4000;

  /// Minimum allowed message length (after trimming)
  static const int minLength = 1;

  /// Warning threshold for character count (90% of max)
  static const int warningThreshold = 3600;

  /// Validates a message and returns a ValidationResult
  ///
  /// Checks for:
  /// - Empty messages
  /// - Messages exceeding max length
  /// - Sanitizes content (removes control characters, normalizes whitespace)
  static ValidationResult validate(String message) {
    // Trim whitespace
    final trimmed = message.trim();

    if (trimmed.isEmpty) {
      return ValidationResult.invalid('Message cannot be empty');
    }

    if (trimmed.length > maxLength) {
      return ValidationResult.invalid(
        'Message exceeds maximum length of $maxLength characters',
      );
    }

    final sanitized = sanitize(trimmed);

    if (sanitized.isEmpty) {
      return ValidationResult.invalid('Message cannot be empty');
    }

    return ValidationResult.valid(sanitized);
  }

  /// Sanitizes message content
  ///
  /// - Removes control characters (except newlines and tabs)
  /// - Normalizes excessive whitespace
  /// - Trims leading/trailing whitespace
  static String sanitize(String input) {
    // Remove control characters except newlines (\n), carriage returns (\r), and tabs (\t)
    // Control characters are U+0000 to U+001F and U+007F to U+009F
    final withoutControlChars = input.replaceAll(
      RegExp(r'[\x00-\x08\x0B\x0C\x0E-\x1F\x7F-\x9F]'),
      '',
    );

    // Normalize multiple consecutive spaces (but preserve single spaces and newlines)
    final normalizedSpaces = withoutControlChars.replaceAll(
      RegExp(r' {2,}'),
      ' ',
    );

    // Normalize multiple consecutive newlines (max 2)
    final normalizedNewlines = normalizedSpaces.replaceAll(
      RegExp(r'\n{3,}'),
      '\n\n',
    );

    return normalizedNewlines.trim();
  }

  /// Returns the remaining characters allowed
  static int getRemainingCharacters(String message) {
    return maxLength - message.length;
  }

  /// Returns true if the message length is approaching the limit
  static bool isApproachingLimit(String message) {
    return message.length >= warningThreshold;
  }

  /// Returns true if the message exceeds the limit
  static bool exceedsLimit(String message) {
    return message.length > maxLength;
  }
}
