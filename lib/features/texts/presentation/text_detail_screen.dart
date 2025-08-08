import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/l10n/generated/app_localizations.dart';
import 'package:flutter_pecha/features/app/presentation/pecha_bottom_nav_bar.dart';
import 'package:flutter_pecha/features/texts/models/term/term.dart';
import 'package:flutter_pecha/features/texts/data/providers/texts_provider.dart';
import 'package:flutter_pecha/features/texts/models/text/texts.dart';
import 'package:flutter_pecha/shared/utils/helper_fucntions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class TextDetailScreen extends ConsumerWidget {
  const TextDetailScreen({super.key, required this.term});
  final Term term;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textDetailResponse = ref.watch(textsFutureProvider(term.id));
    final localizations = AppLocalizations.of(context)!;

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
                textDetailResponse.value?.term.title ?? '',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 16),
              textDetailResponse.when(
                data: (response) {
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
                      Text(
                        localizations.text_detail_rootText,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey[700],
                        ),
                      ),
                      if (rootTexts.isEmpty)
                        const Text(
                          "No root text found",
                          style: TextStyle(fontSize: 16),
                        ),
                      ...rootTexts.map((t) => _buildTextList([t], context)),
                      const SizedBox(height: 12),
                      Text(
                        localizations.text_detail_commentaryText,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey[700],
                        ),
                      ),
                      if (commentaries.isEmpty)
                        const Text(
                          "No commentary text found",
                          style: TextStyle(fontSize: 16),
                        ),
                      ...commentaries.map((t) => _buildTextList([t], context)),
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
                    style: TextStyle(
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
}
