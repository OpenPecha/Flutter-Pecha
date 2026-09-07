import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/theme/app_colors.dart';
import 'package:flutter_pecha/features/practice/presentation/screens/create_collection_screen.dart';

Future<void> showNewCollectionDialog(BuildContext context) {
  return showDialog<void>(
    context: context,
    barrierDismissible: true,
    builder: (_) => const NewCollectionDialog(),
  );
}

class NewCollectionDialog extends StatefulWidget {
  const NewCollectionDialog({super.key});

  @override
  State<NewCollectionDialog> createState() => _NewCollectionDialogState();
}

class _NewCollectionDialogState extends State<NewCollectionDialog> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    _focusNode = FocusNode();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onCancel() => Navigator.of(context).pop();

  void _onCreate() {
    final name = _controller.text.trim();
    if (name.isEmpty) return;

    final navigator = Navigator.of(context);
    navigator.pop();
    navigator.push(
      MaterialPageRoute(
        builder: (_) => CreateCollectionScreen(initialName: name),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor =
        isDark ? AppColors.cardBackgroundDark : AppColors.surfaceWhite;
    final titleColor =
        isDark ? AppColors.textPrimaryDark : AppColors.textPrimary;
    final cancelColor =
        isDark ? AppColors.textPrimaryDark : AppColors.textPrimary;
    final createBackground =
        isDark ? AppColors.surfaceWhite : AppColors.textPrimary;
    final createForeground =
        isDark ? AppColors.textPrimary : AppColors.onPrimary;
    final fieldBorder = isDark ? AppColors.cardBorderDark : AppColors.grey900;
    final fieldFill = isDark ? AppColors.surfaceDark : AppColors.surfaceWhite;

    return Dialog(
      backgroundColor: cardColor,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 28),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'New Collection',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: titleColor,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _controller,
              focusNode: _focusNode,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _onCreate(),
              style: TextStyle(fontSize: 15, color: titleColor),
              decoration: InputDecoration(
                isDense: true,
                filled: true,
                fillColor: fieldFill,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 14,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: fieldBorder, width: 1),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: fieldBorder, width: 1),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: fieldBorder, width: 1.5),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: _onCancel,
                  style: TextButton.styleFrom(
                    foregroundColor: cancelColor,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Material(
                  color: createBackground,
                  shape: const StadiumBorder(),
                  child: InkWell(
                    onTap: _onCreate,
                    customBorder: const StadiumBorder(),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                      child: Text(
                        'Create',
                        style: TextStyle(
                          color: createForeground,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
