import 'package:flutter/material.dart';
import 'package:flutter_pecha/features/app/presentation/pecha_bottom_nav_bar.dart';
import 'package:flutter_pecha/features/texts/data/providers/texts_provider.dart';
import 'package:flutter_pecha/features/texts/models/section.dart';
import 'package:flutter_pecha/features/texts/models/texts.dart';
import 'package:flutter_pecha/features/texts/models/version.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class TextTocScreen extends ConsumerWidget {
  const TextTocScreen({super.key, required this.text});
  final Texts text;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textContent = ref.watch(textContentFutureProvider(text.id));
    final textVersion = ref.watch(textVersionFutureProvider(text.id));

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios),
            onPressed: () => Navigator.pop(context),
          ),
          toolbarHeight: 40,
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(2),
            child: Container(height: 2, color: const Color(0xFFB6D7D7)),
          ),
        ),
        body: Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      text.title,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const Icon(Icons.menu_book_outlined, size: 22),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                text.type.toLowerCase() == "root_text"
                    ? "Root Text"
                    : "Commentary Text",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[600],
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: 160,
                height: 40,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFC6A04D),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: () {
                    // TODO: handle start reading
                  },
                  child: const Text(
                    'Start Reading',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 22),
              TabBar(
                labelColor: Theme.of(context).textTheme.bodyMedium?.color,
                unselectedLabelColor: Colors.grey,
                indicatorColor: Color(0xFFC6A04D),
                indicatorWeight: 2.5,
                tabs: [Tab(text: 'Contents'), Tab(text: 'Versions')],
                dividerColor: Color(0xFFDEE2E6),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: TabBarView(
                  children: [
                    // Contents Tab
                    textContent.when(
                      loading:
                          () =>
                              const Center(child: CircularProgressIndicator()),
                      error:
                          (error, stackTrace) =>
                              Center(child: Text(error.toString())),
                      data: (sections) => _buildContentsTab(sections),
                    ),
                    // Versions Tab
                    textVersion.when(
                      loading:
                          () =>
                              const Center(child: CircularProgressIndicator()),
                      error:
                          (error, stackTrace) =>
                              Center(child: Text(error.toString())),
                      data: (versions) => _buildVersionsTab(versions),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        bottomNavigationBar: PechaBottomNavBar(),
      ),
    );
  }

  Widget _buildContentsTab(List<Section> sections) {
    if (sections.isEmpty) {
      return const Center(child: Text('No contents found'));
    }
    return GridView.builder(
      padding: EdgeInsets.zero,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 5,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.1,
      ),
      itemCount: sections.length,
      itemBuilder: (context, idx) {
        final section = sections[idx];
        return GestureDetector(
          onTap: () {
            context.push(
              '/texts/reader',
              extra: {
                'textId': text.id,
                'section': section,
                'skip': idx.toString(),
              },
            );
          },
          child: Container(
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Center(
              child: Text(
                section.title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildVersionsTab(List<Version> versions) {
    if (versions.isEmpty) {
      return const Center(child: Text('No versions found'));
    }
    return ListView.separated(
      itemCount: versions.length,
      separatorBuilder:
          (context, idx) =>
              const Divider(height: 32, thickness: 1, color: Color(0xFFF0F0F0)),
      itemBuilder: (context, idx) {
        final version = versions[idx];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    version.title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Container(
                  margin: const EdgeInsets.only(left: 8, top: 2),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F3F3),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Text(
                    _getLanguageLabel(version.language),
                    style: const TextStyle(
                      fontSize: 15,
                      color: Colors.black87,
                      fontWeight: FontWeight.w400,
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Revision History',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade800,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        );
      },
    );
  }

  String _getLanguageLabel(String code) {
    switch (code.toLowerCase()) {
      case 'bo':
      case 'tibetan':
        return 'Tibetan';
      case 'sa':
      case 'sanskrit':
        return 'Sanskrit';
      case 'en':
      case 'english':
        return 'English';
      default:
        return code;
    }
  }
}
