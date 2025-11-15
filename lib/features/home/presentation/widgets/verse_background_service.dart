import 'dart:math';
import 'package:flutter_pecha/features/home/presentation/widgets/verse_card_constants.dart';

/// Service to manage verse card background image selection
class VerseBackgroundService {
  static final VerseBackgroundService _instance =
      VerseBackgroundService._internal();
  factory VerseBackgroundService() => _instance;
  VerseBackgroundService._internal();

  final Random _random = Random();
  int _currentIndex = 0;
  bool _isRandom = true;

  /// Get a random background image from the list
  String getRandomImage() {
    final images = VerseCardConstants.backgroundImages;
    if (images.isEmpty) {
      throw StateError('No background images available');
    }
    _currentIndex = _random.nextInt(images.length);
    return images[_currentIndex];
  }

  /// Get the next background image in sequence (loop through)
  String getNextImage() {
    final images = VerseCardConstants.backgroundImages;
    if (images.isEmpty) {
      throw StateError('No background images available');
    }
    _currentIndex = (_currentIndex + 1) % images.length;
    return images[_currentIndex];
  }

  /// Get a background image based on current mode (random or sequential)
  String getImage() {
    return _isRandom ? getRandomImage() : getNextImage();
  }

  /// Set the selection mode
  void setRandomMode(bool isRandom) {
    _isRandom = isRandom;
  }

  /// Reset to first image
  void reset() {
    _currentIndex = 0;
  }

  /// Get image by index (useful for consistent selection based on verse ID)
  String getImageByIndex(int index) {
    final images = VerseCardConstants.backgroundImages;
    if (images.isEmpty) {
      throw StateError('No background images available');
    }
    return images[index % images.length];
  }

  /// Get image based on verse text hash (consistent for same verse)
  String getImageForVerse(String verseText) {
    final images = VerseCardConstants.backgroundImages;
    if (images.isEmpty) {
      throw StateError('No background images available');
    }
    // Use hash code to get consistent image for same verse
    final index = verseText.hashCode.abs() % images.length;
    return images[index];
  }
}
