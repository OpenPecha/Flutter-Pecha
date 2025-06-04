import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/l10n/generated/app_localizations.dart';
import 'package:flutter_pecha/core/utils/get_language.dart';
import 'package:flutter_pecha/features/texts/data/providers/texts_provider.dart';
import 'package:flutter_pecha/features/texts/models/version.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class VersionSelectionScreen extends ConsumerWidget {
  const VersionSelectionScreen({
    super.key,
    required this.textId,
    required this.language,
  });

  final String textId;
  final String language;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textVersionResponse = ref.watch(textVersionFutureProvider(textId));
    final numberOfVersions = textVersionResponse.value?.versions
        .map((version) {
          if (version.language == language) {
            return 1;
          }
          return 0;
        })
        .reduce((a, b) => a + b);

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
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
            _buildLanguageCard(language, context),
            // Versions Title
            Text(
              '${getLanguageLabel(language, context)} Versions ($numberOfVersions)',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            // Versions List
            textVersionResponse.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error:
                  (error, stackTrace) => Center(child: Text(error.toString())),
              data:
                  (textVersion) =>
                      Expanded(child: _buildVersionCard(textVersion.versions)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageCard(String language, BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    return Container(
      margin: EdgeInsets.all(18),
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F8F8),
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
            onTap: () => context.push('/texts/language_selection'),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Text(
                    getLanguageLabel(language, context),
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
