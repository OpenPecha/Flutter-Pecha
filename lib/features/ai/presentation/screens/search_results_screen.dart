import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/theme/app_colors.dart';
import 'package:flutter_pecha/features/ai/data/models/search_state.dart';
import 'package:flutter_pecha/features/ai/presentation/controllers/chat_controller.dart';
import 'package:flutter_pecha/features/ai/presentation/controllers/search_state_controller.dart';
import 'package:flutter_pecha/features/ai/presentation/widgets/all_tab_view.dart';
import 'package:flutter_pecha/features/ai/presentation/widgets/author_tab_view.dart';
import 'package:flutter_pecha/features/ai/presentation/widgets/contents_tab_view.dart';
import 'package:flutter_pecha/features/ai/presentation/widgets/titles_tab_view.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_pecha/core/extensions/context_ext.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class SearchResultsScreen extends ConsumerStatefulWidget {
  final String initialQuery;

  const SearchResultsScreen({super.key, required this.initialQuery});

  @override
  ConsumerState<SearchResultsScreen> createState() =>
      _SearchResultsScreenState();
}

class _SearchResultsScreenState extends ConsumerState<SearchResultsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late TextEditingController _searchController;
  late FocusNode _searchFocusNode;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 5,
      vsync: this,
      initialIndex: 1, // Start with "All"
    );
    _searchController = TextEditingController(text: widget.initialQuery);
    _searchFocusNode = FocusNode();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(searchStateProvider.notifier).search(widget.initialQuery);
    });

    _tabController.addListener(_onTabChanged);
  }

  void _onTabChanged() {
    if (!_tabController.indexIsChanging) {
      final tab = SearchTab.values[_tabController.index];
      if (tab == SearchTab.aiMode) {
        _navigateToAiMode();
      } else {
        ref.read(searchStateProvider.notifier).switchTab(tab);
      }
    }
  }

  void _navigateToAiMode() {
    final query = ref.read(searchStateProvider).currentQuery;
    // Set flag to switch AI screen to AI mode
    ref.read(searchStateProvider.notifier).setSwitchToAiMode(true);
    context.pop();
    Future.delayed(const Duration(milliseconds: 100), () {
      ref.read(chatControllerProvider.notifier).sendMessage(query);
    });
  }

  void _onSearch() {
    final query = _searchController.text.trim();
    if (query.isNotEmpty) {
      _searchFocusNode.unfocus();
      ref.read(searchStateProvider.notifier).search(query);
    }
  }

  void _onShowMore(SearchTab tab) {
    setState(() {
      _tabController.animateTo(tab.index);
    });
  }

  void _onRetry() {
    final query = ref.read(searchStateProvider).currentQuery;
    if (query.isNotEmpty) {
      ref.read(searchStateProvider.notifier).search(query);
    }
  }

  @override
  Widget build(BuildContext context) {
    final searchState = ref.watch(searchStateProvider);
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: () {
        // Dismiss keyboard when tapping outside the TextField
        if (_searchFocusNode.hasFocus) {
          _searchFocusNode.unfocus();
        }
      },
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: _buildAppBar(isDarkMode),
        body: Column(
          children: [
            _buildTabBar(isDarkMode),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  const SizedBox.shrink(), // AI Mode Placeholder
                  AllTabView(
                    searchState: searchState,
                    onShowMore: _onShowMore,
                    onRetry: _onRetry,
                  ),
                  TitlesTabView(searchState: searchState, onRetry: _onRetry),
                  ContentsTabView(searchState: searchState, onRetry: _onRetry),
                  AuthorTabView(searchState: searchState, onRetry: _onRetry),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(bool isDarkMode) {
    return AppBar(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      elevation: 0,
      centerTitle: false,
      leadingWidth: 48,
      leading: Padding(
        padding: const EdgeInsets.only(left: 8.0),
        child: IconButton(
          icon: const Icon(PhosphorIconsRegular.arrowLeft, size: 20),
          onPressed: () => context.pop(),
          color: isDarkMode ? AppColors.surfaceWhite : AppColors.textPrimary,
        ),
      ),
      titleSpacing: 0,
      title: Container(
        height: 44,
        margin: const EdgeInsets.only(right: 16),
        decoration: BoxDecoration(
          color: isDarkMode ? AppColors.grey900 : AppColors.grey100,
          borderRadius: BorderRadius.circular(12),
        ),
        child: TextField(
          controller: _searchController,
          focusNode: _searchFocusNode,
          textInputAction: TextInputAction.search,
          onSubmitted: (_) => _onSearch(),
          onChanged:
              (_) => setState(() {}), // Rebuild to show/hide clear button
          textAlignVertical: TextAlignVertical.center,
          style: TextStyle(
            color: isDarkMode ? AppColors.surfaceWhite : AppColors.textPrimary,
            fontSize: 15,
          ),
          decoration: InputDecoration(
            hintText: context.l10n.search_buddhist_texts,
            hintStyle: TextStyle(
              color: isDarkMode ? AppColors.grey600 : AppColors.grey500,
              fontSize: 15,
            ),
            prefixIcon: Icon(
              Icons.search,
              size: 20,
              color: isDarkMode ? AppColors.grey500 : AppColors.grey600,
            ),
            suffixIcon:
                _searchController.text.isNotEmpty
                    ? IconButton(
                      icon: Icon(
                        Icons.close,
                        size: 20,
                        color:
                            isDarkMode ? AppColors.grey500 : AppColors.grey600,
                      ),
                      onPressed: () {
                        setState(() {
                          _searchController.clear();
                        });
                        _searchFocusNode.unfocus();
                      },
                    )
                    : null,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12),
          ),
        ),
      ),
    );
  }

  Widget _buildTabBar(bool isDarkMode) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: isDarkMode ? AppColors.grey800 : AppColors.grey300,
            width: 1,
          ),
        ),
      ),
      child: TabBar(
        controller: _tabController,
        isScrollable: true,
        // KEY FIX: This aligns tabs to the start (left) of the screen
        tabAlignment: TabAlignment.start,
        labelColor: AppColors.accentGold,
        unselectedLabelColor:
            isDarkMode ? AppColors.grey400 : AppColors.grey600,
        indicatorColor: AppColors.accentGold,
        indicatorWeight: 3,
        indicatorSize:
            TabBarIndicatorSize.label, // Indicator matches text width
        dividerColor:
            Colors.transparent, // Removes the default Material 3 divider
        labelPadding: const EdgeInsets.symmetric(horizontal: 25),
        labelStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.2,
        ),
        unselectedLabelStyle: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        tabs: [
          Tab(text: context.l10n.search_tab_ai_mode),
          Tab(text: context.l10n.search_all),
          Tab(text: context.l10n.search_titles),
          Tab(text: context.l10n.search_contents),
          Tab(text: context.l10n.search_author),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }
}
