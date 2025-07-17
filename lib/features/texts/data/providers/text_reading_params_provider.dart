import 'package:flutter_riverpod/flutter_riverpod.dart';

class TextReadingParams {
  final String textId;
  final String contentId;
  final String? segmentId;
  final String? sectionId;
  final String? direction;
  final String? versionId;

  const TextReadingParams({
    required this.textId,
    required this.contentId,
    this.segmentId,
    this.sectionId,
    this.direction,
    this.versionId,
  });

  TextReadingParams copyWith({
    required String textId,
    required String contentId,
    String? segmentId,
    String? sectionId,
    String? direction,
    String? versionId,
  }) {
    return TextReadingParams(
      textId: textId,
      contentId: contentId,
      segmentId: segmentId,
      sectionId: sectionId,
      direction: direction,
      versionId: versionId,
    );
  }
}

class TextReadingParamsNotifier extends StateNotifier<TextReadingParams?> {
  TextReadingParamsNotifier() : super(null);

  void setParams({
    required String textId,
    required String contentId,
    String? segmentId,
    String? sectionId,
    String? direction,
    String? versionId,
  }) {
    state = TextReadingParams(
      textId: textId,
      contentId: contentId,
      segmentId: segmentId,
      sectionId: sectionId,
      direction: direction,
      versionId: versionId,
    );
  }

  void updateParams({
    required String textId,
    required String contentId,
    String? segmentId,
    String? sectionId,
    String? direction,
    String? versionId,
  }) {
    if (state != null) {
      state = state!.copyWith(
        textId: textId,
        contentId: contentId,
        segmentId: segmentId,
        sectionId: sectionId,
        direction: direction,
        versionId: versionId,
      );
    }
  }

  void clearParams() {
    state = null;
  }
}

final textReadingParamsProvider =
    StateNotifierProvider<TextReadingParamsNotifier, TextReadingParams?>((ref) {
      return TextReadingParamsNotifier();
    });
