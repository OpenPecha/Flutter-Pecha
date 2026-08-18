import 'package:flutter_pecha/core/config/locale/locale_notifier.dart';
import 'package:flutter_pecha/features/auth/presentation/providers/state_providers.dart';
import 'package:flutter_pecha/features/group_profile/domain/entities/group_event.dart';
import 'package:flutter_pecha/features/group_profile/presentation/providers/group_profile_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

const homeGroupEventsPreviewLimit = 2;

final homeGroupEventsPreviewProvider =
    FutureProvider.autoDispose<List<GroupEvent>>((ref) async {
      final authState = ref.watch(authProvider);
      if (authState.isGuest || !authState.isLoggedIn) {
        return const [];
      }

      final language = ref.watch(contentLanguageProvider);
      final result = await ref
          .read(groupProfileRepositoryProvider)
          .getConnectEvents(
            includeUnfollowed: false,
            language: language,
            skip: 0,
            limit: homeGroupEventsPreviewLimit,
          );

      return result.fold((_) => const [], (page) => page.events);
    });
