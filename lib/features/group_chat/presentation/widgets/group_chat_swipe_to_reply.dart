import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_pecha/core/constants/app_assets.dart';
import 'package:flutter_pecha/core/theme/app_colors.dart';

/// Drag a message towards the end of the row to reply to it, as in WhatsApp.
///
/// The row follows the finger up to [_maxDrag] and always springs back —
/// nothing is dismissed. Passing [_triggerAt] fires [onReply] once, on
/// release, with a haptic tick so the threshold is felt rather than guessed.
class GroupChatSwipeToReply extends StatefulWidget {
  const GroupChatSwipeToReply({
    super.key,
    required this.child,
    required this.onReply,
  });

  final Widget child;
  final VoidCallback onReply;

  @override
  State<GroupChatSwipeToReply> createState() => _GroupChatSwipeToReplyState();
}

class _GroupChatSwipeToReplyState extends State<GroupChatSwipeToReply>
    with SingleTickerProviderStateMixin {
  static const double _maxDrag = 72;
  static const double _triggerAt = 52;

  /// Built in [initState] rather than as a lazy `late final` initialiser.
  ///
  /// [build] never reads this field — only [_offset] and [_settling] — so a row
  /// that is never swiped never creates it, and [dispose] becomes the *first*
  /// read. The initialiser would then run during unmount, and building a
  /// ticker there looks up `TickerMode` on an element that is already
  /// deactivated: "Looking up a deactivated widget's ancestor is unsafe".
  /// Every row scrolling out of the thread threw, which tore down the list.
  late final AnimationController _controller;

  Animation<double> _settle = const AlwaysStoppedAnimation(0);
  double _offset = 0;
  bool _settling = false;

  /// Whether the haptic for this gesture has already fired, so holding past
  /// the threshold does not buzz repeatedly.
  bool _armed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 180),
    )..addListener(() {
      if (_settling) setState(() => _offset = _settle.value);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onDragUpdate(DragUpdateDetails details) {
    _settling = false;
    final next = (_offset + details.delta.dx).clamp(0.0, _maxDrag);
    if (next >= _triggerAt && !_armed) {
      _armed = true;
      HapticFeedback.mediumImpact();
    } else if (next < _triggerAt) {
      _armed = false;
    }
    setState(() => _offset = next);
  }

  void _onDragEnd(DragEndDetails details) {
    final shouldReply = _offset >= _triggerAt;
    _armed = false;
    _springBack();
    if (shouldReply) widget.onReply();
  }

  void _springBack() {
    _settle = Tween<double>(
      begin: _offset,
      end: 0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _settling = true;
    _controller.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final progress = (_offset / _triggerAt).clamp(0.0, 1.0);

    return GestureDetector(
      // Horizontal only: the list keeps the vertical axis, and the gesture
      // arena hands each drag to whichever direction it commits to.
      onHorizontalDragUpdate: _onDragUpdate,
      onHorizontalDragEnd: _onDragEnd,
      onHorizontalDragCancel: _springBack,
      child: Stack(
        children: [
          if (_offset > 0)
            Positioned.fill(
              child: Align(
                alignment: AlignmentDirectional.centerStart,
                child: Padding(
                  padding: const EdgeInsets.only(left: 16),
                  child: Opacity(
                    opacity: progress,
                    child: Transform.scale(
                      scale: 0.7 + 0.3 * progress,
                      child: Icon(
                        AppAssets.arrowBendUpLeft,
                        size: 20,
                        color:
                            isDark
                                ? AppColors.textTertiaryDark
                                : AppColors.textSecondary,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          Transform.translate(offset: Offset(_offset, 0), child: widget.child),
        ],
      ),
    );
  }
}
