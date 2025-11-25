import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/l10n/generated/app_localizations.dart';
import 'package:flutter_pecha/features/home/presentation/home_screen_constants.dart';
import 'package:flutter_pecha/features/home/presentation/utils.dart';
import 'package:flutter_pecha/features/home/presentation/widgets/action_of_the_day_card.dart';
import 'package:flutter_pecha/features/home/presentation/widgets/verse_card.dart';
import 'package:flutter_pecha/features/plans/models/response/featured_day_response.dart';
import 'package:flutter_pecha/features/plans/models/user/user_subtasks_dto.dart';
import 'package:flutter_pecha/features/story_view/utils/story_dialog_helper.dart';

class FeaturedContentFactory {
  FeaturedContentFactory._();

  static Widget createCard({
    required BuildContext context,
    required int index,
    required FeaturedDayTask planItem,
    required List<FeaturedDayTask> allPlanItems,
    required AppLocalizations localizations,
  }) {
    if (planItem.subtasks.isEmpty) {
      return const SizedBox.shrink();
    }

    final nextPlanItem =
        index < allPlanItems.length - 1 ? allPlanItems[index + 1] : null;

    switch (index) {
      case HomeScreenConstants.verseCardIndex:
        return _buildVerseCard(
          planItem: planItem,
          nextPlanItem: nextPlanItem,
          allPlanItems: allPlanItems,
          index: index,
          localizations: localizations,
        );

      case HomeScreenConstants.scriptureCardIndex:
        return _buildScriptureCard(
          context: context,
          planItem: planItem,
          nextPlanItem: nextPlanItem,
          localizations: localizations,
        );

      case HomeScreenConstants.meditationCardIndex:
        return _buildMeditationCard(
          context: context,
          planItem: planItem,
          localizations: localizations,
        );

      default:
        return const SizedBox.shrink();
    }
  }

  static Widget _buildVerseCard({
    required FeaturedDayTask planItem,
    required FeaturedDayTask? nextPlanItem,
    required List<FeaturedDayTask> allPlanItems,
    required int index,
    required AppLocalizations localizations,
  }) {
    return Column(
      children: [
        VerseCard(
          verseText: planItem.subtasks[0].content,
          title: planItem.title,
          subtask: _createSubtaskDto(planItem.subtasks[0]),
          nextCard:
              nextPlanItem != null
                  ? _buildNextCardData(
                    planItem: nextPlanItem,
                    heading: localizations.home_scripture,
                    subtitle: HomeScreenConstants.defaultDuration,
                    nextNextCard:
                        index + 2 < allPlanItems.length
                            ? _buildNextCardData(
                              planItem: allPlanItems[index + 2],
                              heading: localizations.home_meditation,
                              subtitle: HomeScreenConstants.defaultDuration,
                            )
                            : null,
                  )
                  : null,
        ),
        const SizedBox(height: HomeScreenConstants.cardSpacing),
      ],
    );
  }

  static Widget _buildScriptureCard({
    required BuildContext context,
    required FeaturedDayTask planItem,
    required FeaturedDayTask? nextPlanItem,
    required AppLocalizations localizations,
  }) {
    return Column(
      children: [
        ActionOfTheDayCard(
          title: planItem.title,
          duration: HomeScreenConstants.defaultDuration,
          iconWidget: getVideoThumbnail(planItem.subtasks[0].content),
          onTap:
              () => showStoryDialog(
                context: context,
                subtasks: [_createSubtaskDto(planItem.subtasks[0])],
                nextCard:
                    nextPlanItem != null
                        ? _buildNextCardData(
                          planItem: nextPlanItem,
                          heading: localizations.home_meditation,
                          subtitle: HomeScreenConstants.defaultDuration,
                        )
                        : null,
              ),
        ),
        const SizedBox(height: HomeScreenConstants.cardSpacing),
      ],
    );
  }

  static Widget _buildMeditationCard({
    required BuildContext context,
    required FeaturedDayTask planItem,
    required AppLocalizations localizations,
  }) {
    return Column(
      children: [
        ActionOfTheDayCard(
          title: planItem.title,
          duration: HomeScreenConstants.defaultDuration,
          iconWidget: getVideoThumbnail(planItem.subtasks[0].content),
          onTap:
              () => showStoryDialog(
                context: context,
                subtasks: [_createSubtaskDto(planItem.subtasks[0])],
              ),
        ),
        const SizedBox(height: HomeScreenConstants.cardSpacing),
      ],
    );
  }

  /// Helper method to build next card data structure
  static Map<String, dynamic> _buildNextCardData({
    required FeaturedDayTask planItem,
    required String heading,
    required String subtitle,
    Map<String, dynamic>? nextNextCard,
  }) {
    if (planItem.subtasks.isEmpty) {
      throw StateError('PlanItem must have at least one subtask');
    }

    final cardData = {
      'heading': heading,
      'title': planItem.title,
      'subtitle': subtitle,
      'iconWidget': getVideoThumbnail(planItem.subtasks[0].content),
      'subtasks': [_createSubtaskDto(planItem.subtasks[0])],
    };

    if (nextNextCard != null) {
      cardData['nextCard'] = nextNextCard;
    }

    return cardData;
  }

  /// Helper method to create UserSubtasksDto from subtask model
  static UserSubtasksDto _createSubtaskDto(FeaturedDaySubtask subtask) {
    return UserSubtasksDto(
      id: subtask.id,
      contentType: subtask.contentType,
      content: subtask.content,
      displayOrder: subtask.displayOrder,
      isCompleted: false,
    );
  }
}
