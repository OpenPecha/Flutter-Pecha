import 'package:flutter/material.dart';
import 'package:flutter_pecha/features/connect/presentation/widgets/connect_my_discover_tab.dart';

/// Waits for the first My-segment fetch to settle, then mounts
/// [ConnectMyDiscoverTab] on the correct segment with no switch animation.
class ConnectMyDiscoverTabGate extends StatefulWidget {
  const ConnectMyDiscoverTabGate({
    super.key,
    required this.myHasLoaded,
    required this.myIsEmpty,
    required this.myHasError,
    required this.onSegmentChanged,
    required this.myBuilder,
    required this.discoverBuilder,
    this.onMyRefresh,
    this.onDiscoverRefresh,
    this.onMyLoadMore,
    this.onDiscoverLoadMore,
  });

  final bool myHasLoaded;
  final bool myIsEmpty;
  final bool myHasError;
  final ValueChanged<int> onSegmentChanged;
  final ConnectSegmentChildBuilder myBuilder;
  final ConnectSegmentChildBuilder discoverBuilder;
  final Future<void> Function()? onMyRefresh;
  final Future<void> Function()? onDiscoverRefresh;
  final VoidCallback? onMyLoadMore;
  final VoidCallback? onDiscoverLoadMore;

  @override
  State<ConnectMyDiscoverTabGate> createState() =>
      _ConnectMyDiscoverTabGateState();
}

class _ConnectMyDiscoverTabGateState extends State<ConnectMyDiscoverTabGate> {
  bool _ready = false;
  int _initialSegment = 0;

  @override
  void initState() {
    super.initState();
    _maybeReveal();
  }

  @override
  void didUpdateWidget(ConnectMyDiscoverTabGate oldWidget) {
    super.didUpdateWidget(oldWidget);
    _maybeReveal();
  }

  void _maybeReveal() {
    if (_ready || !widget.myHasLoaded) return;
    _ready = true;
    _initialSegment = !widget.myHasError && widget.myIsEmpty ? 1 : 0;
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready) {
      return const Center(child: CircularProgressIndicator());
    }

    return ConnectMyDiscoverTab(
      initialSegment: _initialSegment,
      onSegmentChanged: widget.onSegmentChanged,
      onMyRefresh: widget.onMyRefresh,
      onDiscoverRefresh: widget.onDiscoverRefresh,
      onMyLoadMore: widget.onMyLoadMore,
      onDiscoverLoadMore: widget.onDiscoverLoadMore,
      myBuilder: widget.myBuilder,
      discoverBuilder: widget.discoverBuilder,
    );
  }
}
