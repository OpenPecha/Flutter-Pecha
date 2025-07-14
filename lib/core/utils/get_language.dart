import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/l10n/generated/app_localizations.dart';

String getLanguageLabel(String code, BuildContext context) {
  final localizations = AppLocalizations.of(context)!;
  switch (code.toLowerCase()) {
    case 'bo':
    case 'tibetan':
      return localizations.tibetan;
    case 'sa':
    case 'sanskrit':
      return localizations.sanskrit;
    case 'en':
    case 'english':
      return localizations.english;
    default:
      return localizations.english;
  }
}
