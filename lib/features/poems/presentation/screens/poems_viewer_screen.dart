import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/config/locale/locale_notifier.dart';
import 'package:flutter_pecha/core/constants/app_assets.dart';
import 'package:flutter_pecha/core/extensions/context_ext.dart';
import 'package:flutter_pecha/core/theme/app_colors.dart';
import 'package:flutter_pecha/features/poems/presentation/providers/poems_providers.dart';
import 'package:flutter_pecha/features/poems/presentation/providers/poems_viewer_notifier.dart';
import 'package:flutter_pecha/features/poems/presentation/widgets/poem_dots_indicator.dart';
import 'package:flutter_pecha/features/poems/presentation/utils/poem_share.dart';
import 'package:flutter_pecha/features/poems/presentation/widgets/poem_story_page.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Full-screen, side-scrollable (Instagram-story-like) poems viewer.
///
/// Swiping horizontally moves between published poems; more poems are
/// fetched lazily as the reader nears the end of the loaded list.
class PoemsViewerScreen extends ConsumerStatefulWidget {
  const PoemsViewerScreen({super.key, this.initialPoemId});

  /// When set, the viewer opens on this poem (e.g. tapped from the home
  /// preview card) instead of the newest one.
  final String? initialPoemId;

  @override
  ConsumerState<PoemsViewerScreen> createState() => _PoemsViewerScreenState();
}

class _PoemsViewerScreenState extends ConsumerState<PoemsViewerScreen> {
  // How many pages from the end of the loaded list triggers the next fetch.
  static const _loadMoreThreshold = 3;

  PageController? _pageController;
  int _currentIndex = 0;
  bool _initialized = false;

  @override
  void dispose() {
    _pageController?.dispose();
    super.dispose();
  }

  void _onPageChanged(int index, PoemsViewerState state) {
    if (state.poems.isNotEmpty && _currentIndex < state.poems.length) {
      ref
          .read(
            poemViewerAppBarTitleVisibleProvider(
              state.poems[_currentIndex].id,
            ).notifier,
          )
          .state = false;
    }

    setState(() => _currentIndex = index);

    if (state.poems.isNotEmpty && index < state.poems.length) {
      ref
          .read(
            poemViewerAppBarTitleVisibleProvider(state.poems[index].id).notifier,
          )
          .state = false;
    }

    if (state.hasMore && index >= state.poems.length - _loadMoreThreshold) {
      ref.read(poemsViewerProvider(widget.initialPoemId).notifier).loadMore();
    }
  }

  void _resetForLanguageChange() {
    _pageController?.dispose();
    _pageController = null;
    _initialized = false;
    _currentIndex = 0;
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(contentLanguageProvider, (previous, next) {
      if (previous != null && previous != next) {
        _resetForLanguageChange();
      }
    });

    final state = ref.watch(poemsViewerProvider(widget.initialPoemId));

    if (!_initialized && state.hasLoaded && state.poems.isNotEmpty) {
      _initialized = true;
      _currentIndex = state.initialIndex.clamp(0, state.poems.length - 1);
      _pageController = PageController(initialPage: _currentIndex);
    }

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final backgroundColor =
        isDark
            ? AppColors.scaffoldBackgroundDark
            : AppColors.scaffoldBackgroundLight;
    final iconColor = isDark ? AppColors.textPrimaryDark : AppColors.textPrimary;
    final currentPoem =
        state.poems.isNotEmpty && _currentIndex < state.poems.length
            ? state.poems[_currentIndex]
            : null;
    final showTitleInAppBar =
        currentPoem != null
            ? ref.watch(
              poemViewerAppBarTitleVisibleProvider(currentPoem.id),
            )
            : false;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            _TopBar(
              iconColor: iconColor,
              title: currentPoem?.title,
              showTitle: showTitleInAppBar,
              onBack: () => context.canPop() ? context.pop() : context.go('/home'),
              onShare:
                  currentPoem != null
                      ? () => sharePoem(context, currentPoem)
                      : null,
            ),
            Expanded(child: _buildBody(context, state, isDark)),
            if (_pageController != null && state.poems.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: PoemDotsIndicator(
                  count: state.poems.length,
                  currentIndex: _currentIndex,
                  activeColor: iconColor,
                  inactiveColor:
                      isDark ? AppColors.grey800 : AppColors.grey300,
                  backgroundColor:
                      isDark ? AppColors.surfaceDark : AppColors.surfaceWhite,
                  borderColor:
                      isDark ? AppColors.cardBorderDark : AppColors.grey100,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context, PoemsViewerState state, bool isDark) {
    final secondaryColor =
        isDark ? AppColors.textTertiaryDark : AppColors.textSecondary;

    if (state.isLoading && state.poems.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.error != null && state.poems.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                context.l10n.poems_load_error,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 15, color: secondaryColor, height: 1.5),
              ),
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed:
                    () => ref
                        .read(poemsViewerProvider(widget.initialPoemId).notifier)
                        .loadInitial(),
                child: Text(context.l10n.retry),
              ),
            ],
          ),
        ),
      );
    }

    if (state.hasLoaded && state.poems.isEmpty) {
      return Center(
        child: Text(
          context.l10n.poems_empty,
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 15, color: secondaryColor, height: 1.5),
        ),
      );
    }

    if (_pageController == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return PageView.builder(
      controller: _pageController,
      itemCount: state.poems.length,
      onPageChanged: (index) => _onPageChanged(index, state),
      itemBuilder: (context, index) => PoemStoryPage(poem: state.poems[index]),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.iconColor,
    required this.onBack,
    this.title,
    this.showTitle = false,
    this.onShare,
  });

  final Color iconColor;
  final VoidCallback onBack;
  final String? title;
  final bool showTitle;
  final VoidCallback? onShare;

  @override
  Widget build(BuildContext context) {
    final resolvedTitle = title?.trim() ?? '';
    final hasTitle = resolvedTitle.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: Row(
        children: [
          IconButton(
            onPressed: onBack,
            icon: Icon(AppAssets.arrowLeft, color: iconColor),
          ),
          Expanded(
            child: AnimatedOpacity(
              opacity: showTitle && hasTitle ? 1 : 0,
              duration: const Duration(milliseconds: 150),
              child: Text(
                resolvedTitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: iconColor,
                ),
              ),
            ),
          ),
          IconButton(
            onPressed: onShare,
            icon: Icon(AppAssets.readerShare, color: iconColor),
            tooltip: context.l10n.share,
          ),
        ],
      ),
    );
  }
}
