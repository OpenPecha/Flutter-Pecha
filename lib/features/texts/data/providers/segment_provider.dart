import 'package:flutter_pecha/features/texts/data/datasource/segment_remote.datasource.dart';
import 'package:flutter_pecha/features/texts/data/repositories/segment_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

final segmentRepositoryProvider = Provider<SegmentRepository>(
  (ref) => SegmentRepository(
    remoteDatasource: SegmentRemoteDatasource(client: http.Client()),
  ),
);

final segmentCommentaryFutureProvider = FutureProvider.family((
  ref,
  String segmentId,
) {
  return ref.watch(segmentRepositoryProvider).getSegmentCommentaries(segmentId);
});
