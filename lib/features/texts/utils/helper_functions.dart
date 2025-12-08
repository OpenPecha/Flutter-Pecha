// to get the last segment id
import 'package:flutter_pecha/core/utils/app_logger.dart';
import 'package:flutter_pecha/features/texts/models/section.dart';
import 'package:flutter_pecha/features/texts/models/segment.dart';
import 'package:flutter_pecha/features/texts/models/text/toc.dart';

final _logger = AppLogger('TextHelperFunctions');

/// Gets the last segment ID from a list of sections
///
/// Returns the segment_id of the last segment in the last section,
/// or null if no sections or segments are available
/// Handles nested sections recursively
String? getLastSegmentId(List<Section> sections) {
  if (sections.isEmpty) return null;

  final lastSection = sections.last;

  // First try to get from nested sections
  if (lastSection.sections != null && lastSection.sections!.isNotEmpty) {
    final nestedResult = getLastSegmentId(lastSection.sections!);
    if (nestedResult != null) return nestedResult;
  }

  // If no nested sections or no result from nested, try direct segments
  if (lastSection.segments.isNotEmpty) {
    return lastSection.segments.last.segmentId;
  }

  return null;
}

/// Gets the first segment ID from a list of sections
///
/// Returns the segment_id of the first segment in the first section,
/// or null if no sections or segments are available
/// Handles nested sections recursively
String? getFirstSegmentId(List<Section> sections) {
  if (sections.isEmpty) return null;

  final firstSection = sections.first;

  // First try to get from nested sections
  if (firstSection.sections != null && firstSection.sections!.isNotEmpty) {
    final nestedResult = getFirstSegmentId(firstSection.sections!);
    if (nestedResult != null) return nestedResult;
  }

  // If no nested sections or no result from nested, try direct segments
  if (firstSection.segments.isNotEmpty) {
    return firstSection.segments.first.segmentId;
  }

  return null;
}

/// Gets the total number of segments across all sections
/// Handles nested sections recursively
int getTotalSegmentsCount(List<Section> sections) {
  return sections.fold(0, (total, section) {
    int sectionTotal = section.segments.length;

    // Add segments from nested sections
    if (section.sections != null) {
      sectionTotal += getTotalSegmentsCount(section.sections!);
    }

    return total + sectionTotal;
  });
}

/// Merges two lists of sections recursively, handling nested sections
///
/// Returns a new list of sections that is the combination of the two input lists.
/// If a section exists in both lists, the segments and nested sections from the new list will be merged with the existing section.
/// If a section does not exist in the existing list, it will be added.
List<Section> mergeSections(
  List<Section> existingSections,
  List<Section> newSections,
  String direction,
) {
  if (existingSections.isEmpty) return newSections;
  if (newSections.isEmpty) return existingSections;

  final mergedSections = List<Section>.from(existingSections);

  try {
    for (final newSection in newSections) {
      final existingIndex = mergedSections.indexWhere(
        (section) => section.id == newSection.id,
      );

      if (existingIndex != -1) {
        // Section exists, merge segments and nested sections
        final Section existingSection = mergedSections[existingIndex];
        final mergedSegments = List<Segment>.from(existingSection.segments);

        // Merge segments
        // if (direction == 'previous') {
        //   // For previous direction, insert segments in reverse order so last one is on top
        //   for (int i = newSection.segments.length - 1; i >= 0; i--) {
        //     final newSegment = newSection.segments[i];
        //     final segmentExists = mergedSegments.any(
        //       (segment) => segment.segmentId == newSegment.segmentId,
        //     );

        //     if (!segmentExists) {
        //       mergedSegments.insert(0, newSegment);
        //     }
        //   }
        // } else {
        // For next direction, add segments in normal order
        for (final newSegment in newSection.segments) {
          final segmentExists = mergedSegments.any(
            (segment) => segment.segmentId == newSegment.segmentId,
          );

          if (!segmentExists) {
            if (direction == 'previous') {
              // Add at the beginning
              mergedSegments.insert(0, newSegment);
            } else {
              // Add at the end
              mergedSegments.add(newSegment);
            }
          }
        }
        // }

        // Merge nested sections recursively
        final mergedNestedSections = mergeSections(
          existingSection.sections ?? [],
          newSection.sections ?? [],
          direction,
        );

        // Create new section with merged segments and nested sections
        // Equivalent to JavaScript: {...existingSection, segments: mergedSegments, sections: mergedNestedSections}
        mergedSections[existingIndex] = existingSection.copyWith(
          segments: mergedSegments,
          sections: mergedNestedSections,
        );
      } else {
        // Section doesn't exist, add it based on direction
        if (direction == 'previous') {
          // Add new sections at the beginning (top)
          mergedSections.insert(0, newSection);
        } else {
          // Add new sections at the end (bottom)
          mergedSections.add(newSection);
        }
      }
    }
  } catch (e) {
    _logger.error('Error merging sections', e);
  }

  return mergedSections;
}

// ✅ Correct function to find segment index
int findSegmentIndex(Toc content, String targetSegmentId) {
  int currentIndex = 0;

  for (final section in content.sections) {
    // Check if target is in this section (including nested)
    final segmentIndex = _findSegmentInSection(
      section,
      targetSegmentId,
      currentIndex,
    );
    if (segmentIndex != -1) {
      return segmentIndex;
    }

    // Move to next section
    currentIndex += calculateSectionItemCount(section);
  }

  return -1; // Not found
}

// recursive function to find segment in a section
int _findSegmentInSection(
  Section section,
  String targetSegmentId,
  int startIndex,
) {
  int currentIndex = startIndex;

  // Skip section title
  currentIndex++;

  // Check direct segments in this section
  for (
    int segmentIndex = 0;
    segmentIndex < section.segments.length;
    segmentIndex++
  ) {
    final segment = section.segments[segmentIndex];
    if (segment.segmentId == targetSegmentId) {
      return currentIndex; // Found it!
    }
    currentIndex++;
  }

  // Check nested sections
  if (section.sections != null) {
    for (final nestedSection in section.sections!) {
      final segmentIndex = _findSegmentInSection(
        nestedSection,
        targetSegmentId,
        currentIndex,
      );
      if (segmentIndex != -1) {
        return segmentIndex; // Found in nested section
      }
      currentIndex += calculateSectionItemCount(nestedSection);
    }
  }

  return -1; // Not found in this section
}

// Helper function to calculate section item count (same as in Chapter widget)
int calculateSectionItemCount(Section section) {
  int count = 1; // Section title
  count += section.segments.length; // Direct segments

  // Add nested sections
  if (section.sections != null) {
    for (final nestedSection in section.sections!) {
      count += calculateSectionItemCount(nestedSection);
    }
  }
  return count;
}
