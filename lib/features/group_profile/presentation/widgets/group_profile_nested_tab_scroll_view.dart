import 'package:flutter/material.dart';

/// Scroll view body for a [NestedScrollView] tab, coordinating with the
/// pinned header via overlap injection.
class GroupProfileNestedTabScrollView extends StatelessWidget {
  final Object? pageStorageKey;
  final List<Widget> slivers;

  const GroupProfileNestedTabScrollView({
    super.key,
    this.pageStorageKey,
    required this.slivers,
  });

  /// Non-scrollable tab state centered in the remaining space.
  factory GroupProfileNestedTabScrollView.centered({
    Key? key,
    Object? pageStorageKey,
    required Widget child,
  }) {
    return GroupProfileNestedTabScrollView(
      key: key,
      pageStorageKey: pageStorageKey,
      slivers: [
        SliverFillRemaining(hasScrollBody: false, child: child),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Builder(
      builder: (context) {
        return CustomScrollView(
          key: pageStorageKey != null ? PageStorageKey(pageStorageKey) : null,
          slivers: [
            SliverOverlapInjector(
              handle: NestedScrollView.sliverOverlapAbsorberHandleFor(context),
            ),
            ...slivers,
          ],
        );
      },
    );
  }
}
