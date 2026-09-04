import 'package:flutter_pecha/core/l10n/generated/app_localizations.dart';
import 'package:flutter_pecha/shared/domain/validators/collection_name_validator.dart';

/// Translated message for a [CollectionNameValidationError].
///
/// The `person_name_*` strings are worded generically ("Must be at least 1
/// character", "Must be 50 characters or less") and exist in every locale, so
/// they are reused rather than adding untranslated collection-specific keys.
String collectionNameErrorMessage(
  AppLocalizations l10n,
  CollectionNameValidationError error,
) => switch (error) {
  CollectionNameValidationError.empty => l10n.person_name_min_length,
  CollectionNameValidationError.tooLong => l10n.person_name_max_length,
};
