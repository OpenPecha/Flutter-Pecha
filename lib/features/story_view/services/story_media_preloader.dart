import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_pecha/features/plans/models/user/user_subtasks_dto.dart';

/// Service to preload story media (images, videos) for better UX
class StoryMediaPreloader {
  static final StoryMediaPreloader _instance = StoryMediaPreloader._internal();
  factory StoryMediaPreloader() => _instance;
  StoryMediaPreloader._internal();

  final Set<String> _preloadingImageUrls = {};
  final Set<String> _precachedImageUrls = {};
  final Set<String> _preloadingVideoUrls = {};
  final Set<String> _preparedVideoUrls = {};

  /// Preloads story items progressively
  /// First 2-3 items are prioritized, rest are queued
  Future<void> preloadStoryItems(
    List<UserSubtasksDto> subtasks,
    BuildContext context, {
    int priorityCount = 2,
  }) async {
    if (subtasks.isEmpty) return;

    // Preload priority items (first 2-3) immediately
    final priorityItems = subtasks.take(priorityCount).toList();
    final remainingItems = subtasks.skip(priorityCount).toList();

    // Preload priority items in parallel
    final priorityFutures =
        priorityItems.map((subtask) {
          return _preloadSubtask(subtask, context);
        }).toList();

    // Wait for priority items to start loading
    await Future.wait(priorityFutures, eagerError: false);

    // Preload remaining items in background (don't wait)
    if (remainingItems.isNotEmpty) {
      Future.microtask(() {
        for (final subtask in remainingItems) {
          // if (context.mounted) {
          _preloadSubtask(subtask, context).ignore();
          // }
        }
      });
    }
  }

  /// Preloads a single subtask's media
  Future<void> _preloadSubtask(
    UserSubtasksDto subtask,
    BuildContext context,
  ) async {
    if (subtask.content.isEmpty) return;

    switch (subtask.contentType) {
      case 'IMAGE':
        await preloadImage(subtask.content, context);
        break;
      case 'VIDEO':
        await prepareVideoMetadata(subtask.content);
        break;
      case 'AUDIO':
        // Audio can be preloaded if needed, but typically loads fast enough
        break;
      case 'TEXT':
        // No preloading needed for text
        break;
    }
  }

  /// Precaches a single image
  Future<void> preloadImage(String imageUrl, BuildContext context) async {
    if (imageUrl.isEmpty) return;

    // Check if already precached
    if (_precachedImageUrls.contains(imageUrl)) {
      return;
    }

    // Check if already preloading
    if (_preloadingImageUrls.contains(imageUrl)) {
      return;
    }

    try {
      _preloadingImageUrls.add(imageUrl);
      final imageProvider = CachedNetworkImageProvider(imageUrl);
      await precacheImage(imageProvider, context);
      _precachedImageUrls.add(imageUrl);
    } catch (e) {
      debugPrint('Failed to preload image $imageUrl: $e');
    } finally {
      _preloadingImageUrls.remove(imageUrl);
    }
  }

  /// Checks if an image is already precached
  bool isImagePrecached(String imageUrl) {
    return _precachedImageUrls.contains(imageUrl);
  }

  /// Prepares video metadata (lightweight operation)
  /// For YouTube videos, this extracts the video ID
  Future<void> prepareVideoMetadata(String videoUrl) async {
    if (videoUrl.isEmpty) return;

    // Check if already prepared
    if (_preparedVideoUrls.contains(videoUrl)) {
      return;
    }

    // Check if already preloading
    if (_preloadingVideoUrls.contains(videoUrl)) {
      return;
    }

    try {
      _preloadingVideoUrls.add(videoUrl);
      // Extract YouTube video ID if it's a YouTube URL
      // This is a lightweight operation that helps with faster initialization
      if (videoUrl.contains('youtube.com') || videoUrl.contains('youtu.be')) {
        // Video ID extraction is handled by the YouTube player library
        // We just mark it as prepared
        _preparedVideoUrls.add(videoUrl);
      } else {
        // For other video types, mark as prepared
        _preparedVideoUrls.add(videoUrl);
      }
    } catch (e) {
      debugPrint('Failed to prepare video metadata $videoUrl: $e');
    } finally {
      _preloadingVideoUrls.remove(videoUrl);
    }
  }

  /// Checks if video metadata is prepared
  bool isVideoPrepared(String videoUrl) {
    return _preparedVideoUrls.contains(videoUrl);
  }

  /// Checks if the first story item is ready
  bool isFirstItemReady(UserSubtasksDto firstSubtask) {
    if (firstSubtask.content.isEmpty) return false;

    switch (firstSubtask.contentType) {
      case 'IMAGE':
        return isImagePrecached(firstSubtask.content);
      case 'VIDEO':
        return isVideoPrepared(firstSubtask.content);
      case 'AUDIO':
      case 'TEXT':
        return true; // These load fast enough
      default:
        return false;
    }
  }

  /// Clears preloading state (useful when navigating away)
  void clearPreloadingState() {
    _preloadingImageUrls.clear();
    _preloadingVideoUrls.clear();
  }

  /// Clears all cached state (useful for memory management)
  void clearCache() {
    _precachedImageUrls.clear();
    _preparedVideoUrls.clear();
    clearPreloadingState();
  }
}
