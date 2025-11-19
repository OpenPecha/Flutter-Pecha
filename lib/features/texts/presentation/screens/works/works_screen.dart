import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/config/locale/locale_notifier.dart';
import 'package:flutter_pecha/core/l10n/generated/app_localizations.dart';
import 'package:flutter_pecha/core/widgets/error_state_widget.dart';
import 'package:flutter_pecha/features/app/presentation/pecha_bottom_nav_bar.dart';
import 'package:flutter_pecha/features/texts/constants/text_screen_constants.dart';
import 'package:flutter_pecha/features/texts/constants/text_routes.dart';
import 'package:flutter_pecha/features/texts/models/collections/collections.dart';
import 'package:flutter_pecha/features/texts/data/providers/apis/texts_provider.dart';
import 'package:flutter_pecha/features/texts/models/text/texts.dart';
import 'package:flutter_pecha/features/texts/presentation/widgets/loading_state_widget.dart';
import 'package:flutter_pecha/features/texts/presentation/widgets/section_header.dart';
import 'package:flutter_pecha/features/texts/presentation/widgets/text_list_item.dart';
import 'package:flutter_pecha/features/texts/presentation/widgets/text_screen_app_bar.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Screen displaying works (texts) within a collection
/// Separates root texts and commentaries
class WorksScreen extends ConsumerWidget {
  const WorksScreen({super.key, required this.collection});
  final Collections collection;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textDetailResponse = ref.watch(textsFutureProvider(collection.id));

    return Scaffold(
      appBar: TextScreenAppBar(onBackPressed: () => Navigator.pop(context)),
      body: SingleChildScrollView(
        child: Padding(
          padding: TextScreenConstants.screenLargePaddingValue,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                textDetailResponse.value?.collections.title ?? '',
                style: const TextStyle(
                  fontSize: TextScreenConstants.titleFontSize,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: TextScreenConstants.largeVerticalSpacing),
              textDetailResponse.when(
                data:
                    (response) => _buildTextsList(context, ref, response.texts),
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
          _RootTextsSection(texts: rootTexts),
          const SizedBox(height: TextScreenConstants.contentVerticalSpacing),
        ],
        if (commentaries.isNotEmpty) _CommentariesSection(texts: commentaries),
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

  const _RootTextsSection({required this.texts});

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(title: localizations.text_detail_rootText),
        ...texts.map(
          (text) => TextListItem(
            title: text.title,
            language: text.language,
            onTap: () {
              context.push(TextRoutes.texts, extra: text);
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

  const _CommentariesSection({required this.texts});

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
            language: text.language,
            onTap: () {
              context.push(TextRoutes.texts, extra: text);
            },
          ),
        ),
      ],
    );
  }
}
