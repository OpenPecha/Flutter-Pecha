import 'package:flutter_pecha/core/constants/app_storage_keys.dart';
import 'package:flutter_pecha/core/utils/local_storage_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class FontSizeNotifier extends StateNotifier<double> {
  final LocalStorageService _localStorageService;
  FontSizeNotifier({required LocalStorageService localStorageService})
    : _localStorageService = localStorageService,
      super(16.0) {
    _loadFontSize();
  }

  Future<void> _loadFontSize() async {
    final fontSize = await _localStorageService.get<double>(
      AppStorageKeys.fontSize,
    );
    state = fontSize ?? 16.0;
  }

  Future<void> setFontSize(double size) async {
    state = size;
    await _localStorageService.set<double>(AppStorageKeys.fontSize, size);
  }
}

final fontSizeProvider = StateNotifierProvider<FontSizeNotifier, double>((ref) {
  return FontSizeNotifier(
    localStorageService: ref.read(localStorageServiceProvider),
  );
});
