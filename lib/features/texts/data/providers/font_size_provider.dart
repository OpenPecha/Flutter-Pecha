import 'package:flutter_pecha/core/storage/preferences_service.dart';
import 'package:flutter_pecha/core/storage/storage_keys.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class FontSizeNotifier extends StateNotifier<double> {
  final PreferencesService _prefs;
  FontSizeNotifier(this._prefs) : super(16.0) {
    _loadFontSize();
  }

  Future<void> _loadFontSize() async {
    final fontSize = await _prefs.get<double>(StorageKeys.fontSize);
    state = fontSize ?? 16.0;
  }

  Future<void> setFontSize(double size) async {
    state = size;
    await _prefs.set(StorageKeys.fontSize, size);
  }
}

final fontSizeProvider = StateNotifierProvider<FontSizeNotifier, double>((ref) {
  return FontSizeNotifier(ref.read(preferencesServiceProvider));
});
