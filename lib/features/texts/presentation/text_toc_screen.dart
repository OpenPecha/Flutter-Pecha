import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/l10n/generated/app_localizations.dart';
import 'package:flutter_pecha/core/widgets/error_state_widget.dart';
import 'package:flutter_pecha/features/app/presentation/pecha_bottom_nav_bar.dart';
import 'package:flutter_pecha/features/texts/data/providers/apis/texts_provider.dart';
import 'package:flutter_pecha/features/texts/models/text/texts.dart';
import 'package:flutter_pecha/features/texts/models/text/toc_response.dart';
import 'package:flutter_pecha/features/texts/models/text/version_response.dart';
import 'package:flutter_pecha/features/texts/models/version.dart';
import 'package:flutter_pecha/features/texts/presentation/widgets/table_of_contens.dart';
import 'package:flutter_pecha/shared/utils/helper_fucntions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class TextTocScreen extends ConsumerWidget {
  const TextTocScreen({super.key, required this.text});
  final Texts text;

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
        const Icon(Icons.menu_book_outlined, size: 22),
      ],
    );
  }

  Widget _buildTextType(Texts text, AppLocalizations localizations) {
    return Text(
      text.type.toLowerCase() == "root_text"
          ? localizations.text_detail_rootText
          : localizations.text_detail_commentaryText,
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: Colors.grey[600],
      ),
    );
  }

  Widget _buildContinueReadingButton(
    Texts text,
    AppLocalizations localizations,
    BuildContext context,
  ) {
    return SizedBox(
      width: 200,
      height: 40,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Theme.of(context).colorScheme.primary,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        onPressed: () {
          context.push(
            '/texts/chapter',
            extra: {'textId': text.id, 'contentId': text.id},
          );
        },
        child: Text(
          localizations.text_toc_continueReading,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w500,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildTabs(
    AppLocalizations localizations,
    BuildContext context,
    AsyncValue<TocResponse> textContentResponse,
    AsyncValue<VersionResponse> textVersionResponse,
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
            tabs: [
              Tab(text: localizations.text_toc_content),
              Tab(text: localizations.text_toc_versions),
            ],
            dividerColor: Color(0xFFDEE2E6),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: TabBarView(
              children: [
                // Contents Tab
                textContentResponse.when(
                  loading:
                      () => const Center(child: CircularProgressIndicator()),
                  error:
                      (error, stackTrace) => ErrorStateWidget(
                        error: error,
                        customMessage: 'Unable to load table of contents.\nPlease try again later.',
                      ),
                  data:
                      (contentResponse) =>
                          TableOfContents(toc: contentResponse),
                ),
                // Versions Tab
                textVersionResponse.when(
                  loading:
                      () => const Center(child: CircularProgressIndicator()),
                  error:
                      (error, stackTrace) => ErrorStateWidget(
                        error: error,
                        customMessage: 'Unable to load versions.\nPlease try again later.',
                      ),
                  data:
                      (versionResponse) =>
                          _buildVersionsTab(versionResponse.versions, context),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final localizations = AppLocalizations.of(context)!;
    final textContentResponse = ref.watch(textContentFutureProvider(text.id));
    final textVersionResponse = ref.watch(textVersionFutureProvider(text.id));

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          elevation: 0,
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios),
            onPressed: () => Navigator.pop(context),
          ),
          toolbarHeight: 50,
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(2),
            child: Container(height: 2, color: const Color(0xFFB6D7D7)),
          ),
        ),
        body: Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTextHeader(context, text),
              const SizedBox(height: 4),
              _buildTextType(text, localizations),
              const SizedBox(height: 18),
              _buildContinueReadingButton(text, localizations, context),
              const SizedBox(height: 22),
              _buildTabs(
                localizations,
                context,
                textContentResponse,
                textVersionResponse,
              ),
            ],
          ),
        ),
        bottomNavigationBar: PechaBottomNavBar(),
      ),
    );
  }

  Widget _buildVersionsTab(List<Version> versions, BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    if (versions.isEmpty) {
      return const Center(child: Text('No versions found'));
    }
    return ListView.separated(
      itemCount: versions.length,
      padding: const EdgeInsets.only(top: 10, bottom: 10),
      separatorBuilder:
          (context, idx) =>
              const Divider(height: 32, thickness: 1, color: Color(0xFFF0F0F0)),
      itemBuilder: (context, idx) {
        final version = versions[idx];
        return GestureDetector(
          onTap: () {
            context.push(
              '/texts/chapter',
              extra: {
                'textId': version.id,
                'contentId': version.tableOfContents[0],
              },
            );
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      version.title,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        fontFamily: getFontFamily(version.language),
                      ),
                    ),
                  ),
                  Container(
                    margin: const EdgeInsets.only(left: 8, top: 2),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3F3F3),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Text(
                      _getLanguageLabel(version.language, context),
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.black87,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                localizations.text_toc_revisionHistory,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade800,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _getLanguageLabel(String code, BuildContext context) {
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
        return code;
    }
  }
}
