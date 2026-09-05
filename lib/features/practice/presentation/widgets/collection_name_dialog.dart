import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/extensions/context_ext.dart';
import 'package:flutter_pecha/core/theme/app_colors.dart';
import 'package:flutter_pecha/features/practice/presentation/utils/collection_name_validation.dart';
import 'package:flutter_pecha/shared/domain/validators/collection_name_validator.dart';

/// Shows [CollectionNameDialog]; resolves to the sanitized name, or `null`
/// when cancelled or dismissed.
Future<String?> showCollectionNameDialog(
  BuildContext context, {
  required String title,
  required String actionLabel,
  String initialName = '',
}) {
  return showDialog<String>(
    context: context,
    barrierDismissible: true,
    builder:
        (_) => CollectionNameDialog(
          title: title,
          actionLabel: actionLabel,
          initialName: initialName,
        ),
  );
}

/// Single-field name prompt shared by "New Collection" and "Change title",
/// so both keep the same field and button styling.
class CollectionNameDialog extends StatefulWidget {
  const CollectionNameDialog({
    super.key,
    required this.title,
    required this.actionLabel,
    this.initialName = '',
  });

  final String title;
  final String actionLabel;
  final String initialName;

  @override
  State<CollectionNameDialog> createState() => _CollectionNameDialogState();
}

class _CollectionNameDialogState extends State<CollectionNameDialog> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;

  /// Shown under the field after a failed submit; cleared on the next edit.
  CollectionNameValidationError? _error;

  bool get _isValid =>
      CollectionNameValidator.validate(_controller.text) == null;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialName);
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

  void _onSubmit() {
    final error = CollectionNameValidator.validate(_controller.text);
    if (error != null) {
      setState(() => _error = error);
      return;
    }
    Navigator.of(
      context,
    ).pop(CollectionNameValidator.sanitize(_controller.text));
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
    final actionBackground =
        _isValid
            ? (isDark ? AppColors.surfaceWhite : AppColors.textPrimary)
            : (isDark ? AppColors.grey900 : AppColors.grey500);
    final actionForeground =
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
              widget.title,
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
              maxLength: CollectionNameValidator.maxLength,
              buildCounter:
                  (
                    context, {
                    required currentLength,
                    required isFocused,
                    required maxLength,
                  }) => const SizedBox.shrink(),
              onChanged: (_) => setState(() => _error = null),
              onSubmitted: (_) => _onSubmit(),
              style: TextStyle(fontSize: 15, color: titleColor),
              decoration: InputDecoration(
                isDense: true,
                errorText:
                    _error == null
                        ? null
                        : collectionNameErrorMessage(context.l10n, _error!),
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
                  child: Text(
                    context.l10n.cancel,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Material(
                  color: actionBackground,
                  shape: const StadiumBorder(),
                  child: InkWell(
                    onTap: _isValid ? _onSubmit : null,
                    customBorder: const StadiumBorder(),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 10,
                      ),
                      child: Text(
                        widget.actionLabel,
                        style: TextStyle(
                          color: actionForeground,
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
