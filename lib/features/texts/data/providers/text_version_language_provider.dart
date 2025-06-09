import 'package:flutter_riverpod/flutter_riverpod.dart';

class TextVersionLanguageNotifier extends StateNotifier<String> {
  TextVersionLanguageNotifier() : super('en');

  void setLanguage(String language) {
    state = language;
  }
}

final textVersionLanguageProvider =
    StateNotifierProvider<TextVersionLanguageNotifier, String>((ref) {
      return TextVersionLanguageNotifier();
    });
