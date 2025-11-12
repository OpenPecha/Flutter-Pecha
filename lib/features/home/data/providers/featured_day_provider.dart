import 'package:flutter_pecha/core/config/locale/locale_notifier.dart';
import 'package:flutter_pecha/features/plans/models/response/featured_day_response.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import '../datasource/featured_day_remote_datasource.dart';
import '../repositories/featured_day_repository.dart';

// Repository provider
final featuredDayRepositoryProvider = Provider<FeaturedDayRepository>((ref) {
  return FeaturedDayRepository(
    featuredDayRemoteDatasource: FeaturedDayRemoteDatasource(
      client: http.Client(),
    ),
  );
});

// Featured day tasks provider - returns List<FeaturedDayTask>
// Watches localeProvider to refresh when language changes
final featuredDayFutureProvider = FutureProvider<List<FeaturedDayTask>>((
  ref,
) async {
  // Watch locale to refresh when language changes
  final locale = ref.watch(localeProvider);
  final repository = ref.watch(featuredDayRepositoryProvider);
  final response = await repository.getFeaturedDay(
    language: locale.languageCode,
  );
  return repository.mapToFeaturedDayTasks(response);
});
