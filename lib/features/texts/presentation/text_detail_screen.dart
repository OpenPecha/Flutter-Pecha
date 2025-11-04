import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/config/locale/locale_notifier.dart';
import 'package:flutter_pecha/core/l10n/generated/app_localizations.dart';
import 'package:flutter_pecha/features/app/presentation/pecha_bottom_nav_bar.dart';
import 'package:flutter_pecha/features/texts/models/collections/collections.dart';
import 'package:flutter_pecha/features/texts/data/providers/apis/texts_provider.dart';
import 'package:flutter_pecha/features/texts/models/text/texts.dart';
import 'package:flutter_pecha/shared/utils/helper_fucntions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class TextDetailScreen extends ConsumerWidget {
  const TextDetailScreen({super.key, required this.collection});
  final Collections collection;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textDetailResponse = ref.watch(textsFutureProvider(collection.id));

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.pop(context),
        ),
        title: null,
        centerTitle: true,
        shape: Border(bottom: BorderSide(color: Color(0xFFB6D7D7), width: 3)),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                textDetailResponse.value?.collections.title ?? '',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 16),
              textDetailResponse.when(
                data: (response) {
                  final texts = response.texts;
                  final rootTexts =
                      response.texts
                          .where((t) => t.type.toLowerCase() == 'root_text')
                          .toList();
                  final commentaries =
                      response.texts
                          .where((t) => t.type.toLowerCase() == 'commentary')
                          .toList();
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (texts.isEmpty)
                        _buildEmptyState(context, ref)
                      else ...[
                        _buildRootTexts(rootTexts, context),
                        const SizedBox(height: 12),
                        _buildCommentaries(commentaries, context),
                      ],
                    ],
                  );
                },
                loading:
                    () => const Padding(
                      padding: EdgeInsets.only(top: 40.0),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                error:
                    (e, st) => Padding(
                      padding: const EdgeInsets.only(top: 40.0),
                      child: Center(child: Text('Failed to load texts')),
                    ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const PechaBottomNavBar(),
    );
  }

  Widget _buildRootTexts(List<Texts> texts, BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final buildTitle = Text(
      localizations.text_detail_rootText,
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w500,
        color: Colors.grey[700],
      ),
    );
    if (texts.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        buildTitle,
        ...texts.map((text) => _buildTextList([text], context)),
      ],
    );
  }

  Widget _buildCommentaries(List<Texts> texts, BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final buildTitle = Text(
      localizations.text_detail_commentaryText,
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w500,
        color: Colors.grey[700],
      ),
    );
    if (texts.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        buildTitle,
        ...texts.map((text) => _buildTextList([text], context)),
      ],
    );
  }

  Widget _buildTextList(List<Texts> texts, BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children:
          texts.map((text) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Divider(thickness: 1, color: Color(0xFFB6D7D7)),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    text.title,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontSize: getFontSize(text.language),
                      fontFamily: getFontFamily(text.language),
                    ),
                  ),
                  onTap: () {
                    context.push('/texts/toc', extra: text);
                  },
                ),
              ],
            );
          }).toList(),
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
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 18),
            if (currentLocale?.languageCode != 'bo')
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
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  localizations.text_switchToTibetan,
                  style: const TextStyle(
                    fontSize: 16,
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
