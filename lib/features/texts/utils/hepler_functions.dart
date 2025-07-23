// to get the last segment id
import 'package:flutter_pecha/features/texts/models/section.dart';
import 'package:flutter_pecha/features/texts/models/segment.dart';

/// Gets the last segment ID from a list of sections
///
/// Returns the segment_id of the last segment in the last section,
/// or null if no sections or segments are available
String? getLastSegmentId(List<Section> sections) {
  if (sections.isEmpty) return null;

  final lastSection = sections.last;
  if (lastSection.segments.isEmpty) return null;

  final lastSegment = lastSection.segments.last;
  return lastSegment.segmentId;
}

/// Gets the first segment ID from a list of sections
///
/// Returns the segment_id of the first segment in the first section,
/// or null if no sections or segments are available
String? getFirstSegmentId(List<Section> sections) {
  if (sections.isEmpty) return null;

  final firstSection = sections.first;
  if (firstSection.segments.isEmpty) return null;

  final firstSegment = firstSection.segments.first;
  return firstSegment.segmentId;
}

/// Gets the total number of segments across all sections
int getTotalSegmentsCount(List<Section> sections) {
  return sections.fold(0, (total, section) => total + section.segments.length);
}

/// Merges two lists of sections based on direction
///
/// [direction] can be 'previous' or 'next'
/// - If 'previous': newSections are merged at the beginning (top)
/// - If 'next': newSections are merged at the end (bottom)
///
/// Returns a new list of sections that is the combination of the two input lists.
/// If a section exists in both lists, the segments from the new list will be added to the existing section.
/// If a section does not exist in the existing list, it will be added based on direction.
List<Section> mergeSections(
  List<Section> existingSections,
  List<Section> newSections,
  String direction,
) {
  if (existingSections.isEmpty) return newSections;
  if (newSections.isEmpty) return existingSections;

  final mergedSections = List<Section>.from(existingSections);

  for (final newSection in newSections) {
    final existingIndex = mergedSections.indexWhere(
      (section) => section.id == newSection.id,
    );

    if (existingIndex != -1) {
      // Section exists, merge segments
      final existingSection = mergedSections[existingIndex];
      final mergedSegments = List<Segment>.from(existingSection.segments);

      for (final newSegment in newSection.segments) {
        final segmentExists = mergedSegments.any(
          (segment) => segment.segmentId == newSegment.segmentId,
        );

        if (!segmentExists) {
          if (direction == 'previous') {
            mergedSegments.insert(newSegment.segmentNumber - 1, newSegment);
          } else {
            mergedSegments.add(newSegment);
          }
        }
      }

      // Create new section with merged segments
      mergedSections[existingIndex] = Section(
        id: existingSection.id,
        title: existingSection.title,
        sectionNumber: existingSection.sectionNumber,
        parentId: existingSection.parentId,
        segments: mergedSegments,
        sections: existingSection.sections,
        createdDate: existingSection.createdDate,
        updatedDate: existingSection.updatedDate,
        publishedDate: existingSection.publishedDate,
      );
    } else {
      // Section doesn't exist, add it based on direction
      if (direction == 'previous') {
        // Add new sections at the beginning (top)
        mergedSections.insert(0, newSection);
      } else {
        // Add new sections at the end (bottom) - default behavior
        mergedSections.add(newSection);
      }
    }
  }

  return mergedSections;
}
