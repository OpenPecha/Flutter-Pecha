import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/theme/app_colors.dart';
import 'package:flutter_pecha/features/ai/models/chat_message.dart';

class SourceBottomSheet extends StatelessWidget {
  final SearchResult source;
  final int citationNumber;

  const SourceBottomSheet({
    super.key,
    required this.source,
    required this.citationNumber,
  });

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

              // Content
              Expanded(
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
                          source.title,
                          style: TextStyle(
                            fontSize: 17,
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
                          source.text,
                          style: TextStyle(
                            fontSize: 13,
                            height: 1.6,
                            color: isDarkMode ? AppColors.textSecondaryDark : AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
