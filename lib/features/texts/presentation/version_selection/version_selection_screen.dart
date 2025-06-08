import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/l10n/generated/app_localizations.dart';
import 'package:flutter_pecha/core/utils/get_language.dart';
import 'package:flutter_pecha/features/texts/data/providers/texts_provider.dart';
import 'package:flutter_pecha/features/texts/data/providers/version_provider.dart';
import 'package:flutter_pecha/features/texts/models/version.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class VersionSelectionScreen extends ConsumerStatefulWidget {
  const VersionSelectionScreen({
    super.key,
    required this.textId,
    required this.selectedLanguage,
  });

  final String textId;
  final String selectedLanguage;

  @override
  ConsumerState<VersionSelectionScreen> createState() =>
      _VersionSelectionScreenState();
}

class _VersionSelectionScreenState
    extends ConsumerState<VersionSelectionScreen> {
  late String selectedLanguage;

  @override
  void initState() {
    super.initState();
    selectedLanguage = widget.selectedLanguage;
  }

  @override
  Widget build(BuildContext context) {
    final textVersionResponse = ref.watch(
      textVersionFutureProvider(widget.textId),
    );
    final numberOfVersions = textVersionResponse.value?.versions
        .map((version) {
          if (version.language == selectedLanguage) {
            return 1;
          }
          return 0;
        })
        .reduce((a, b) => a + b);
    final filteredVersions =
        textVersionResponse.value?.versions
            .where((version) => version.language == selectedLanguage)
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
            onPressed: () => Navigator.pop(context),
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
            _buildLanguageCard(uniqueLanguages ?? [], context),
            // Versions Title
            Text(
              '${getLanguageLabel(selectedLanguage, context)} Versions ($numberOfVersions)',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            Expanded(child: _buildVersionCard(filteredVersions ?? [])),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageCard(
    List<String> uniqueLanguages,
    BuildContext context,
  ) {
    final localizations = AppLocalizations.of(context)!;
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
                extra: {
                  "uniqueLanguages": uniqueLanguages,
                  "selectedLanguage": selectedLanguage,
                },
              );
              if (result != null && result is String) {
                setState(() {
                  selectedLanguage = result;
                });
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
                    getLanguageLabel(selectedLanguage, context),
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

  Widget _buildVersionCard(List<Version> versions) {
    return ListView.builder(
      itemCount: versions.length,
      itemBuilder: (context, index) {
        final version = versions[index];
        return ListTile(
          onTap: () {
            ref.read(versionProvider.notifier).setVersion(version, skip: '0');
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
