import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/l10n/generated/app_localizations.dart';
import 'package:flutter_pecha/core/widgets/error_state_widget.dart';
import 'package:flutter_pecha/features/app/presentation/pecha_bottom_nav_bar.dart';
import 'package:flutter_pecha/features/texts/constants/text_screen_constants.dart';
import 'package:flutter_pecha/features/texts/constants/text_routes.dart';
import 'package:flutter_pecha/features/texts/data/providers/apis/texts_provider.dart';
import 'package:flutter_pecha/features/texts/models/text/commentary_text_response.dart';
import 'package:flutter_pecha/features/texts/models/text/texts.dart';
import 'package:flutter_pecha/features/texts/models/text/toc_response.dart';
import 'package:flutter_pecha/features/texts/models/text/version_response.dart';
import 'package:flutter_pecha/features/texts/models/text_detail.dart';
import 'package:flutter_pecha/features/texts/models/version.dart';
import 'package:flutter_pecha/features/texts/presentation/widgets/commentary_tab.dart';
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
  const TextsScreen({super.key, required this.text, this.colorIndex});
  final Texts text;
  final int? colorIndex;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final localizations = AppLocalizations.of(context)!;
    final textContentResponse = ref.watch(textContentFutureProvider(text.id));
    final textVersionResponse = ref.watch(textVersionFutureProvider(text.id));
    final commentaryTextResponse = ref.watch(
      commentaryTextFutureProvider(text.id),
    );

    // Determine if we should show the contents tab
    final showContentsTab = textContentResponse.maybeWhen(
      data:
          (contentResponse) =>
              contentResponse.contents.isNotEmpty &&
              contentResponse.contents[0].sections.length > 1,
      orElse: () => null, // Return null while loading
    );

    final tabCount = showContentsTab == true ? 3 : 2;

    // Get the border color from the color index
    final borderColor =
        colorIndex != null
            ? TextScreenConstants.collectionCyclingColors[colorIndex! % 9]
            : null;

    return DefaultTabController(
      length: tabCount,
      child: Scaffold(
        appBar: TextScreenAppBar(
          onBackPressed: () => context.pop(),
          borderColor: borderColor,
        ),
        body: Padding(
          padding: TextScreenConstants.screenLargePaddingNoBottom,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTextHeader(context, text),
              const SizedBox(height: TextScreenConstants.largeTitleFontSize),
              if (showContentsTab == null)
                const Expanded(child: LoadingStateWidget())
              else
                _buildTabs(
                  localizations,
                  context,
                  textContentResponse,
                  textVersionResponse,
                  commentaryTextResponse,
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
    final language = text.language ?? '';
    final fontSize = 22.0;
    return Row(
      children: [
        Expanded(
          child: Text(
            text.title,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              fontSize: fontSize,
              fontWeight: FontWeight.w500,
              fontFamily: getFontFamily(language),
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
    AsyncValue<CommentaryTextResponse> commentaryTextResponse,
    bool showContentsTab,
  ) {
    final localizations = AppLocalizations.of(context)!;
    return Expanded(
      child: Column(
        children: [
          // Tab Bar
          TabBar(
            labelColor: Theme.of(context).textTheme.bodyMedium?.color,
            labelStyle: TextStyle(
              fontSize: TextScreenConstants.largeTitleFontSize,
              fontWeight: FontWeight.w500,
            ),
            unselectedLabelColor: Colors.grey,
            indicatorColor: Colors.grey,
            indicatorWeight: 2.5,
            isScrollable: !showContentsTab, // Left-align when single tab
            tabAlignment:
                showContentsTab ? TabAlignment.fill : TabAlignment.start,
            tabs: [
              if (showContentsTab) Tab(text: localizations.text_toc_content),
              Tab(text: localizations.text_toc_versions),
              Tab(text: localizations.text_detail_commentaryText),
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
                      // Safely check bounds before accessing contents[0]
                      if (contentResponse.contents.isNotEmpty &&
                          contentResponse.contents[0].sections.length > 1) {
                        return TableOfContents(toc: contentResponse);
                      } else {
                        return Center(child: Text(localizations.no_content));
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
                    if ((versionResponse.versions?.isEmpty ?? true) &&
                        versionResponse.text == null) {
                      return Center(child: Text(localizations.no_version));
                    }
                    return _buildVersionsList(
                      versionResponse.text!,
                      versionResponse.versions ?? [],
                      context,
                    );
                  },
                ),
                // Commentary Tab
                commentaryTextResponse.when(
                  loading: () => const LoadingStateWidget(),
                  error:
                      (error, stackTrace) => ErrorStateWidget(
                        error: error,
                        customMessage:
                            'Unable to load commentary text.\nPlease try again later.',
                      ),
                  data: (commentaryTextResponse) {
                    if (commentaryTextResponse.commentaries.isNotEmpty) {
                      final commentaries = commentaryTextResponse.commentaries;
                      return CommentaryTab(commentaries: commentaries);
                    } else {
                      return Center(child: Text(localizations.no_commentary));
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

  Widget _buildVersionsList(
    TextDetail text,
    List<Version> versions,
    BuildContext context,
  ) {
    final newVersions = [
      Version(
        id: text.id,
        title: text.title,
        language: text.language,
        type: text.type,
        tableOfContents: [],
        isPublished: text.isPublished,
        createdDate: text.createdDate,
        updatedDate: text.updatedDate,
        publishedDate: text.publishedDate,
        publishedBy: text.publishedBy,
        sourceLink: text.sourceLink,
        license: text.license,
      ),
      ...versions,
    ];
    return ListView.separated(
      itemCount: newVersions.length,
      padding: const EdgeInsets.only(top: 10, bottom: 10),
      separatorBuilder:
          (context, idx) => const Divider(
            height: 32,
            thickness: TextScreenConstants.thinDividerThickness,
            color: Color(0xFFF0F0F0),
          ),
      itemBuilder: (context, idx) {
        final version = newVersions[idx];
        final contentId =
            version.tableOfContents.isNotEmpty
                ? version.tableOfContents[0]
                : null;

        return VersionListItem(
          title: version.title,
          sourceLink: version.sourceLink ?? '',
          license: version.license ?? '',
          language: version.language,
          languageLabel: getLanguageLabel(version.language, context),
          onTap: () {
            context.push(
              TextRoutes.chapters,
              extra: {
                'textId': version.id,
                'contentId': contentId,
                'colorIndex': colorIndex,
              },
            );
          },
        );
      },
    );
  }
}
