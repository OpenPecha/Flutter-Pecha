import 'dart:math' as math;

import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/theme/app_colors.dart';

/// Opens the full emoji picker behind the `+` in the reaction pill.
///
/// Modelled on WhatsApp: it rises from the bottom, closes on a swipe down, and
/// scrolls **continuously** through every category rather than paging between
/// them. The category bar jumps rather than switching pages.
///
/// Returns the chosen emoji, or null when dismissed. The API takes `emoji` as
/// a free-form string, so anything picked here is a valid reaction.
Future<String?> showChatEmojiPicker(BuildContext context) {
  final isDark = Theme.of(context).brightness == Brightness.dark;

  return showModalBottomSheet<String>(
    context: context,
    // Scroll-controlled so the sheet can own the drag: swiping down anywhere,
    // including over the grid once it is scrolled to the top, dismisses it.
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    backgroundColor: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder:
        (_) => DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.62,
          minChildSize: 0.4,
          maxChildSize: 0.95,
          builder:
              (context, scrollController) =>
                  _ChatEmojiPicker(scrollController: scrollController),
        ),
  );
}

class _ChatEmojiPicker extends StatefulWidget {
  const _ChatEmojiPicker({required this.scrollController});

  /// Supplied by [DraggableScrollableSheet] so the grid's overscroll at the top
  /// turns into a drag on the sheet itself.
  final ScrollController scrollController;

  @override
  State<_ChatEmojiPicker> createState() => _ChatEmojiPickerState();
}

class _ChatEmojiPickerState extends State<_ChatEmojiPicker> {
  static const int _columns = 8;
  static const double _barHeight = 44;

  late final List<CategoryEmoji> _categories;
  int _current = 0;

  /// Section start offsets, recomputed whenever the tile size changes.
  List<double> _offsets = const [];
  double _tileSize = 0;

  @override
  void initState() {
    super.initState();
    // The package's dataset, without its paged view. Names only drive search,
    // which this picker does not have, so the default English set is enough.
    _categories =
        defaultEmojiSet.where((category) => category.emoji.isNotEmpty).toList();
    widget.scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    widget.scrollController.removeListener(_onScroll);
    super.dispose();
  }

  void _onScroll() {
    if (_offsets.isEmpty || !widget.scrollController.hasClients) return;
    final offset = widget.scrollController.offset;
    var index = 0;
    for (var i = 0; i < _offsets.length; i++) {
      if (offset >= _offsets[i] - 1) index = i;
    }
    if (index != _current) setState(() => _current = index);
  }

  /// Every section is a uniform grid, so its extent is exact arithmetic — no
  /// measurement pass needed to know where each category starts.
  void _measure(double width) {
    final tile = width / _columns;
    if (tile == _tileSize) return;
    final offsets = <double>[];
    var running = 0.0;
    for (final category in _categories) {
      offsets.add(running);
      final rows = (category.emoji.length / _columns).ceil();
      running += rows * tile;
    }
    _tileSize = tile;
    _offsets = offsets;
  }

  void _jumpTo(int index) {
    if (index < 0 || index >= _offsets.length) return;
    setState(() => _current = index);
    widget.scrollController.animateTo(
      math.min(
        _offsets[index],
        widget.scrollController.position.maxScrollExtent,
      ),
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return LayoutBuilder(
      builder: (context, constraints) {
        _measure(constraints.maxWidth);

        return Column(
          children: [
            Expanded(
              child: CustomScrollView(
                controller: widget.scrollController,
                slivers: [
                  for (final category in _categories)
                    SliverGrid(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: _columns,
                          ),
                      delegate: SliverChildBuilderDelegate((context, index) {
                        final emoji = category.emoji[index];
                        return _EmojiCell(
                          emoji: emoji.emoji,
                          size: _tileSize,
                          onTap: () => Navigator.of(context).pop(emoji.emoji),
                        );
                      }, childCount: category.emoji.length),
                    ),
                  const SliverToBoxAdapter(child: SizedBox(height: 12)),
                ],
              ),
            ),
            _CategoryBar(
              categories: _categories,
              current: _current,
              isDark: isDark,
              onSelected: _jumpTo,
            ),
          ],
        );
      },
    );
  }
}

class _EmojiCell extends StatelessWidget {
  const _EmojiCell({
    required this.emoji,
    required this.size,
    required this.onTap,
  });

  final String emoji;
  final double size;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkResponse(
      onTap: onTap,
      child: Center(
        child: Text(emoji, style: TextStyle(fontSize: size * 0.58)),
      ),
    );
  }
}

class _CategoryBar extends StatelessWidget {
  const _CategoryBar({
    required this.categories,
    required this.current,
    required this.isDark,
    required this.onSelected,
  });

  final List<CategoryEmoji> categories;
  final int current;
  final bool isDark;
  final ValueChanged<int> onSelected;

  static const _icons = CategoryIcons();

  static IconData _iconFor(Category category) {
    return switch (category) {
      Category.RECENT => _icons.recentIcon,
      Category.SMILEYS => _icons.smileyIcon,
      Category.ANIMALS => _icons.animalIcon,
      Category.FOODS => _icons.foodIcon,
      Category.ACTIVITIES => _icons.activityIcon,
      Category.TRAVEL => _icons.travelIcon,
      Category.OBJECTS => _icons.objectIcon,
      Category.SYMBOLS => _icons.symbolIcon,
      Category.FLAGS => _icons.flagIcon,
    };
  }

  @override
  Widget build(BuildContext context) {
    final selected = isDark ? AppColors.textPrimaryDark : AppColors.textPrimary;
    final muted = isDark ? AppColors.grey600 : AppColors.grey500;

    return Container(
      height: _ChatEmojiPickerState._barHeight,
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: isDark ? AppColors.cardBorderDark : AppColors.grey100,
          ),
        ),
      ),
      child: Row(
        children: [
          for (var i = 0; i < categories.length; i++)
            Expanded(
              child: InkResponse(
                onTap: () => onSelected(i),
                child: Icon(
                  _iconFor(categories[i].category),
                  size: 20,
                  color: i == current ? selected : muted,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
