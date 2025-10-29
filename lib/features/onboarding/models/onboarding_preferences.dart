/// Model for storing user preferences collected during onboarding
class OnboardingPreferences {
  const OnboardingPreferences({
    this.familiarityLevel,
    this.preferredLanguage,
    this.selectedPaths,
  });

  final String? familiarityLevel;
  final String? preferredLanguage;
  final List<String>? selectedPaths;

  /// Creates a copy with the specified fields replaced with new values
  OnboardingPreferences copyWith({
    String? familiarityLevel,
    String? preferredLanguage,
    List<String>? selectedPaths,
  }) {
    return OnboardingPreferences(
      familiarityLevel: familiarityLevel ?? this.familiarityLevel,
      preferredLanguage: preferredLanguage ?? this.preferredLanguage,
      selectedPaths: selectedPaths ?? this.selectedPaths,
    );
  }

  /// Converts to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'familiarityLevel': familiarityLevel,
      'preferredLanguage': preferredLanguage,
      'selectedPaths': selectedPaths,
    };
  }

  /// Creates from JSON
  factory OnboardingPreferences.fromJson(Map<String, dynamic> json) {
    return OnboardingPreferences(
      familiarityLevel: json['familiarityLevel'] as String?,
      preferredLanguage: json['preferredLanguage'] as String?,
      selectedPaths:
          (json['selectedPaths'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList(),
    );
  }

  /// Checks if all preferences are complete
  bool get isComplete {
    return familiarityLevel != null &&
        preferredLanguage != null &&
        selectedPaths != null &&
        selectedPaths!.isNotEmpty;
  }

  @override
  String toString() {
    return 'OnboardingPreferences(familiarityLevel: $familiarityLevel, '
        'preferredLanguage: $preferredLanguage, '
        'selectedPaths: $selectedPaths)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is OnboardingPreferences &&
        other.familiarityLevel == familiarityLevel &&
        other.preferredLanguage == preferredLanguage &&
        _listEquals(other.selectedPaths, selectedPaths);
  }

  @override
  int get hashCode {
    return Object.hash(familiarityLevel, preferredLanguage, selectedPaths);
  }

  bool _listEquals(List<String>? a, List<String>? b) {
    if (a == null) return b == null;
    if (b == null || a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}

/// Familiarity level options
class FamiliarityLevel {
  static const String completelyNew = 'completely_new';
  static const String knowLittle = 'know_little';
  static const String practicingBuddhist = 'practicing_buddhist';
}

/// Language options
class PreferredLanguage {
  static const String tibetan = 'tibetan';
  static const String english = 'english';
  static const String sanskrit = 'sanskrit';
  static const String chinese = 'chinese';
}

/// Buddhist path options
class BuddhistPath {
  static const String theravada = 'theravada';
  static const String zen = 'zen';
  static const String tibetanBuddhism = 'tibetan_buddhism';
  static const String pureLand = 'pure_land';
}
