import 'package:flutter_pecha/core/constants/app_storage_keys.dart';
import 'package:flutter_pecha/core/utils/app_logger.dart';
import 'package:flutter_pecha/core/utils/local_storage_service.dart';
import 'package:flutter_pecha/features/auth/application/user_state.dart';
import 'package:flutter_pecha/features/auth/data/providers/auth_providers.dart';
import 'package:flutter_pecha/features/auth/domain/entities/user.dart';
import 'package:flutter_pecha/features/auth/domain/repositories/auth_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final _logger = AppLogger('UserNotifier');

/// UserNotifier manages user state and provides reactive user data to the app
///
/// This is the single source of truth for user profile data.
/// Follows industry best practices:
/// - Separation of concerns (Auth != User Profile)
/// - Single source of truth
/// - Reactive state management
/// - Proper error handling
class UserNotifier extends StateNotifier<UserState> {
  final AuthRepository _authRepository;
  final LocalStorageService _localStorageService;

  UserNotifier({
    required AuthRepository authRepository,
    required LocalStorageService localStorageService,
  }) : _authRepository = authRepository,
       _localStorageService = localStorageService,
       super(const UserState.initial());

  /// Initialize user data from API or local cache
  /// Call this after successful authentication
  Future<void> initializeUser() async {
    try {
      _logger.debug('Initializing user data');
      state = const UserState.loading();

      // Try to fetch from API first
      final user = await _authRepository.getCurrentUser();

      if (user != null) {
        _logger.info('User data loaded from API: ${user.displayName}');

        // Preserve local onboarding status (backend doesn't store this)
        final localOnboardingCompleted =
            await _localStorageService.get<bool>(
              AppStorageKeys.onboardingCompleted,
            ) ??
            false;

        // Update user with local onboarding status
        final userWithLocalOnboarding = user.copyWith(
          onboardingCompleted: localOnboardingCompleted,
        );

        state = UserState.loaded(userWithLocalOnboarding);

        // Cache locally for offline access
        await _cacheUserLocally(userWithLocalOnboarding);
      } else {
        // Fallback to local cache
        _logger.debug('No user from API, trying local cache');
        await _loadFromLocalCache();
      }
    } catch (e, stackTrace) {
      _logger.error('Error initializing user', e, stackTrace);

      // Try local cache on error
      try {
        await _loadFromLocalCache();
      } catch (cacheError) {
        state = UserState.error('Failed to load user data: ${e.toString()}');
      }
    }
  }

  /// Refresh user data from API
  Future<void> refreshUser() async {
    try {
      final user = await _authRepository.getCurrentUser();

      if (user != null) {
        _logger.debug('User data refreshed: ${user.displayName}');

        // Preserve local onboarding status (backend doesn't store this)
        final localOnboardingCompleted =
            await _localStorageService.get<bool>(
              AppStorageKeys.onboardingCompleted,
            ) ??
            false;

        // Update user with local onboarding status
        final userWithLocalOnboarding = user.copyWith(
          onboardingCompleted: localOnboardingCompleted,
        );

        state = UserState.loaded(userWithLocalOnboarding);
        await _cacheUserLocally(userWithLocalOnboarding);
      }
    } catch (e) {
      _logger.error('Error refreshing user', e);
      // Keep current state on refresh error
      state = state.copyWith(errorMessage: 'Failed to refresh user data');
    }
  }

  /// Update user data (optimistic update + API sync)
  Future<void> updateUser(User updatedUser) async {
    try {
      // Optimistic update
      state = UserState.loaded(updatedUser);

      // Cache locally
      await _cacheUserLocally(updatedUser);

      // Sync onboarding status separately to local storage
      await _localStorageService.set(
        AppStorageKeys.onboardingCompleted,
        updatedUser.onboardingCompleted,
      );

      _logger.debug('User data updated: ${updatedUser.displayName}');
    } catch (e) {
      _logger.error('Error updating user', e);
      state = state.copyWith(errorMessage: 'Failed to update user data');
    }
  }

  /// Update onboarding status
  Future<void> updateOnboardingStatus(bool completed) async {
    try {
      // Update local storage first (primary source of truth)
      await _localStorageService.set(
        AppStorageKeys.onboardingCompleted,
        completed,
      );

      // Update user object if it exists
      if (state.user != null) {
        final updatedUser = state.user!.copyWith(
          onboardingCompleted: completed,
        );
        state = UserState.loaded(updatedUser);
        await _cacheUserLocally(updatedUser);
      }

      _logger.debug('Onboarding status updated: $completed');
    } catch (e) {
      _logger.error('Error updating onboarding status', e);
    }
  }

  /// Clear user data (on logout)
  Future<void> clearUser() async {
    try {
      state = const UserState.initial();

      // Clear local cache
      await _localStorageService.clearUserData();

      _logger.info('User data cleared');
    } catch (e) {
      _logger.error('Error clearing user', e);
    }
  }

  /// Load user from local cache
  Future<void> _loadFromLocalCache() async {
    final localUserData = await _localStorageService.getUserData();

    if (localUserData != null) {
      final user = User.fromJson(localUserData);
      _logger.debug('Loaded user from cache: ${user.displayName}');
      state = UserState.loaded(user);
    } else {
      _logger.debug('No user data in cache');
      state = const UserState.error('No user data available');
    }
  }

  /// Cache user data locally
  Future<void> _cacheUserLocally(User user) async {
    await _localStorageService.setUserData(user.toJson());
  }
}

/// Provider for UserNotifier
/// This is the main provider for accessing user state throughout the app
final userProvider = StateNotifierProvider<UserNotifier, UserState>((ref) {
  final authRepository = ref.watch(authRepositoryProvider);
  final localStorageService = ref.watch(localStorageServiceProvider);

  return UserNotifier(
    authRepository: authRepository,
    localStorageService: localStorageService,
  );
});
