class PrayerData {
  final String text;
  final Duration startTime;
  final Duration endTime;

  PrayerData({
    required this.text,
    required this.startTime,
    required this.endTime,
  });

  factory PrayerData.fromJson(Map<String, dynamic> json) {
    return PrayerData(
      text: json['text'],
      startTime: _parseDuration(json['startTime']!),
      endTime: _parseDuration(json['endTime']!),
    );
  }

  static Duration _parseDuration(String timeStr) {
    final parts = timeStr.split(':');
    final minutes = int.parse(parts[0]);
    final seconds = int.parse(parts[1]);
    return Duration(minutes: minutes, seconds: seconds);
  }

  Map<String, dynamic> toJson() {
    return {'text': text, 'startTime': startTime, 'endTime': endTime};
  }
}
