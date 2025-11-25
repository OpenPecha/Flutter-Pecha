import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/utils/get_language.dart';
import 'package:flutter_pecha/features/texts/constants/text_routes.dart';
import 'package:flutter_pecha/features/texts/models/text/commentary_text.dart';
import 'package:flutter_pecha/features/texts/constants/text_screen_constants.dart';
import 'package:flutter_pecha/features/texts/presentation/widgets/commentary_list_item.dart';
import 'package:go_router/go_router.dart';

class CommentaryTab extends StatelessWidget {
  const CommentaryTab({super.key, required this.commentaries});

  final List<CommentaryText> commentaries;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      itemCount: commentaries.length,
      padding: const EdgeInsets.only(top: 10, bottom: 10),
      separatorBuilder:
          (context, idx) => const Divider(
            height: 32,
            thickness: TextScreenConstants.thinDividerThickness,
            color: Color(0xFFF0F0F0),
          ),
      itemBuilder: (context, idx) {
        final commentary = commentaries[idx];

        return CommentaryListItem(
          commentary: commentary,
          language: commentary.language ?? '',
          languageLabel: getLanguageLabel(commentary.language ?? '', context),
          onTap: () {
            context.push(TextRoutes.chapters, extra: {'textId': commentary.id});
          },
        );
      },
    );
  }
}
