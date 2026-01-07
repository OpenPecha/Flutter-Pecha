import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/config/locale/locale_notifier.dart';
import 'package:flutter_pecha/core/l10n/generated/app_localizations.dart';
import 'package:flutter_pecha/core/widgets/error_state_widget.dart';
import 'package:flutter_pecha/features/app/presentation/pecha_bottom_nav_bar.dart';
import 'package:flutter_pecha/features/texts/constants/text_screen_constants.dart';
import 'package:flutter_pecha/features/texts/constants/text_routes.dart';
import 'package:flutter_pecha/features/texts/data/providers/paginated_texts_provider.dart';
import 'package:flutter_pecha/features/texts/models/collections/collections.dart';
import 'package:flutter_pecha/features/texts/models/text/texts.dart';
import 'package:flutter_pecha/features/texts/presentation/widgets/loading_state_widget.dart';
import 'package:flutter_pecha/features/texts/presentation/widgets/section_header.dart';
import 'package:flutter_pecha/features/texts/presentation/widgets/text_list_item.dart';
import 'package:flutter_pecha/features/texts/presentation/widgets/text_screen_app_bar.dart';
import 'package:flutter_pecha/shared/utils/helper_functions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class WorksScreen extends ConsumerStatefulWidget {
  const WorksScreen({super.key, required this.collection, this.colorIndex});
  final Collections collection;
  final int? colorIndex;

  @override
  ConsumerState<WorksScreen> createState() => _WorksScreenState();
}

class _WorksScreenState extends ConsumerState<WorksScreen> {
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent * 0.8) {
      ref
          .read(paginatedTextsProvider(widget.collection.id).notifier)
          .loadMoreTexts();
    }
  }

  @override
  Widget build(BuildContext context) {
    final paginatedState = ref.watch(
      paginatedTextsProvider(widget.collection.id),
    );
    final locale = ref.watch(localeProvider);
    final fontFamily = getFontFamily(locale.languageCode);
    final lineHeight = getLineHeight(locale.languageCode);
    final fontSize = locale.languageCode == 'bo' ? 24.0 : 22.0;

    // Get the border color from the color index
    final borderColor =
        widget.colorIndex != null
            ? TextScreenConstants.collectionCyclingColors[widget.colorIndex! %
                9]
            : null;

    return Scaffold(
      appBar: TextScreenAppBar(
        title: Text(
          paginatedState.collection?.title ?? widget.collection.title,
          style: TextStyle(
            fontFamily: fontFamily,
            height: lineHeight,
            fontSize: fontSize,
          ),
        ),
        onBackPressed: () => Navigator.pop(context),
        borderColor: borderColor,
      ),
      body: RefreshIndicator(
        onRefresh:
            () =>
                ref
                    .read(paginatedTextsProvider(widget.collection.id).notifier)
                    .refresh(),
        child: SingleChildScrollView(
          controller: _scrollController,
          child: Padding(
            padding: TextScreenConstants.screenLargePaddingValue,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (paginatedState.error != null &&
                    paginatedState.texts.isEmpty)
                  ErrorStateWidget(
                    error: paginatedState.error!,
                    customMessage:
                        'Unable to load texts.\nPlease try again later.',
                  )
                else if (paginatedState.texts.isEmpty &&
                    paginatedState.isLoading)
                  const LoadingStateWidget(topPadding: 40.0)
                else if (paginatedState.texts.isEmpty)
                  _buildEmptyState(context)
                else
                  Column(
                    children: [
                      _buildTextsList(context, paginatedState.texts),
                      if (paginatedState.isLoading)
                        const Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Center(child: CircularProgressIndicator()),
                        ),
                      if (paginatedState.error != null &&
                          paginatedState.texts.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Text(
                            'Error loading more: ${paginatedState.error}',
                            style: TextStyle(color: Colors.red),
                            textAlign: TextAlign.center,
                          ),
                        ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: const PechaBottomNavBar(),
    );
  }

  Widget _buildTextsList(BuildContext context, List<Texts> texts) {
    final rootTexts =
        texts.where((t) => t.type.toLowerCase() == 'root_text').toList();
    final commentaries =
        texts.where((t) => t.type.toLowerCase() == 'commentary').toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (rootTexts.isNotEmpty) ...[
          _RootTextsSection(texts: rootTexts, colorIndex: widget.colorIndex),
          const SizedBox(height: TextScreenConstants.contentVerticalSpacing),
        ],
        if (commentaries.isNotEmpty)
          _CommentariesSection(
            texts: commentaries,
            colorIndex: widget.colorIndex,
          ),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context) {
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
        ...texts.asMap().entries.map(
          (entry) => TextListItem(
            title: entry.value.title,
            language: entry.value.language ?? '',
            showDivider: entry.key != 0,
            onTap: () {
              context.push(
                TextRoutes.texts,
                extra: {'text': entry.value, 'colorIndex': colorIndex},
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
        ...texts.asMap().entries.map(
          (entry) => TextListItem(
            title: entry.value.title,
            language: entry.value.language ?? '',
            showDivider: entry.key != 0,
            onTap: () {
              context.push(
                TextRoutes.texts,
                extra: {'text': entry.value, 'colorIndex': colorIndex},
              );
            },
          ),
        ),
      ],
    );
  }
}
