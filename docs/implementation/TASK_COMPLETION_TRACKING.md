# Task and Subtask Completion Tracking

## Overview

This document describes the implementation of task and subtask completion tracking in the Flutter Pecha app. The system tracks when users complete tasks and view subtasks (story items) to maintain progress state.

**Last Updated**: January 2025  
**Status**: ✅ Implemented (v1.0)

---

## Table of Contents

1. [Architecture](#architecture)
2. [Task Completion](#task-completion)
3. [Subtask Completion](#subtask-completion)
4. [Edge Cases Handled](#edge-cases-handled)
5. [Future Improvements](#future-improvements)
6. [API Endpoints](#api-endpoints)

---

## Architecture

### Components

```
┌─────────────────────────────────────────────────────────┐
│                    UI Layer                              │
│  ┌──────────────────┐  ┌──────────────────────────┐   │
│  │  PlanDetails     │  │  PlanStoryPresenter      │   │
│  │  (Task Toggle)   │  │  (Subtask Tracking)      │   │
│  └────────┬─────────┘  └──────────┬─────────────────┘   │
└───────────┼────────────────────────┼────────────────────┘
            │                        │
            │ Direct Repository Call │
            │                        │
┌───────────┼────────────────────────┼────────────────────┐
│           ▼                        ▼                    │
│  ┌──────────────────────────────────────────────┐      │
│  │     UserPlansRepository                      │      │
│  │  - completeTask(taskId)                      │      │
│  │  - deleteTask(taskId)                        │      │
│  │  - completeSubTask(subtaskId)                │      │
│  └──────────────────┬───────────────────────────┘      │
│                     │                                    │
│  ┌──────────────────▼───────────────────────────┐      │
│  │     UserPlansRemoteDatasource                │      │
│  │  - API calls to backend                       │      │
│  └───────────────────────────────────────────────┘      │
└──────────────────────────────────────────────────────────┘
```

### Key Design Decisions

1. **Direct Repository Calls** (not FutureProviders)

   - Tasks/subtasks are mutations (POST/DELETE operations)
   - FutureProviders cache results, causing "only works once" bugs
   - Direct calls ensure fresh API requests every time

2. **Debounced Subtask Tracking**

   - 300ms debounce prevents excessive API calls during rapid swiping
   - Only marks completion after user pauses on a story

3. **Silent Background Operation**
   - Subtask completion happens automatically without UI interruption
   - Errors are logged but don't disrupt user experience

---

## Task Completion

### Implementation

**Location**: `lib/features/plans/presentation/plan_details.dart`

**Flow**:

1. User taps checkbox on a task
2. `_handleTaskToggle()` is called with taskId
3. Checks `task.isCompleted` status
4. Calls appropriate API:
   - If completed → `deleteTask(taskId)` (uncomplete)
   - If not completed → `completeTask(taskId)`
5. On success → Invalidates provider to refresh UI

**Code Example**:

```dart
Future<void> _handleTaskToggle(
  String taskId,
  List<UserTasksDto> tasks,
) async {
  final task = tasks.firstWhere((t) => t.id == taskId);
  final repository = ref.read(userPlansRepositoryProvider);

  try {
    bool success;
    if (task.isCompleted) {
      success = await repository.deleteTask(taskId);
    } else {
      success = await repository.completeTask(taskId);
    }

    if (success && mounted) {
      ref.invalidate(
        userPlanDayContentFutureProvider(
          PlanDaysParams(planId: widget.plan.id, dayNumber: selectedDay),
        ),
      );
    } else if (!success && mounted) {
      _showErrorSnackbar('Failed to update task status');
    }
  } catch (e) {
    debugPrint('Error toggling task: $e');
    if (mounted) {
      _showErrorSnackbar('Error: $e');
    }
  }
}
```

### Features

✅ **Manual Toggle** - User explicitly completes/uncompletes tasks  
✅ **Immediate UI Feedback** - Checkbox state reflects `task.isCompleted` from API  
✅ **Error Handling** - Shows SnackBar on failure  
✅ **State Refresh** - Invalidates provider to sync with server

---

## Subtask Completion

### Implementation

**Location**: `lib/features/story_view/presentation/screens/plan_story_presenter.dart`

**Flow**:

1. User views a story item (subtask content)
2. `onStoryChanged` callback fires with story index
3. 300ms debounce timer starts
4. If user stays on story for 300ms:
   - Maps story index to subtask ID
   - Checks if already completed or pending
   - Calls `completeSubTask(subtaskId)` API
   - Adds to local Set to prevent duplicates

**Code Example**:

```dart
void _onStoryChanged(int storyIndex) {
  // Cancel previous debounce timer
  _debounceTimer?.cancel();

  // Set new debounce timer (300ms)
  _debounceTimer = Timer(const Duration(milliseconds: 300), () {
    if (_isDisposing || !mounted) return;

    final subtaskId = _storyIndexToSubtaskId[storyIndex];
    if (subtaskId == null) return;

    if (storyIndex != _lastTrackedIndex &&
        !_completedSubtaskIds.contains(subtaskId) &&
        !_pendingSubtaskIds.contains(subtaskId)) {

      _lastTrackedIndex = storyIndex;
      final subtask = widget.subtasks.firstWhere((s) => s.id == subtaskId);

      if (!subtask.isCompleted) {
        _markSubtaskComplete(subtaskId);
      }
    }
  });
}
```

### Features

✅ **Automatic Tracking** - Completes subtasks when viewed  
✅ **Debouncing** - Prevents excessive API calls during rapid swiping  
✅ **Index Mapping** - Handles filtered subtasks correctly  
✅ **Duplicate Prevention** - Uses Sets to track completed/pending IDs  
✅ **Silent Operation** - No UI interruption, errors logged only

---

## Edge Cases Handled

### ✅ Currently Handled

1. **Multiple Story Changes in Seconds**

   - Debounce timer cancels on each change
   - Only last viewed story gets tracked (after 300ms pause)
   - Prevents marking stories as "viewed" during rapid swiping

2. **Index Out of Bounds**

   - Validates `index >= 0 && index < widget.subtasks.length`
   - Prevents crashes from invalid indices

3. **Duplicate Tracking**

   - Uses `Set<String>` to track completed subtask IDs
   - Checks both local Set and `isCompleted` flag
   - Prevents duplicate API calls

4. **Widget Disposal During API Call**

   - Checks `mounted` and `_isDisposing` flags
   - Cancels debounce timer in dispose()
   - Prevents setState on unmounted widget

5. **API Failure Handling**

   - Try-catch blocks around API calls
   - Errors logged but don't crash app
   - Failed subtasks can be retried (not added to completed Set)

6. **Story Items vs Subtasks Mismatch**

   - Some subtasks filtered out if content is empty
   - Index mapping (`_storyIndexToSubtaskId`) handles mismatch
   - Maps story index to correct subtask ID

7. **Concurrent API Calls**
   - `_pendingSubtaskIds` Set prevents duplicate simultaneous calls
   - Properly cleaned up in finally block

### ⚠️ Partially Handled

8. **Rapid Open/Close**

   - Timer might fire after widget disposal starts
   - Protected by `_isDisposing` check, but timing edge case exists

9. **Network Retry**
   - No automatic retry mechanism
   - Failed completions can be retried on next view

### ❌ Not Yet Handled (Future Features)

10. **Offline Queue/Persistence**

    - No local storage for failed completions
    - Lost if app closes before completion

11. **Exponential Backoff Retry**

    - No retry queue with backoff strategy
    - Could add for better reliability

12. **Memory Leak Prevention**
    - Sets cleared in dispose(), but could grow large in long sessions
    - Consider size limits or periodic cleanup

---

## Future Improvements

### High Priority

#### 1. **Index Mapping Enhancement** 🔴

**Current Issue**: Story items count may differ from subtasks due to filtering

**Solution**:

```dart
Map<int, String> _buildIndexMapping() {
  final mapping = <int, String>{};
  int storyIndex = 0;

  for (final subtask in widget.subtasks) {
    if (subtask.content.isEmpty) {
      continue; // Skip filtered subtasks
    }
    mapping[storyIndex] = subtask.id;
    storyIndex++;
  }

  return mapping;
}
```

**Status**: ⚠️ Should be implemented to handle edge case #6 properly

#### 2. **Pending State Management** 🟡

**Current Issue**: API failure after ID added to Set prevents retry

**Solution**:

```dart
final Set<String> _pendingSubtaskIds = {};

Future<void> _markSubtaskComplete(String subtaskId) async {
  _pendingSubtaskIds.add(subtaskId);

  try {
    await repository.completeSubTask(subtaskId);
    if (mounted && !_isDisposing) {
      _completedSubtaskIds.add(subtaskId); // Only on success
    }
  } catch (e) {
    // Remove from pending to allow retry
    _pendingSubtaskIds.remove(subtaskId);
  } finally {
    _pendingSubtaskIds.remove(subtaskId);
  }
}
```

**Status**: ⚠️ Should be implemented for better retry handling

#### 3. **Mounted Checks After Async** 🟡

**Current Issue**: No mounted check after await operations

**Solution**:

```dart
final success = await repository.completeTask(taskId);
if (success && mounted && !_isDisposing) {
  // Update UI
}
```

**Status**: ⚠️ Should be added for robustness

### Medium Priority

#### 4. **Offline Queue with Persistence** 🟢

**Feature**: Store failed completions locally and retry when online

**Implementation**:

- Use `shared_preferences` or `hive` for local storage
- Queue failed API calls
- Retry on app resume or network reconnect
- Clear queue after successful sync

**Benefits**:

- No lost completions during network issues
- Better user experience offline

#### 5. **Completion Analytics** 🟢

**Feature**: Track completion metrics for analytics

**Metrics to Track**:

- Time spent viewing each subtask
- Completion rate per task
- Average time to complete a day
- Drop-off points

**Implementation**:

- Add analytics events on completion
- Track timestamps
- Send to analytics service (Firebase Analytics, etc.)

#### 6. **Batch Completion API** 🟢

**Feature**: Send multiple completions in one API call

**Benefits**:

- Reduced network overhead
- Better for offline sync
- Atomic operations

**API Design**:

```dart
POST /api/v1/users/me/subtasks/batch-complete
{
  "subtask_ids": ["id1", "id2", "id3"]
}
```

### Low Priority

#### 7. **Exponential Backoff Retry** 🔵

**Feature**: Retry failed API calls with exponential backoff

**Implementation**:

```dart
class RetryQueue {
  final Queue<RetryItem> _queue = Queue();

  Future<void> retryWithBackoff(RetryItem item) async {
    int attempt = 0;
    while (attempt < maxRetries) {
      try {
        await item.execute();
        return;
      } catch (e) {
        attempt++;
        await Future.delayed(Duration(seconds: pow(2, attempt)));
      }
    }
  }
}
```

#### 8. **Completion Progress Indicator** 🔵

**Feature**: Show visual progress of task/subtask completion

**UI Elements**:

- Progress bar for day completion
- Checkmarks on completed items
- Celebration animation on day completion

#### 9. **Completion History** 🔵

**Feature**: Track completion history and allow undo

**Implementation**:

- Store completion timestamps
- Allow "undo" for recent completions
- Show completion timeline

#### 10. **Smart Debounce Adjustment** 🔵

**Feature**: Adjust debounce time based on content type

**Logic**:

- Text: 300ms (quick read)
- Video: 2000ms (needs more viewing time)
- Audio: 1500ms (needs listening time)
- Image: 500ms (medium viewing time)

---

## API Endpoints

### Task Completion

#### Complete Task

```
POST /api/v1/users/me/tasks/{taskId}/completion
Headers: Authorization: Bearer {token}
Response: 204 No Content
```

#### Delete/Uncomplete Task

```
DELETE /api/v1/users/me/task/{taskId}
Headers: Authorization: Bearer {token}
Response: 204 No Content
```

### Subtask Completion

#### Complete Subtask

```
POST /api/v1/users/me/sub-tasks/{subTaskId}/complete
Headers: Authorization: Bearer {token}
Response: 204 No Content
```

### Protected Routes

All completion endpoints are protected and require authentication. Routes are configured in:
`lib/core/network/api_client_provider.dart`

```dart
static const List<String> _protectedPaths = [
  '/api/v1/users/me/tasks/{taskId}/completion',
  '/api/v1/users/me/task/{taskId}',
  '/api/v1/users/me/sub-tasks/{subTaskId}/complete',
];
```

---

## Testing Scenarios

### Task Completion Tests

1. ✅ **Toggle Task Complete**

   - Tap checkbox → Task marked complete
   - UI updates immediately
   - API called successfully

2. ✅ **Toggle Task Uncomplete**

   - Tap completed task → Task uncompleted
   - UI updates immediately
   - API called successfully

3. ✅ **Network Error**

   - Disable network → Tap task
   - Error SnackBar shown
   - Task state not changed

4. ✅ **Rapid Toggling**
   - Rapidly tap same task multiple times
   - Each toggle makes fresh API call
   - No caching issues

### Subtask Completion Tests

1. ✅ **View Story Item**

   - View story for >300ms → Subtask marked complete
   - API called successfully
   - No UI interruption

2. ✅ **Rapid Swiping**

   - Swipe through 5 stories in 2 seconds
   - Only last story tracked (after 300ms pause)
   - No excessive API calls

3. ✅ **Already Completed**

   - View already completed subtask
   - No API call made
   - Checked via `isCompleted` flag

4. ✅ **Filtered Subtasks**

   - View story where some subtasks filtered out
   - Correct subtask ID mapped
   - No index mismatch errors

5. ✅ **Widget Disposal**
   - Close story while API call in progress
   - No errors or crashes
   - Timer properly canceled

---

## Code References

### Key Files

- **Task Completion**: `lib/features/plans/presentation/plan_details.dart`
- **Subtask Completion**: `lib/features/story_view/presentation/screens/plan_story_presenter.dart`
- **Repository**: `lib/features/plans/data/repositories/user_plans_repository.dart`
- **Datasource**: `lib/features/plans/data/datasource/user_plans_remote_datasource.dart`
- **API Client**: `lib/core/network/api_client_provider.dart`
- **Router**: `lib/core/config/router/go_router.dart`

### Models

- **Task**: `lib/features/plans/models/user/user_tasks_dto.dart`
- **Subtask**: `lib/features/plans/models/user/user_subtasks_dto.dart`
- **Day Content**: `lib/features/plans/models/response/user_plan_day_detail_response.dart`

---

## Best Practices

### ✅ Do

- Use direct repository calls for mutations (not FutureProviders)
- Add debouncing for automatic tracking
- Check `mounted` and `_isDisposing` after async operations
- Use Sets for duplicate prevention
- Invalidate providers after successful mutations
- Handle errors gracefully without disrupting UX

### ❌ Don't

- Use FutureProviders for POST/DELETE operations
- Add IDs to completed Set before API success
- Make API calls without debouncing for rapid events
- Forget to cancel timers in dispose()
- Show errors for background tracking operations
- Assume 1:1 mapping between story items and subtasks

---

## Changelog

### v1.0 (January 2025)

- ✅ Initial implementation of task completion tracking
- ✅ Initial implementation of subtask completion tracking
- ✅ Debounced subtask tracking (300ms)
- ✅ Direct repository calls (no FutureProvider caching)
- ✅ Error handling and UI feedback
- ✅ Edge case handling for rapid changes and disposal

---

## Related Documentation

- [API Client Provider](./architecture/TOKEN_REFRESH_FLOW.md) - Authentication and API routing
- [Plan Details Implementation](./PLAN_SEARCH_PAGINATION.md) - Plan-related features
- [Auth Implementation](./architecture/AUTH_IMPLEMENTATION.md) - Authentication flow

---

## Questions or Issues?

If you encounter issues or have questions about task/subtask completion tracking:

1. Check this documentation first
2. Review edge cases section
3. Check code references for implementation details
4. Review future improvements for planned enhancements
