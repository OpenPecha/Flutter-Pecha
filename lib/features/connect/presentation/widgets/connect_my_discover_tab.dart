import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/extensions/context_ext.dart';
import 'package:flutter_pecha/features/connect/presentation/widgets/connect_segmented_control.dart';

typedef ConnectSegmentChildBuilder =
    Widget Function(
      BuildContext context,
      ScrollController scrollController,
      VoidCallback switchToDiscover,
    );

/// Shared My / Discover segmented tab scaffold with dual scroll controllers
/// and threshold-based pagination.
class ConnectMyDiscoverTab extends StatefulWidget {
  const ConnectMyDiscoverTab({
    super.key,
    required this.myBuilder,
    required this.discoverBuilder,
    this.onMyRefresh,
    this.onDiscoverRefresh,
    this.onMyLoadMore,
    this.onDiscoverLoadMore,
    this.onSegmentChanged,
  });

  final ConnectSegmentChildBuilder myBuilder;
  final ConnectSegmentChildBuilder discoverBuilder;
  final Future<void> Function()? onMyRefresh;
  final Future<void> Function()? onDiscoverRefresh;
  final VoidCallback? onMyLoadMore;
  final VoidCallback? onDiscoverLoadMore;
  final ValueChanged<int>? onSegmentChanged;

  @override
  State<ConnectMyDiscoverTab> createState() => _ConnectMyDiscoverTabState();
}

class _ConnectMyDiscoverTabState extends State<ConnectMyDiscoverTab> {
  static const _paginationThreshold = 200.0;

  int _selectedSegment = 0;
  final ScrollController _myScrollController = ScrollController();
  final ScrollController _discoverScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    if (widget.onMyLoadMore != null) {
      _myScrollController.addListener(_onMyScroll);
    }
    if (widget.onDiscoverLoadMore != null) {
      _discoverScrollController.addListener(_onDiscoverScroll);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.onSegmentChanged?.call(_selectedSegment);
    });
  }

  @override
  void dispose() {
    if (widget.onMyLoadMore != null) {
      _myScrollController.removeListener(_onMyScroll);
    }
    if (widget.onDiscoverLoadMore != null) {
      _discoverScrollController.removeListener(_onDiscoverScroll);
    }
    _myScrollController.dispose();
    _discoverScrollController.dispose();
    super.dispose();
  }

  void _onMyScroll() => _onScroll(_myScrollController, widget.onMyLoadMore);

  void _onDiscoverScroll() =>
      _onScroll(_discoverScrollController, widget.onDiscoverLoadMore);

  void _onScroll(ScrollController controller, VoidCallback? loadMore) {
    if (loadMore == null || !controller.hasClients) return;
    if (controller.position.pixels <
        controller.position.maxScrollExtent - _paginationThreshold) {
      return;
    }
    loadMore();
  }

  void _switchToDiscover() => _selectSegment(1);

  void _selectSegment(int index) {
    if (_selectedSegment == index) return;
    setState(() => _selectedSegment = index);
    widget.onSegmentChanged?.call(index);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
          child: ConnectSegmentedControl(
            segments: [
              context.l10n.connect_segment_my,
              context.l10n.connect_segment_discover,
            ],
            selectedIndex: _selectedSegment,
            onChanged: _selectSegment,
          ),
        ),
        Expanded(
          child: IndexedStack(
            index: _selectedSegment,
            children: [
              RefreshIndicator(
                onRefresh: widget.onMyRefresh ?? () async {},
                child: widget.myBuilder(
                  context,
                  _myScrollController,
                  _switchToDiscover,
                ),
              ),
              RefreshIndicator(
                onRefresh: widget.onDiscoverRefresh ?? () async {},
                child: widget.discoverBuilder(
                  context,
                  _discoverScrollController,
                  _switchToDiscover,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
