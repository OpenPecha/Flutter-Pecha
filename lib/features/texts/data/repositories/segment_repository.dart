import 'package:flutter_pecha/features/texts/data/datasource/segment_remote.datasource.dart';
import 'package:flutter_pecha/features/texts/models/commentary/segment_commentary_response.dart';

class SegmentRepository {
  final SegmentRemoteDatasource remoteDatasource;

  SegmentRepository({required this.remoteDatasource});

  Future<SegmentCommentaryResponse> getSegmentCommentaries(
    String segmentId,
  ) async {
    return await remoteDatasource.getSegmentCommentaries(segmentId);
  }
}
