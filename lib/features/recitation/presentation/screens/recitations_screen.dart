import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/l10n/generated/app_localizations.dart';
import 'package:flutter_pecha/core/theme/app_colors.dart';
import 'package:flutter_pecha/features/recitation/presentation/widgets/my_recitations_tab.dart';
import 'package:flutter_pecha/features/recitation/presentation/widgets/recitations_tab.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class RecitationsScreen extends ConsumerStatefulWidget {
  const RecitationsScreen({super.key});

  @override
  ConsumerState<RecitationsScreen> createState() => _RecitationsScreenState();
}

class _RecitationsScreenState extends ConsumerState<RecitationsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  bool _isSearchVisible = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(context, localizations),
            // if (_isSearchVisible)
            _buildSearchBar(context, localizations),
            _buildTabBar(context, localizations),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: const [RecitationsTab(), MyRecitationsTab()],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context, AppLocalizations localizations) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Recitations',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
          ),
          IconButton(
            onPressed: () {
              setState(() {
                _isSearchVisible = !_isSearchVisible;
                if (!_isSearchVisible) {
                  _searchController.clear();
                }
              });
            },
            icon: Icon(_isSearchVisible ? Icons.close : Icons.search, size: 24),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context, AppLocalizations localizations) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
      child: Container(
        height: 40,
        decoration: BoxDecoration(
          color: const Color(0xFFFCF2F2),
          borderRadius: BorderRadius.circular(11),
        ),
        child: TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: 'Search',
            hintStyle: const TextStyle(color: Color(0xFF707070), fontSize: 12),
            prefixIcon: const Icon(
              Icons.search,
              color: Color(0xFF707070),
              size: 20,
            ),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 10,
            ),
          ),
          style: const TextStyle(fontSize: 14),
          onChanged: (value) {
            // TODO: Implement search functionality
          },
        ),
      ),
    );
  }

  Widget _buildTabBar(BuildContext context, AppLocalizations localizations) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
      child: Row(
        children: [
          _buildTabButton(
            context: context,
            label: 'Recitations',
            tabIndex: 0,
            onTap: () {
              _tabController.animateTo(0);
            },
          ),
          const SizedBox(width: 9),
          _buildTabButton(
            context: context,
            label: 'My Recitations',
            tabIndex: 1,
            onTap: () {
              _tabController.animateTo(1);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton({
    required BuildContext context,
    required String label,
    required int tabIndex,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedBuilder(
        animation: _tabController,
        builder: (context, child) {
          final isSelected = _tabController.index == tabIndex;
          return Container(
            height: 34,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.primary : const Color(0xFFFAE6E6),
              borderRadius: BorderRadius.circular(4),
            ),
            alignment: Alignment.center,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: isSelected ? Colors.white : AppColors.primary,
              ),
            ),
          );
        },
      ),
    );
  }
}
