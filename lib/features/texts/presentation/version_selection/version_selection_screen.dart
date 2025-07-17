import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/l10n/generated/app_localizations.dart';
import 'package:flutter_pecha/core/utils/get_language.dart';
import 'package:flutter_pecha/features/texts/data/providers/text_reading_params_provider.dart';
import 'package:flutter_pecha/features/texts/data/providers/texts_provider.dart';
import 'package:flutter_pecha/features/texts/data/providers/text_version_language_provider.dart';
import 'package:flutter_pecha/features/texts/models/version.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class VersionSelectionScreen extends ConsumerWidget {
  const VersionSelectionScreen({super.key, required this.textId});

  final String textId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textVersionResponse = ref.watch(textVersionFutureProvider(textId));
    final currentLanguage = ref.watch(textVersionLanguageProvider);
    final numberOfVersions = textVersionResponse.value?.versions
        .map((version) {
          if (version.language == currentLanguage) {
            return 1;
          }
          return 0;
        })
        .reduce((a, b) => a + b);
    final filteredVersions =
        textVersionResponse.value?.versions
            .where((version) => version.language == currentLanguage)
            .toList();
    final uniqueLanguages =
        textVersionResponse.value?.versions
            .map((version) => version.language)
            .toSet()
            .toList();

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.pop(context),
        ),
        toolbarHeight: 50,
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              showSearch(
                context: context,
                delegate: VersionSearchDelegate(
                  versions: filteredVersions ?? [],
                  ref: ref,
                ),
              );
            },
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(2),
          child: Container(height: 2, color: const Color(0xFFB6D7D7)),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Language Card
            _buildLanguageCard(uniqueLanguages ?? [], context, ref),
            // Versions Title
            Text(
              '${getLanguageLabel(currentLanguage, context)} Versions ($numberOfVersions)',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            Expanded(child: _buildVersionCard(filteredVersions ?? [], ref)),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageCard(
    List<String> uniqueLanguages,
    BuildContext context,
    WidgetRef ref,
  ) {
    final localizations = AppLocalizations.of(context)!;
    final currentLanguage = ref.watch(textVersionLanguageProvider);
    return Container(
      margin: EdgeInsets.all(18),
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          const Icon(Icons.language, size: 22),
          const SizedBox(width: 10),
          Text(
            localizations.language,
            style: TextStyle(fontWeight: FontWeight.w500, fontSize: 16),
          ),
          const Spacer(),
          GestureDetector(
            onTap: () async {
              final result = await context.push(
                '/texts/language_selection',
                extra: {"uniqueLanguages": uniqueLanguages},
              );
              if (result != null && result is String) {
                ref
                    .read(textVersionLanguageProvider.notifier)
                    .setLanguage(result);
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Text(
                    getLanguageLabel(currentLanguage, context),
                    style: TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    Icons.arrow_circle_right_outlined,
                    color: Colors.grey.shade600,
                    size: 18,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVersionCard(List<Version> versions, WidgetRef ref) {
    return ListView.builder(
      itemCount: versions.length,
      itemBuilder: (context, index) {
        final version = versions[index];
        return ListTile(
          onTap: () {
            ref
                .read(textReadingParamsProvider.notifier)
                .setParams(
                  textId: version.id,
                  contentId: version.tableOfContents[0],
                  versionId: version.id,
                  segmentId: null,
                  sectionId: null,
                  direction: "next",
                );
            context.pop();
          },
          contentPadding: EdgeInsets.zero,
          title: Text(
            version.title,
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          subtitle: Text(
            '${getLanguageLabel(version.language, context)}, ${version.publishedBy}',
          ),
          trailing: Icon(Icons.info_outline, color: Colors.grey.shade700),
        );
      },
    );
  }
}

class VersionSearchDelegate extends SearchDelegate<Version?> {
  final List<Version> versions;
  final WidgetRef ref;

  VersionSearchDelegate({required this.versions, required this.ref});

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () {
          query = '';
        },
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back_ios),
      onPressed: () {
        close(context, null);
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return _buildSearchResults(context);
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return _buildSearchResults(context);
  }

  Widget _buildSearchResults(BuildContext context) {
    final filteredVersions =
        versions.where((version) {
          return version.title.toLowerCase().contains(query.toLowerCase());
        }).toList();

    if (filteredVersions.isEmpty) {
      return Center(
        child: Text(
          'No versions found for "$query"',
          style: TextStyle(fontSize: 16, color: Colors.grey[600]),
        ),
      );
    }

    return ListView.builder(
      itemCount: filteredVersions.length,
      itemBuilder: (context, index) {
        final version = filteredVersions[index];
        return ListTile(
          onTap: () {
            ref
                .read(textReadingParamsProvider.notifier)
                .setParams(
                  textId: version.id,
                  contentId: version.tableOfContents[0],
                  versionId: version.id,
                  segmentId: '',
                  sectionId: '',
                  direction: '',
                );
            close(context, version);
            Navigator.pop(context);
          },
          title: Text(
            version.title,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          subtitle: Text(
            '${getLanguageLabel(version.language, context)}, ${version.publishedBy}',
          ),
        );
      },
    );
  }
}
