import 'package:flutter_pecha/core/utils/app_logger.dart';
import 'package:flutter_pecha/features/texts/models/text/commentary_text.dart';

final _logger = AppLogger('CommentaryTextResponse');

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
      _logger.error('Failed to load commentary text', e);
      throw Exception('Failed to load commentary text');
    }
  }

  Map<String, dynamic> toJson() {
    return {'commentaries': commentaries.map((e) => e.toJson()).toList()};
  }

  /// Factory to reconstruct from cached JSON (Map format from toJson)
  factory CommentaryTextResponse.fromCacheJson(Map<String, dynamic> json) {
    final list = json['commentaries'] as List<dynamic>;
    return CommentaryTextResponse(
      commentaries:
          list
              .map((e) => CommentaryText.fromJson(e as Map<String, dynamic>))
              .toList(),
    );
  }
}
