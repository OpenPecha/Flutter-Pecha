import 'package:flutter_pecha/features/texts/models/segment.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final selectedSegmentProvider = StateProvider<Segment?>((ref) => null);

final bottomBarVisibleProvider = StateProvider.autoDispose<bool>(
  (ref) => false,
);
