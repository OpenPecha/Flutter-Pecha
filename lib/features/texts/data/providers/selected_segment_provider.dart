import 'package:flutter_pecha/features/texts/models/segment.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final selectedSegmentProvider = StateProvider<Segment?>((ref) => null);

final bottomBarVisibleProvider = StateProvider.autoDispose<bool>(
  (ref) => false,
);

/// Provider to track the segment ID for which commentary split screen is shown.
/// When null, the split screen is hidden.
final commentarySplitSegmentProvider = StateProvider<String?>((ref) => null);

/// Provider to track the split ratio for the commentary panel (0.0 to 1.0).
/// Represents the fraction of height taken by the main text content.
/// Default is 0.5 (50% each).
final commentarySplitRatioProvider = StateProvider<double>((ref) => 0.5);
