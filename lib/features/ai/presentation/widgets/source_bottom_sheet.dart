import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/theme/app_colors.dart';
import 'package:flutter_pecha/features/ai/data/models/chat_message.dart';
import 'package:flutter_pecha/features/ai/presentation/providers/segment_url_resolver_provider.dart';
import 'package:flutter_pecha/features/reader/data/models/navigation_context.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_pecha/core/extensions/context_ext.dart';

class SourceBottomSheet extends ConsumerStatefulWidget {
  final SearchResult source;
  final int citationNumber;

  const SourceBottomSheet({
    super.key,
    required this.source,
    required this.citationNumber,
  });

  /// Static method to show the bottom sheet
  static void show(
    BuildContext context,
    SearchResult source,
    int citationNumber,
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
          (context) =>
              SourceBottomSheet(source: source, citationNumber: citationNumber),
    ).then((_) {
      // Prevent keyboard from popping up after modal closes
      // ignore: use_build_context_synchronously
      FocusScope.of(context).unfocus();
    });
  }

  @override
  ConsumerState<SourceBottomSheet> createState() => _SourceBottomSheetState();
}

class _SourceBottomSheetState extends ConsumerState<SourceBottomSheet> {
  bool _isLoading = false;

  /// Handle source click - resolve URL and navigate
  Future<void> _handleNavigateToChapter() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Get the repository
      final repository = ref.read(segmentUrlResolverRepositoryProvider);

      // Call API to resolve segment URL
      final result = await repository.resolveSegmentUrl(widget.source.id);

      // Check if widget is still mounted before navigation
      if (!mounted) return;
      final textId = result['textId'];
      final segmentId = result['segmentId'];

      // Close the bottom sheet first
      Navigator.of(context).pop();

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
                localizations.ai_text_not_found_message(widget.source.title),
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
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDarkMode ? AppColors.surfaceDark : Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
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
                  color: isDarkMode ? AppColors.grey500 : AppColors.grey400,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              const SizedBox(height: 12),

              // Content - Make entire area clickable
              Expanded(
                child: Stack(
                  children: [
                    InkWell(
                      onTap: _isLoading ? null : _handleNavigateToChapter,
                      child: SingleChildScrollView(
                        controller: scrollController,
                        padding: const EdgeInsets.all(20),
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            minHeight: MediaQuery.of(context).size.height * 0.3,
                            minWidth: double.infinity,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Title
                              Text(
                                widget.source.title,
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w500,
                                  color:
                                      isDarkMode
                                          ? AppColors.textPrimaryDark
                                          : AppColors.textPrimary,
                                  height: 1.4,
                                ),
                              ),
                              const SizedBox(height: 16),

                              Text(
                                widget.source.text,
                                style: TextStyle(
                                  fontSize: 16,
                                  height: 1.6,
                                  color:
                                      isDarkMode
                                          ? AppColors.textSecondaryDark
                                          : AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // Loading overlay
                    if (_isLoading)
                      Container(
                        color: (isDarkMode ? Colors.black : Colors.white)
                            .withValues(alpha: 0.7),
                        child: const Center(
                          child: CircularProgressIndicator(
                            color: AppColors.accentGold,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
