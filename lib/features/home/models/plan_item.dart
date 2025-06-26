import 'package:flutter_pecha/features/home/models/prayer_data.dart';

class PlanItem {
  final String verseText;
  final String verseImageUrl;
  final String scriptureVideoUrl;
  final String meditationAudioUrl;
  final String meditationImageUrl;
  final List<PrayerData> prayerData;
  final String prayerAudioUrl;
  final String mindTrainingImageUrl;

  PlanItem({
    required this.verseText,
    required this.verseImageUrl,
    required this.scriptureVideoUrl,
    required this.meditationAudioUrl,
    required this.meditationImageUrl,
    required this.prayerData,
    required this.prayerAudioUrl,
    required this.mindTrainingImageUrl,
  });

  factory PlanItem.fromJson(Map<String, dynamic> json) {
    return PlanItem(
      verseText: json['verseText'],
      verseImageUrl: json['verseImageUrl'],
      scriptureVideoUrl: json['scriptureVideoUrl'],
      meditationAudioUrl: json['meditationAudioUrl'],
      meditationImageUrl: json['meditationImageUrl'],
      prayerData:
          (json['prayerData'] as List)
              .map((prayerData) => PrayerData.fromJson(prayerData))
              .toList(),
      prayerAudioUrl: json['prayerAudioUrl'],
      mindTrainingImageUrl: json['mindTrainingImageUrl'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'verseText': verseText,
      'verseImageUrl': verseImageUrl,
      'scriptureVideoUrl': scriptureVideoUrl,
      'meditationAudioUrl': meditationAudioUrl,
      'meditationImageUrl': meditationImageUrl,
      'prayerData':
          prayerData.map((prayerData) => prayerData.toJson()).toList(),
      'prayerAudioUrl': prayerAudioUrl,
      'mindTrainingImageUrl': mindTrainingImageUrl,
    };
  }
}
