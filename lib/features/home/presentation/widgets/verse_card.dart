import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/config/locale_provider.dart';
import 'package:flutter_pecha/features/texts/models/term/term.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class VerseCard extends ConsumerWidget {
  final String verse;
  final String? author;

  const VerseCard({super.key, required this.verse, this.author});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeProvider);
    final languageCode = locale?.languageCode;
    final isZh = languageCode == 'zh';
    return GestureDetector(
      onTap: () {
        if (isZh) {
          context.push(
            '/texts/detail',
            extra: Term(
              id: "687f0df34ac5cefce51678aa",
              title: "卓玛祈祷",
              description: "",
              slug: "dolma",
              hasChild: false,
            ),
          );
        }
      },
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.brown[700],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                verse,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 8),
              // add a author text
              if (author != null && author!.isNotEmpty)
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    '$author',
                    style: TextStyle(color: Colors.white, fontSize: 10),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
