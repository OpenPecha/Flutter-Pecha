import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/l10n/generated/app_localizations.dart';
import 'package:flutter_pecha/features/recitation/presentation/search/recitation_search_delegate.dart';
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

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          localizations.recitations_title,
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
        ),
        scrolledUnderElevation: 0,
        centerTitle: false,
        actions: [
          AnimatedBuilder(
            animation: _tabController,
            builder: (context, child) {
              if (_tabController.index == 1) {
                return IconButton(
                  onPressed: () {
                    showSearch(
                      context: context,
                      delegate: RecitationSearchDelegate(ref: ref),
                    );
                  },
                  icon: const Icon(Icons.search),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
        bottom: _buildTabBar(context, localizations),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          MyRecitationsTab(),
          RecitationsTab(controller: _tabController),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildTabBar(
    BuildContext context,
    AppLocalizations localizations,
  ) {
    return TabBar(
      controller: _tabController,
      tabs: [
        Tab(text: localizations.recitations_my_recitations),
        Tab(text: localizations.browse_recitations),
      ],
      labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
      unselectedLabelStyle: const TextStyle(
        fontWeight: FontWeight.bold,
        fontSize: 16,
      ),
      labelColor: Theme.of(context).colorScheme.secondary,
      unselectedLabelColor:
          Theme.of(context).brightness == Brightness.dark
              ? Colors.white
              : Colors.black,
    );
  }
}
