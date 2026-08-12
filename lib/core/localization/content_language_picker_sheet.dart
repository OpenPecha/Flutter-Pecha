import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/constants/app_assets.dart';
import 'package:flutter_pecha/core/l10n/generated/app_localizations.dart';
import 'package:flutter_pecha/core/localization/app_language.dart';
import 'package:flutter_pecha/core/localization/languages_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ContentLanguagePickerSheet extends ConsumerWidget {
  const ContentLanguagePickerSheet({
    super.key,
    required this.selectedCode,
    required this.onSelected,
    this.title,
  });

  final String selectedCode;
  final ValueChanged<String> onSelected;
  final String? title;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final languages = ref.watch(resolvedContentLanguagesProvider);

    return SafeArea(
      top: false,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.7,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                title ?? l10n.language,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                itemCount: languages.length,
                separatorBuilder:
                    (_, __) => Divider(
                      height: 1,
                      color: theme.dividerColor.withValues(alpha: 0.4),
                    ),
                itemBuilder: (_, index) {
                  final language = languages[index];
                  final isSelected = language.code == selectedCode;
                  return _ContentLanguageOption(
                    language: language,
                    isSelected: isSelected,
                    onTap: () {
                      onSelected(language.code);
                      Navigator.of(context).pop();
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class _ContentLanguageOption extends StatelessWidget {
  const _ContentLanguageOption({
    required this.language,
    required this.isSelected,
    required this.onTap,
  });

  final AppLanguage language;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final activeColor = theme.colorScheme.primary;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  language.nativeName,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color:
                        isSelected
                            ? activeColor
                            : theme.textTheme.titleMedium?.color,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ),
              SizedBox(
                width: 18,
                child:
                    isSelected
                        ? Icon(AppAssets.check, size: 18, color: activeColor)
                        : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Future<void> showContentLanguagePickerSheet(
  BuildContext context, {
  required String selectedCode,
  required ValueChanged<String> onSelected,
  String? title,
}) {
  return showModalBottomSheet(
    context: context,
    backgroundColor: Theme.of(context).scaffoldBackgroundColor,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    isScrollControlled: true,
    useRootNavigator: true,
    builder:
        (_) => ContentLanguagePickerSheet(
          selectedCode: selectedCode,
          onSelected: onSelected,
          title: title,
        ),
  );
}
