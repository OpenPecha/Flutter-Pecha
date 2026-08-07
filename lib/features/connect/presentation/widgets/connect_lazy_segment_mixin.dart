import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Defers Connect My/Discover provider subscriptions until the parent main
/// tab is active and the selected segment is visible.
mixin ConnectLazyMyDiscoverTabMixin<T extends ConsumerStatefulWidget>
    on ConsumerState<T> {
  int selectedSegment = 0;
  bool isTabActive = true;

  @override
  void initState() {
    super.initState();
    isTabActive = readTabActive(widget);
    if (isTabActive) {
      scheduleActiveSegmentLoad();
    }
  }

  @override
  void didUpdateWidget(covariant T oldWidget) {
    super.didUpdateWidget(oldWidget);
    final wasActive = readTabActive(oldWidget);
    final isActive = readTabActive(widget);
    if (wasActive != isActive) {
      isTabActive = isActive;
      if (isActive) {
        scheduleActiveSegmentLoad();
      } else {
        setState(() {});
      }
    }
  }

  bool readTabActive(T widget);

  void handleSegmentChanged(int segment) {
    if (selectedSegment == segment) return;
    setState(() => selectedSegment = segment);
    scheduleActiveSegmentLoad();
  }

  void scheduleActiveSegmentLoad() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !isTabActive) return;
      loadActiveSegment();
    });
  }

  void loadActiveSegment();
}
