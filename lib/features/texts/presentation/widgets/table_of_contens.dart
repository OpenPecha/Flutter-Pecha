import 'package:flutter/material.dart';
import 'package:flutter_pecha/features/texts/models/section.dart';
import 'package:flutter_pecha/features/texts/models/text/toc_response.dart';
import 'package:flutter_pecha/shared/utils/helper_functions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class TableOfContents extends ConsumerStatefulWidget {
  final TocResponse toc;

  const TableOfContents({super.key, required this.toc});

  @override
  ConsumerState<TableOfContents> createState() => _TableOfContentsState();
}

class _TableOfContentsState extends ConsumerState<TableOfContents> {
  final Map<String, bool> expandedSections = {};

  void toggleSection(String sectionId) {
    setState(() {
      expandedSections[sectionId] = !(expandedSections[sectionId] ?? false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final contents = widget.toc.contents;
    if (contents.isEmpty) {
      return const Center(child: Text('No content found'));
    }
    return ListView(
      children: [
        for (final content in contents)
          for (final section in content.sections)
            _buildContentTree(section, content.id, content.textId, context),
      ],
    );
  }

  Widget _buildContentTree(
    Section section,
    String tocId,
    String textId,
    BuildContext context,
  ) {
    final language = widget.toc.textDetail.language;
    final isExpanded = expandedSections[section.id] ?? false;
    final hasChildren =
        section.sections != null && section.sections!.isNotEmpty;

    Widget buildTitle(bool tappable) {
      final segmentId =
          hasChildren
              ? section.sections!.first.segments.first.segmentId
              : section.segments.first.segmentId;
      final titleWidget = Padding(
        padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
        child: Text(
          section.title ?? '',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            fontFamily: getFontFamily(language),
          ),
        ),
      );
      if (!tappable) return titleWidget;
      return GestureDetector(
        onTap: () {
          context.push(
            '/texts/chapters',
            extra: {
              'textId': textId,
              'contentId': tocId,
              'segmentId': segmentId,
            },
          );
        },
        child: titleWidget,
      );
    }

    Widget buildDropIcon() {
      if (!hasChildren) return const SizedBox(width: 24);
      return Icon(
        isExpanded ? Icons.keyboard_arrow_down : Icons.chevron_right,
        size: 20,
      );
    }

    Widget buildChildren() {
      if (!isExpanded || !hasChildren) return const SizedBox.shrink();
      return Padding(
        padding: const EdgeInsets.only(left: 10.0),
        child: Column(
          children: [
            for (final child in section.sections!)
              _buildContentTree(child, tocId, textId, context),
          ],
        ),
      );
    }

    if (hasChildren) {
      // Section is expandable: InkWell for expand/collapse, title is not separately tappable
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InkWell(
              onTap: () => toggleSection(section.id),
              child: Row(
                children: [
                  buildDropIcon(),
                  const SizedBox(width: 6),
                  buildTitle(false),
                ],
              ),
            ),
            buildChildren(),
          ],
        ),
      );
    } else {
      // Section is not expandable: only title is tappable for navigation
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: buildTitle(true),
      );
    }
  }
}
