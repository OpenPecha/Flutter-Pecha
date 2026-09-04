/// Validation for user-created recitation collection names.
///
/// Names are free text — digits and punctuation are fine, unlike person
/// names — so only emptiness and length are checked. The API puts no bound on
/// `name`; [maxLength] mirrors `PersonNameValidator.maxLength` so the existing
/// translated length message can be reused.
class CollectionNameValidator {
  CollectionNameValidator._();

  static const int maxLength = 50;

  /// Trims and collapses runs of whitespace to a single space.
  ///
  /// Returns `null` when nothing is left.
  static String? sanitize(String input) {
    final trimmed = input.trim();
    if (trimmed.isEmpty) return null;
    return trimmed.replaceAll(RegExp(r'\s+'), ' ');
  }

  /// Returns the first failing rule, or `null` when [input] is acceptable.
  static CollectionNameValidationError? validate(String input) {
    final sanitized = sanitize(input);
    if (sanitized == null) return CollectionNameValidationError.empty;
    if (sanitized.length > maxLength) {
      return CollectionNameValidationError.tooLong;
    }
    return null;
  }
}

enum CollectionNameValidationError { empty, tooLong }
