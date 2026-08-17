import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_pecha/core/extensions/context_ext.dart';
import 'package:flutter_pecha/core/theme/font_config.dart';
import 'package:flutter_pecha/features/reader/presentation/widgets/reader_panels/reader_panel_constants.dart';
import 'package:flutter_pecha/shared/utils/helper_functions.dart';

/// Chevron row + expandable card showing the title, source and license for a
/// panel item (translation/commentary). Source and license rows are hidden
/// when their values are missing so the tile remains useful before the API
/// fully populates these fields.
class ReaderPanelMetadataTile extends StatelessWidget {
  const ReaderPanelMetadataTile({
    super.key,
    required this.title,
    required this.language,
    required this.source,
    required this.license,
    required this.isExpanded,
    required this.onToggle,
  });

  final String title;
  final String language;
  final String? source;
  final String? license;
  final bool isExpanded;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fontFamily = getFontFamily(language);
    final lineHeight = getLineHeight(language);
    final titleFontSize = getLocalizedFontSize(AppTextSize.label);
    final titleStyle = AppFontConfig.applyTibetanMetrics(
      language,
      TextStyle(
        fontFamily: fontFamily,
        height: lineHeight,
        fontSize: titleFontSize,
        color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
        fontWeight: FontWeight.w500,
      ),
    );
    final titleStrutStyle = AppFontConfig.tibetanStrutStyle(
      language,
      titleFontSize,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () {
            HapticFeedback.selectionClick();
            onToggle();
          },
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AnimatedRotation(
                  duration: const Duration(milliseconds: 150),
                  turns: isExpanded ? 0.5 : 0.0,
                  child: Icon(
                    Icons.expand_more,
                    size: 18,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    title,
                    style: titleStyle,
                    strutStyle: titleStrutStyle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          alignment: Alignment.topCenter,
          child:
              isExpanded
                  ? _MetadataCard(
                    title: title,
                    language: language,
                    source: source,
                    license: license,
                  )
                  : const SizedBox.shrink(),
        ),
      ],
    );
  }
}

class _MetadataCard extends StatelessWidget {
  const _MetadataCard({
    required this.title,
    required this.language,
    required this.source,
    required this.license,
  });

  final String title;
  final String language;
  final String? source;
  final String? license;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final localizations = context.l10n;
    final isDark = theme.brightness == Brightness.dark;
    final cardColor =
        isDark
            ? Colors.white.withValues(alpha: 0.06)
            : Colors.black.withValues(alpha: 0.04);
    final fontFamily = getFontFamily(language);
    final lineHeight = getLineHeight(language);
    final titleFontSize = getLocalizedFontSize(AppTextSize.label);
    final titleStyle = AppFontConfig.applyTibetanMetrics(
      language,
      TextStyle(
        fontFamily: fontFamily,
        height: lineHeight,
        fontSize: titleFontSize,
        fontWeight: FontWeight.w600,
        color: theme.colorScheme.onSurface,
      ),
    );
    final titleStrutStyle = AppFontConfig.tibetanStrutStyle(
      language,
      titleFontSize,
    );

    final hasSource = source != null && source!.trim().isNotEmpty;
    final hasLicense = license != null && license!.trim().isNotEmpty;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 6, bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(ReaderPanelConstants.cardRadius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: titleStyle,
            strutStyle: titleStrutStyle,
          ),
          if (hasSource) ...[
            const SizedBox(height: 6),
            _MetadataRow(label: localizations.source, value: source!),
          ],
          if (hasLicense) ...[
            const SizedBox(height: 4),
            _MetadataRow(label: localizations.reader_license, value: license!),
          ],
        ],
      ),
    );
  }
}

class _MetadataRow extends StatelessWidget {
  const _MetadataRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final style = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
    );
    return Text('$label: $value', style: style);
  }
}
