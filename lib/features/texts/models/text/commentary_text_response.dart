import 'package:flutter/material.dart';
import 'package:flutter_pecha/features/texts/models/text/commentary_text.dart';

class CommentaryTextResponse {
  final List<CommentaryText> commentaries;

  CommentaryTextResponse({required this.commentaries});

  factory CommentaryTextResponse.fromJson(List<dynamic> jsonList) {
    try {
      return CommentaryTextResponse(
        commentaries:
            jsonList
                .map((e) => CommentaryText.fromJson(e as Map<String, dynamic>))
                .toList(),
      );
    } catch (e) {
      debugPrint('Failed to load commentary text: $e');
      throw Exception('Failed to load commentary text');
    }
  }

  Map<String, dynamic> toJson() {
    return {'commentaries': commentaries.map((e) => e.toJson()).toList()};
  }
}
