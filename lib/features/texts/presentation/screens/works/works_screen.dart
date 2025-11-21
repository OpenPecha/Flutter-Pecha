import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/config/locale/locale_notifier.dart';
import 'package:flutter_pecha/core/l10n/generated/app_localizations.dart';
import 'package:flutter_pecha/core/widgets/error_state_widget.dart';
import 'package:flutter_pecha/features/app/presentation/pecha_bottom_nav_bar.dart';
import 'package:flutter_pecha/features/texts/constants/text_screen_constants.dart';
import 'package:flutter_pecha/features/texts/constants/text_routes.dart';
import 'package:flutter_pecha/features/texts/models/collections/collections.dart';
import 'package:flutter_pecha/features/texts/data/providers/apis/texts_provider.dart';
import 'package:flutter_pecha/features/texts/models/text/detail_response.dart';
import 'package:flutter_pecha/features/texts/models/text/texts.dart';
import 'package:flutter_pecha/features/texts/presentation/widgets/loading_state_widget.dart';
import 'package:flutter_pecha/features/texts/presentation/widgets/section_header.dart';
import 'package:flutter_pecha/features/texts/presentation/widgets/text_list_item.dart';
import 'package:flutter_pecha/features/texts/presentation/widgets/text_screen_app_bar.dart';
import 'package:flutter_pecha/shared/utils/helper_functions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class WorksScreen extends ConsumerWidget {
  const WorksScreen({
    super.key,
    required this.collection,
    this.colorIndex,
  });
  final Collections collection;
  final int? colorIndex;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<TextDetailResponse?> textDetailResponse = ref.watch(
      textsFutureProvider(collection.id),
    );
    final locale = ref.watch(localeProvider);
    final fontFamily = getFontFamily(locale.languageCode);
    final lineHeight = getLineHeight(locale.languageCode);
    final fontSize = locale.languageCode == 'bo' ? 28.0 : 24.0;

    // Get the border color from the color index
    final borderColor = colorIndex != null
        ? TextScreenConstants.collectionCyclingColors[colorIndex! % 9]
        : null;

    return Scaffold(
      appBar: TextScreenAppBar(
        onBackPressed: () => Navigator.pop(context),
        borderColor: borderColor,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: TextScreenConstants.screenLargePaddingValue,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                textDetailResponse.value?.collections.title ?? '',
                style: TextStyle(
                  fontFamily: fontFamily,
                  height: lineHeight,
                  fontSize: fontSize,
                ),
              ),
              const SizedBox(height: TextScreenConstants.largeVerticalSpacing),
              textDetailResponse.when(
                data: (response) {
                  if (response == null) {
                    return const Center(child: Text('No texts found'));
                  }
                  return _buildTextsList(context, ref, response.texts);
                },
                loading: () => const LoadingStateWidget(topPadding: 40.0),
                error:
                    (e, st) => ErrorStateWidget(
                      error: e,
                      customMessage:
                          'Unable to load texts.\nPlease try again later.',
                    ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const PechaBottomNavBar(),
    );
  }

  Widget _buildTextsList(
    BuildContext context,
    WidgetRef ref,
    List<Texts> texts,
  ) {
    if (texts.isEmpty) {
      return _buildEmptyState(context, ref);
    }

    final rootTexts =
        texts.where((t) => t.type.toLowerCase() == 'root_text').toList();
    final commentaries =
        texts.where((t) => t.type.toLowerCase() == 'commentary').toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (rootTexts.isNotEmpty) ...[
          _RootTextsSection(texts: rootTexts, colorIndex: colorIndex),
          const SizedBox(height: TextScreenConstants.contentVerticalSpacing),
        ],
        if (commentaries.isNotEmpty)
          _CommentariesSection(texts: commentaries, colorIndex: colorIndex),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context, WidgetRef ref) {
    final localizations = AppLocalizations.of(context)!;
    final currentLocale = ref.watch(localeProvider);

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 60.0, horizontal: 24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              localizations.text_noContent,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: TextScreenConstants.bodyFontSize,
                fontWeight: FontWeight.w500,
                color: Colors.grey[TextScreenConstants.greyShade700],
              ),
            ),
            const SizedBox(height: 18),
            if (currentLocale.languageCode != 'bo')
              ElevatedButton(
                onPressed: () {
                  ref
                      .read(localeProvider.notifier)
                      .setLocale(const Locale('bo'));
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(
                      TextScreenConstants.buttonBorderRadius,
                    ),
                  ),
                ),
                child: Text(
                  localizations.text_switchToTibetan,
                  style: const TextStyle(
                    fontSize: TextScreenConstants.bodyFontSize,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Root texts section widget
class _RootTextsSection extends StatelessWidget {
  final List<Texts> texts;
  final int? colorIndex;

  const _RootTextsSection({required this.texts, this.colorIndex});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...texts.map(
          (text) => TextListItem(
            title: text.title,
            language: text.language ?? '',
            onTap: () {
              context.push(
                TextRoutes.texts,
                extra: {
                  'text': text,
                  'colorIndex': colorIndex,
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

/// Commentaries section widget
class _CommentariesSection extends StatelessWidget {
  final List<Texts> texts;
  final int? colorIndex;

  const _CommentariesSection({required this.texts, this.colorIndex});

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(title: localizations.text_detail_commentaryText),
        ...texts.map(
          (text) => TextListItem(
            title: text.title,
            language: text.language ?? '',
            onTap: () {
              context.push(
                TextRoutes.texts,
                extra: {
                  'text': text,
                  'colorIndex': colorIndex,
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
