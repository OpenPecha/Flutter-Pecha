import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/constants/app_assets.dart';
import 'package:flutter_pecha/core/extensions/context_ext.dart';
import 'package:flutter_pecha/core/localization/content_language_picker_sheet.dart';
import 'package:flutter_pecha/core/widgets/error_state_widget.dart';
import 'package:flutter_pecha/features/practice/presentation/providers/practice_recitations_paginated_provider.dart';
import 'package:flutter_pecha/features/practice/presentation/screens/recitations_search_screen.dart';
import 'package:flutter_pecha/features/practice/presentation/utils/recitation_reader_navigation.dart';
import 'package:flutter_pecha/features/practice/presentation/widgets/practice_chant_list_tile.dart';
import 'package:flutter_pecha/features/recitation/presentation/widgets/recitation_list_skeleton.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AllRecitationsScreen extends ConsumerStatefulWidget {
  const AllRecitationsScreen({super.key});

  @override
  ConsumerState<AllRecitationsScreen> createState() =>
      _AllRecitationsScreenState();
}

class _AllRecitationsScreenState extends ConsumerState<AllRecitationsScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    final languageCode = ref.read(practiceRecitationsLanguageProvider);
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      ref
          .read(practiceRecitationsPaginatedProvider(languageCode).notifier)
          .loadMore();
    }
  }

  void _openSearch(BuildContext context, String languageCode) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => RecitationsSearchScreen(languageCode: languageCode),
      ),
    );
  }

  void _openLanguagePicker(BuildContext context, String selectedCode) {
    showContentLanguagePickerSheet(
      context,
      selectedCode: selectedCode,
      onSelected: (code) {
        ref
            .read(practiceRecitationsLanguageProvider.notifier)
            .setLanguage(code);
        if (_scrollController.hasClients) {
          _scrollController.jumpTo(0);
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final languageCode = ref.watch(practiceRecitationsLanguageProvider);
    final recitationsState = ref.watch(
      practiceRecitationsPaginatedProvider(languageCode),
    );

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(AppAssets.arrowLeft),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          l10n.home_chants,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        scrolledUnderElevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            tooltip: l10n.recitations_search_for,
            onPressed: () => _openSearch(context, languageCode),
          ),
          IconButton(
            icon: const Icon(AppAssets.language),
            tooltip: l10n.language,
            onPressed: () => _openLanguagePicker(context, languageCode),
          ),
        ],
      ),
      body: _buildBody(context, recitationsState, languageCode),
    );
  }

  Widget _buildBody(
    BuildContext context,
    PracticeRecitationsState state,
    String languageCode,
  ) {
    if (state.isLoading && state.recitations.isEmpty) {
      return const RecitationListSkeleton(
        variant: RecitationListSkeletonVariant.chantTile,
      );
    }

    if (state.error != null && state.recitations.isEmpty) {
      return ErrorStateWidget(
        error: state.error!,
        onRetry:
            () =>
                ref
                    .read(
                      practiceRecitationsPaginatedProvider(
                        languageCode,
                      ).notifier,
                    )
                    .retry(),
      );
    }

    if (state.recitations.isEmpty) {
      return Center(child: Text(context.l10n.recitations_no_content));
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.only(top: 8, bottom: 16),
      itemCount: state.recitations.length + (state.hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == state.recitations.length) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Center(
              child:
                  state.isLoadingMore
                      ? const CircularProgressIndicator()
                      : const SizedBox.shrink(),
            ),
          );
        }

        final recitation = state.recitations[index];
        return PracticeChantListTile(
          recitation: recitation,
          onTap: () => openRecitationReader(context, recitation),
        );
      },
    );
  }
}
