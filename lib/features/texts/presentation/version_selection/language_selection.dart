import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/utils/get_language.dart';
import 'package:flutter_pecha/features/texts/data/providers/text_version_language_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class LanguageSelectionScreen extends ConsumerWidget {
  const LanguageSelectionScreen({super.key, required this.uniqueLanguages});

  final List<String> uniqueLanguages;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentLanguage = ref.watch(textVersionLanguageProvider);
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        toolbarHeight: 50,
        title: const Text('Select a language', style: TextStyle(fontSize: 20)),
        centerTitle: true,
        scrolledUnderElevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(2),
          child: Container(height: 2, color: const Color(0xFFB6D7D7)),
        ),
      ),
      body: ListView.separated(
        itemCount: uniqueLanguages.length,
        separatorBuilder:
            (context, index) => const Divider(height: 1, thickness: 1),
        itemBuilder: (context, index) {
          final language = uniqueLanguages[index];
          final isSelected = language == currentLanguage;
          return ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 4,
            ),
            title: Row(
              children: [
                Text(
                  getLanguageLabel(language, context),
                  style: const TextStyle(fontSize: 16),
                ),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  language,
                  style: const TextStyle(fontSize: 16, color: Colors.grey),
                ),
                if (isSelected) ...[
                  const SizedBox(width: 8),
                  const Icon(Icons.check, color: Colors.green),
                ],
              ],
            ),
            onTap: () {
              ref
                  .read(textVersionLanguageProvider.notifier)
                  .setLanguage(language);
              Navigator.pop(context);
            },
          );
        },
      ),
    );
  }
}
