import 'package:flutter/material.dart';
import 'package:flutter_pecha/features/reader/data/models/navigation_context.dart';
import 'package:flutter_pecha/features/recitation/data/models/recitation_model.dart';
import 'package:go_router/go_router.dart';

/// Opens a chant/recitation in the shared reader with practice-context actions
/// (e.g. "Add to my practices" in the more menu).
///
/// [listLanguage] is the language currently selected on the chant screen.
/// When provided it is used so the reader matches the list picker. Otherwise
/// [RecitationModel.language] is used.
void openRecitationReader(
  BuildContext context,
  RecitationModel recitation, {
  String? listLanguage,
}) {
  final fromList = listLanguage?.trim();
  final fromModel = recitation.language?.trim();
  final language =
      (fromList != null && fromList.isNotEmpty)
          ? fromList
          : (fromModel != null && fromModel.isNotEmpty ? fromModel : null);

  context.push(
    '/reader/${recitation.textId}',
    extra: NavigationContext(
      source: NavigationSource.recitationList,
      language: language,
    ),
  );
}
