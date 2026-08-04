class DeepLinkUrlBuilder {
  DeepLinkUrlBuilder._();

  static const String _host = 'webuddhist.com';

  static Uri homeLink() {
    return Uri(scheme: 'https', host: _host, pathSegments: ['open']);
  }

  /// Returns a link that opens the reader at the very first segment —
  /// i.e. no segment/lang params so the app starts from the top.
  static Uri readerLink({required String textId}) {
    return Uri(
      scheme: 'https',
      host: _host,
      pathSegments: ['open', 'reader', textId],
    );
  }

  static Uri seriesLink({required String seriesId}) {
    return Uri(
      scheme: 'https',
      host: _host,
      pathSegments: ['open', 'series', seriesId],
    );
  }

  static Uri planLink({required String planId}) {
    return Uri(
      scheme: 'https',
      host: _host,
      pathSegments: ['open', 'plan', planId],
    );
  }

  /// Returns a link that opens a specific day inside a plan.
  ///
  /// Format: https://webuddhist.com/open/plan/{planId}/day/{dayNumber}?lang={language}
  ///
  /// [language] is the content language of the plan (e.g. 'en', 'bo'). It is
  /// included so the recipient's app can locate the correct enrollment even when
  /// their app locale differs from the sharer's.
  static Uri planDayLink({
    required String planId,
    required int dayNumber,
    String? language,
  }) {
    final queryParameters = <String, String>{
      if (language != null && language.isNotEmpty) 'lang': language,
    };
    return Uri(
      scheme: 'https',
      host: _host,
      pathSegments: ['open', 'plan', planId, 'day', dayNumber.toString()],
      queryParameters: queryParameters.isNotEmpty ? queryParameters : null,
    );
  }

  static Uri readerSegmentLink({
    required String textId,
    required String segmentId,
    String? language,
  }) {
    final queryParameters = <String, String>{
      'segment': segmentId,
      if (language != null && language.isNotEmpty) 'lang': language,
    };

    return Uri(
      scheme: 'https',
      host: _host,
      pathSegments: ['open', 'reader', textId],
      queryParameters: queryParameters,
    );
  }

  static Uri moreLink() {
    return Uri(scheme: 'https', host: _host, pathSegments: ['open', 'more']);
  }

  static Uri groupLink({required String groupId}) {
    return Uri(
      scheme: 'https',
      host: _host,
      pathSegments: ['open', 'group', groupId],
    );
  }

  static Uri eventLink({required String eventId}) {
    return Uri(
      scheme: 'https',
      host: _host,
      pathSegments: ['open', 'events', eventId],
    );
  }

  /// Returns a link that opens a group accumulation detail page.
  ///
  /// Format: https://webuddhist.com/open/group-accumulator/{accumulatorId}?group={groupId}
  ///
  /// [groupId] lets the recipient's app push the group page beneath the
  /// accumulation so the back button unwinds accumulation -> group -> Connect.
  static Uri groupAccumulatorLink({
    required String accumulatorId,
    required String groupId,
  }) {
    return Uri(
      scheme: 'https',
      host: _host,
      pathSegments: ['open', 'group-accumulator', accumulatorId],
      queryParameters: {'group': groupId},
    );
  }

  static Uri malaLink({required String presetId}) {
    return Uri(
      scheme: 'https',
      host: _host,
      pathSegments: ['open', 'mala', presetId],
    );
  }

  static Uri timerLink({required String timerId}) {
    return Uri(
      scheme: 'https',
      host: _host,
      pathSegments: ['open', 'timer', timerId],
    );
  }
}
