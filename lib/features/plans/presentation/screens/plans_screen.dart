import 'package:flutter/material.dart';
import 'package:flutter_pecha/features/plans/presentation/widgets/find_plan_tab.dart';
import 'package:flutter_pecha/features/plans/presentation/widgets/my_plan_tab.dart';
import 'package:flutter_pecha/features/plans/presentation/search/plan_search_delegate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class PlansScreen extends ConsumerStatefulWidget {
  const PlansScreen({super.key});

  @override
  ConsumerState<PlansScreen> createState() => _PlansScreenState();
}

class _PlansScreenState extends ConsumerState<PlansScreen>
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
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Plans',
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
                      delegate: PlanSearchDelegate(ref: ref),
                    );
                  },
                  icon: const Icon(Icons.search),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: [Tab(text: 'My Plans'), Tab(text: 'All Plans')],
          labelStyle: TextStyle(fontWeight: FontWeight.bold),
          unselectedLabelStyle: TextStyle(fontWeight: FontWeight.bold),
          labelColor: Theme.of(context).colorScheme.secondary,
          unselectedLabelColor:
              Theme.of(context).brightness == Brightness.dark
                  ? Colors.white
                  : Colors.black,
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          MyPlansTab(controller: _tabController),
          FindPlansTab(controller: _tabController),
        ],
      ),
    );
  }
}
