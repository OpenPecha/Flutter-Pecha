import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/theme/app_colors.dart';
import 'package:flutter_pecha/features/ai/data/models/chat_message.dart';
import 'package:flutter_pecha/features/ai/presentation/widgets/source_bottom_sheet.dart';
import 'package:flutter_pecha/features/ai/presentation/providers/segment_url_resolver_provider.dart';
import 'package:flutter_pecha/features/reader/data/models/navigation_context.dart';
import 'package:flutter_pecha/shared/utils/helper_functions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_pecha/core/extensions/context_ext.dart';

class MessageBubble extends ConsumerStatefulWidget {
  final ChatMessage message;

  const MessageBubble({super.key, required this.message});

  @override
  ConsumerState<MessageBubble> createState() => _MessageBubbleState();
}

class _MessageBubbleState extends ConsumerState<MessageBubble> {
  // Track which source is currently loading
  String? _loadingSourceId;

  /// Truncate title to specified character length
  String _truncateTitle(String title, int maxLength) {
    if (title.length <= maxLength) return title;
    return '${title.substring(0, maxLength)}...';
  }

  /// Handle source click - resolve URL and navigate
  Future<void> _handleSourceClick(SearchResult source) async {
    // Set loading state
    setState(() {
      _loadingSourceId = source.id;
    });

    try {
      // Get the repository
      final repository = ref.read(segmentUrlResolverRepositoryProvider);

      // Call API to resolve segment URL
      final result = await repository.resolveSegmentUrl(source.id);

      // Check if widget is still mounted before navigation
      if (!mounted) return;
      final textId = result['textId'];
      final segmentId = result['segmentId'];

      // Navigate to new reader with search context
      final navigationContext = NavigationContext(
        source: NavigationSource.search,
        targetSegmentId: segmentId,
      );
      context.push('/reader/$textId', extra: navigationContext);
    } catch (e) {
      // Show error dialog if API fails
      if (!mounted) return;

      final localizations = context.l10n;
      showDialog(
        context: context,
        builder:
            (dialogContext) => AlertDialog(
              title: Text(localizations.ai_text_not_found),
              content: Text(
                localizations.ai_text_not_found_message(source.title),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.accentGold,
                  ),
                  child: Text(localizations.common_ok),
                ),
              ],
            ),
      );
    } finally {
      // Clear loading state
      if (mounted) {
        setState(() {
          _loadingSourceId = null;
        });
      }
    }
  }

  /// Parse markdown bold and citations from content using two-pass approach
  List<InlineSpan> _parseContentWithCitations(
    BuildContext context,
    String content,
    List<SearchResult> searchResults,
    bool isDarkMode,
    TextStyle baseStyle,
  ) {
    // Map to track citation numbers and their widgets
    final Map<String, int> idToNumber = {};
    final Map<String, Widget> citationWidgets = {};
    int citationCounter = 0;

    // FIRST PASS: Replace valid citations with unique markers
    String processedContent = content;
    final citationRegex = RegExp(r'\[([a-zA-Z0-9\-_,\s]+)\]');

    processedContent = processedContent.replaceAllMapped(citationRegex, (
      match,
    ) {
      final citationContent = match.group(1)!;
      final ids =
          citationContent
              .split(RegExp(r'[,\s]+'))
              .where((id) => id.trim().isNotEmpty)
              .toList();

      String replacement = '';

      // Process each ID
      for (final id in ids) {
        final trimmedId = id.trim();

        // Check if this ID exists in search results
        final sourceIndex = searchResults.indexWhere((s) => s.id == trimmedId);

        if (sourceIndex != -1) {
          // Assign a citation number if not already assigned
          if (!idToNumber.containsKey(trimmedId)) {
            citationCounter++;
            idToNumber[trimmedId] = citationCounter;

            final source = searchResults[sourceIndex];

            // Create citation widget and store it
            citationWidgets[trimmedId] = GestureDetector(
              onTap: () {
                SourceBottomSheet.show(context, source, citationCounter);
              },
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 2),
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: BoxDecoration(
                  color:
                      isDarkMode
                          ? AppColors.grey600.withValues(alpha: 0.3)
                          : AppColors.grey300.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: isDarkMode ? AppColors.grey500 : AppColors.grey600,
                    width: 1,
                  ),
                ),
                child: Text(
                  _truncateTitle(source.title, 15),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: isDarkMode ? AppColors.grey300 : AppColors.grey800,
                  ),
                ),
              ),
            );
          }

          // Add marker for this citation
          replacement += '<<CITE:$trimmedId>>';
        }
        // If ID doesn't exist, don't add anything (ignore it)
      }

      return replacement;
    });

    // SECOND PASS: Parse bold text
    final List<InlineSpan> spans = [];
    final boldRegex = RegExp(r'\*\*([^*]+)\*\*');
    int lastMatchEnd = 0;

    for (final match in boldRegex.allMatches(processedContent)) {
      // Add text before the bold
      if (match.start > lastMatchEnd) {
        final textBefore = processedContent.substring(
          lastMatchEnd,
          match.start,
        );
        spans.addAll(
          _parseTextWithCitationMarkers(textBefore, citationWidgets, baseStyle),
        );
      }

      // Add bold text (may contain citation markers)
      final boldText = match.group(1)!;
      spans.addAll(
        _parseTextWithCitationMarkers(
          boldText,
          citationWidgets,
          baseStyle.copyWith(fontWeight: FontWeight.bold),
        ),
      );

      lastMatchEnd = match.end;
    }

    // Add remaining text after last bold
    if (lastMatchEnd < processedContent.length) {
      final remainingText = processedContent.substring(lastMatchEnd);
      spans.addAll(
        _parseTextWithCitationMarkers(
          remainingText,
          citationWidgets,
          baseStyle,
        ),
      );
    }

    return spans;
  }

  /// Helper method to parse text containing citation markers
  List<InlineSpan> _parseTextWithCitationMarkers(
    String text,
    Map<String, Widget> citationWidgets,
    TextStyle style,
  ) {
    final List<InlineSpan> spans = [];
    final markerRegex = RegExp(r'<<CITE:([a-zA-Z0-9\-_]+)>>');
    int lastMatchEnd = 0;

    for (final match in markerRegex.allMatches(text)) {
      // Add text before the marker
      if (match.start > lastMatchEnd) {
        spans.add(
          TextSpan(
            text: text.substring(lastMatchEnd, match.start),
            style: TextStyle(fontSize: 16),
          ),
        );
      }

      // Add citation widget
      final citationId = match.group(1)!;
      if (citationWidgets.containsKey(citationId)) {
        spans.add(
          WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: citationWidgets[citationId]!,
          ),
        );
      }

      lastMatchEnd = match.end;
    }

    // Add remaining text
    if (lastMatchEnd < text.length) {
      spans.add(TextSpan(text: text.substring(lastMatchEnd), style: style));
    }

    return spans;
  }

  /// Get cited sources in order of first appearance
  List<SearchResult> _getCitedSources() {
    final citedSources = <SearchResult>[];
    final seenIds = <String>{};

    // Parse content to find citations in order
    final citationRegex = RegExp(r'\[([a-zA-Z0-9\-_,\s]+)\]');
    final matches = citationRegex.allMatches(widget.message.content);

    for (final match in matches) {
      final citationContent = match.group(1)!;
      final ids =
          citationContent
              .split(RegExp(r'[,\s]+'))
              .where((id) => id.trim().isNotEmpty)
              .toList();

      for (final id in ids) {
        final trimmedId = id.trim();

        if (!seenIds.contains(trimmedId)) {
          final sourceIndex = widget.message.searchResults.indexWhere(
            (s) => s.id == trimmedId,
          );

          if (sourceIndex != -1) {
            seenIds.add(trimmedId);
            citedSources.add(widget.message.searchResults[sourceIndex]);
          }
        }
      }
    }

    return citedSources;
  }

  /// Build sources button that opens bottom sheet
  Widget _buildSourcesButton(BuildContext context, bool isDarkMode) {
    final citedSources = _getCitedSources();

    if (citedSources.isEmpty) return const SizedBox.shrink();

    final localizations = context.l10n;

    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: GestureDetector(
        onTap: () {
          _showSourcesBottomSheet(context, citedSources, isDarkMode);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
          decoration: BoxDecoration(
            color:
                isDarkMode
                    ? AppColors.surfaceVariantDark
                    : AppColors.surfaceWhite,
            borderRadius: BorderRadius.circular(30),
            border: Border.all(
              color: isDarkMode ? AppColors.cardBorderDark : AppColors.grey100,
              width: 1,
            ),
          ),
          child: Text(
            localizations.ai_sources_count(citedSources.length),
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: isDarkMode ? AppColors.grey400 : AppColors.grey600,
            ),
          ),
        ),
      ),
    );
  }

  /// Show bottom sheet with all sources
  void _showSourcesBottomSheet(
    BuildContext context,
    List<SearchResult> citedSources,
    bool isDarkMode,
  ) {
    // Unfocus any text fields to prevent keyboard popup
    FocusScope.of(context).unfocus();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      enableDrag: true,
      isDismissible: true,
      builder:
          (context) => Container(
            decoration: BoxDecoration(
              color: isDarkMode ? AppColors.surfaceDark : Colors.white,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: DraggableScrollableSheet(
              initialChildSize: 0.7,
              minChildSize: 0.5,
              maxChildSize: 0.9,
              expand: false,
              builder: (context, scrollController) {
                return Column(
                  children: [
                    // Drag Handle
                    Container(
                      margin: const EdgeInsets.only(top: 12, bottom: 8),
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color:
                            isDarkMode ? AppColors.grey500 : AppColors.grey400,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),

                    // Sources heading
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      child: Text(
                        context.l10n.ai_sources,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color:
                              isDarkMode
                                  ? AppColors.textPrimaryDark
                                  : AppColors.textPrimary,
                        ),
                      ),
                    ),

                    // Sources list
                    Expanded(
                      child: ListView(
                        controller: scrollController,
                        padding: const EdgeInsets.only(
                          left: 10,
                          right: 10,
                          bottom: 10,
                        ),
                        children: List.generate(citedSources.length, (index) {
                          final source = citedSources[index];
                          final citationNumber = index + 1;
                          final isLoading = _loadingSourceId == source.id;

                          return InkWell(
                            onTap:
                                isLoading
                                    ? null
                                    : () => _handleSourceClick(source),
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color:
                                    isDarkMode
                                        ? AppColors.surfaceVariantDark
                                        : AppColors.surfaceWhite,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color:
                                      isDarkMode
                                          ? AppColors.cardBorderDark
                                          : AppColors.grey300,
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Citation number or loading indicator
                                  Container(
                                    width: 24,
                                    height: 24,
                                    margin: const EdgeInsets.only(right: 12),
                                    decoration: BoxDecoration(
                                      color:
                                          isDarkMode
                                              ? AppColors.grey600.withValues(
                                                alpha: 0.5,
                                              )
                                              : AppColors.grey300,
                                      shape: BoxShape.circle,
                                    ),
                                    alignment: Alignment.center,
                                    child:
                                        isLoading
                                            ? SizedBox(
                                              width: 14,
                                              height: 14,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                valueColor:
                                                    AlwaysStoppedAnimation<
                                                      Color
                                                    >(
                                                      isDarkMode
                                                          ? AppColors.grey300
                                                          : AppColors.grey800,
                                                    ),
                                              ),
                                            )
                                            : Text(
                                              '$citationNumber',
                                              style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w600,
                                                color:
                                                    isDarkMode
                                                        ? AppColors.grey300
                                                        : AppColors.grey800,
                                              ),
                                            ),
                                  ),

                                  // Title and text
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          source.title,
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w500,
                                            color:
                                                isDarkMode
                                                    ? AppColors.textPrimaryDark
                                                    : AppColors.textPrimary,
                                            height: 1.4,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          source.text,
                                          style: TextStyle(
                                            fontSize: 14,
                                            color:
                                                isDarkMode
                                                    ? AppColors
                                                        .textSecondaryDark
                                                    : AppColors.textSecondary,
                                            height: 1.4,
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
    ).then((_) {
      // Prevent keyboard from popping up after modal closes
      // ignore: use_build_context_synchronously
      FocusScope.of(context).unfocus();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final fontSize = getLocalizedFontSize(AppTextSize.body);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment:
            widget.message.isUser
                ? MainAxisAlignment.end
                : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Message Content
          Flexible(
            child:
                widget.message.isUser
                    ? Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surfaceContainer,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(18),
                          topRight: Radius.circular(4),
                          bottomLeft: Radius.circular(18),
                          bottomRight: Radius.circular(18),
                        ),
                      ),
                      child: Text(
                        widget.message.content,
                        style: TextStyle(fontSize: fontSize, height: 1.4),
                      ),
                    )
                    : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Main message content
                        RichText(
                          text: TextSpan(
                            style: TextStyle(
                              fontSize: fontSize,
                              height: 1.4,
                              color:
                                  isDarkMode
                                      ? AppColors.textPrimaryDark
                                      : AppColors.textPrimary,
                            ),
                            children: _parseContentWithCitations(
                              context,
                              widget.message.content,
                              widget.message.searchResults,
                              isDarkMode,
                              TextStyle(
                                fontSize: 14,
                                height: 1.4,
                                color:
                                    isDarkMode
                                        ? AppColors.textPrimaryDark
                                        : AppColors.textPrimary,
                              ),
                            ),
                          ),
                        ),

                        // Sources button (only if there are search results)
                        if (widget.message.searchResults.isNotEmpty)
                          _buildSourcesButton(context, isDarkMode),
                      ],
                    ),
          ),
        ],
      ),
    );
  }
}
