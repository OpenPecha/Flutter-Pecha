/// Model for storing user preferences collected during onboarding
class OnboardingPreferences {
  const OnboardingPreferences({this.preferredLanguage});

  final String? preferredLanguage;

  /// Creates a copy with the specified fields replaced with new values
  OnboardingPreferences copyWith({String? preferredLanguage}) {
    return OnboardingPreferences(
      preferredLanguage: preferredLanguage ?? this.preferredLanguage,
    );
  }

  /// Converts to JSON for storage
  Map<String, dynamic> toJson() {
    return {'preferredLanguage': preferredLanguage};
  }

  /// Creates from JSON
  factory OnboardingPreferences.fromJson(Map<String, dynamic> json) {
    return OnboardingPreferences(
      preferredLanguage: json['preferredLanguage'] as String?,
    );
  }

  /// Checks if all preferences are complete
  bool get isComplete {
    return preferredLanguage != null;
  }

  @override
  String toString() {
    return 'OnboardingPreferences(preferredLanguage: $preferredLanguage)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is OnboardingPreferences &&
        other.preferredLanguage == preferredLanguage;
  }

  @override
  int get hashCode {
    return preferredLanguage?.hashCode ?? 0;
  }
}

/// Language options
class PreferredLanguage {
  static const String tibetan = 'tibetan';
  static const String english = 'english';
  static const String chinese = 'chinese';
}
