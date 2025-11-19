import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/l10n/generated/app_localizations.dart';
import 'package:flutter_pecha/core/widgets/error_state_widget.dart';
import 'package:flutter_pecha/features/app/presentation/pecha_bottom_nav_bar.dart';
import 'package:flutter_pecha/features/texts/constants/text_screen_constants.dart';
import 'package:flutter_pecha/features/texts/constants/text_routes.dart';
import 'package:flutter_pecha/features/texts/data/providers/apis/texts_provider.dart';
import 'package:flutter_pecha/features/texts/models/text/texts.dart';
import 'package:flutter_pecha/features/texts/models/text/toc_response.dart';
import 'package:flutter_pecha/features/texts/models/text/version_response.dart';
import 'package:flutter_pecha/features/texts/models/version.dart';
import 'package:flutter_pecha/features/texts/presentation/widgets/continue_reading_button.dart';
import 'package:flutter_pecha/features/texts/presentation/widgets/loading_state_widget.dart';
import 'package:flutter_pecha/features/texts/presentation/widgets/table_of_contens.dart';
import 'package:flutter_pecha/features/texts/presentation/widgets/text_screen_app_bar.dart';
import 'package:flutter_pecha/features/texts/presentation/widgets/version_list_item.dart';
import 'package:flutter_pecha/features/texts/utils/language_helper.dart';
import 'package:flutter_pecha/shared/utils/helper_functions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Screen displaying text details with table of contents and versions
class TextsScreen extends ConsumerWidget {
  const TextsScreen({super.key, required this.text});
  final Texts text;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final localizations = AppLocalizations.of(context)!;
    final textContentResponse = ref.watch(textContentFutureProvider(text.id));
    final textVersionResponse = ref.watch(textVersionFutureProvider(text.id));

    // Determine if we should show the contents tab
    final showContentsTab = textContentResponse.maybeWhen(
      data:
          (contentResponse) =>
              contentResponse.contents.isNotEmpty &&
              contentResponse.contents[0].sections.length > 1,
      orElse: () => null, // Return null while loading
    );

    final tabCount = showContentsTab == true ? 2 : 1;

    return DefaultTabController(
      length: tabCount,
      child: Scaffold(
        appBar: TextScreenAppBar(onBackPressed: () => Navigator.pop(context)),
        body: Padding(
          padding: TextScreenConstants.screenLargePaddingNoBottom,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTextHeader(context, text),
              const SizedBox(height: 4),
              _buildTextType(text, localizations),
              const SizedBox(height: TextScreenConstants.largeTitleFontSize),
              ContinueReadingButton(
                label: localizations.text_toc_continueReading,
                onPressed: () {
                  context.push(TextRoutes.chapters, extra: {'textId': text.id});
                },
              ),
              const SizedBox(
                height: TextScreenConstants.extraLargeVerticalSpacing,
              ),
              // Show loading state until we know whether to show contents tab
              if (showContentsTab == null)
                const Expanded(child: LoadingStateWidget())
              else
                _buildTabs(
                  localizations,
                  context,
                  textContentResponse,
                  textVersionResponse,
                  showContentsTab,
                ),
            ],
          ),
        ),
        bottomNavigationBar: const PechaBottomNavBar(),
      ),
    );
  }

  Widget _buildTextHeader(BuildContext context, Texts text) {
    return Row(
      children: [
        Expanded(
          child: Text(
            text.title,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              fontSize: getFontSize(text.language),
              fontWeight: FontWeight.w500,
              fontFamily: getFontFamily(text.language),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTextType(Texts text, AppLocalizations localizations) {
    return Text(
      text.type.toLowerCase() == "root_text"
          ? localizations.text_detail_rootText.toUpperCase()
          : localizations.text_detail_commentaryText.toUpperCase(),
      style: TextStyle(
        fontSize: TextScreenConstants.bodyFontSize,
        fontWeight: FontWeight.w500,
        color: Colors.grey[TextScreenConstants.greyShade600],
      ),
    );
  }

  Widget _buildTabs(
    AppLocalizations localizations,
    BuildContext context,
    AsyncValue<TocResponse> textContentResponse,
    AsyncValue<VersionResponse> textVersionResponse,
    bool showContentsTab,
  ) {
    return Expanded(
      child: Column(
        children: [
          // Tab Bar
          TabBar(
            labelColor: Theme.of(context).textTheme.bodyMedium?.color,
            unselectedLabelColor: Colors.grey,
            indicatorColor: Theme.of(context).colorScheme.primary,
            indicatorWeight: 2.5,
            isScrollable: !showContentsTab, // Left-align when single tab
            tabAlignment:
                showContentsTab ? TabAlignment.fill : TabAlignment.start,
            tabs: [
              if (showContentsTab) Tab(text: localizations.text_toc_content),
              Tab(text: localizations.text_toc_versions),
            ],
            dividerColor: const Color(0xFFDEE2E6),
          ),
          const SizedBox(height: TextScreenConstants.largeVerticalSpacing),
          Expanded(
            child: TabBarView(
              children: [
                // Contents Tab
                if (showContentsTab)
                  textContentResponse.when(
                    loading: () => const LoadingStateWidget(),
                    error:
                        (error, stackTrace) => ErrorStateWidget(
                          error: error,
                          customMessage:
                              'Unable to load table of contents.\nPlease try again later.',
                        ),
                    data: (contentResponse) {
                      if (contentResponse.contents[0].sections.length > 1) {
                        return TableOfContents(toc: contentResponse);
                      } else {
                        return const Center(child: Text('No content found'));
                      }
                    },
                  ),
                // Versions Tab
                textVersionResponse.when(
                  loading: () => const LoadingStateWidget(),
                  error:
                      (error, stackTrace) => ErrorStateWidget(
                        error: error,
                        customMessage:
                            'Unable to load versions.\nPlease try again later.',
                      ),
                  data: (versionResponse) {
                    if (versionResponse.versions.isNotEmpty) {
                      return _buildVersionsList(
                        versionResponse.versions,
                        context,
                      );
                    } else {
                      return const Center(child: Text('No versions found'));
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVersionsList(List<Version> versions, BuildContext context) {
    return ListView.separated(
      itemCount: versions.length,
      padding: const EdgeInsets.only(top: 10, bottom: 10),
      separatorBuilder:
          (context, idx) => const Divider(
            height: 32,
            thickness: TextScreenConstants.thinDividerThickness,
            color: Color(0xFFF0F0F0),
          ),
      itemBuilder: (context, idx) {
        final version = versions[idx];
        final contentId =
            version.tableOfContents.isNotEmpty
                ? version.tableOfContents[0]
                : null;

        return VersionListItem(
          version: version,
          languageLabel: getLanguageLabel(version.language, context),
          onTap: () {
            context.push(
              TextRoutes.chapters,
              extra: {'textId': version.id, 'contentId': contentId},
            );
          },
        );
      },
    );
  }
}
