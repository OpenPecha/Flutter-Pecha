import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/l10n/l10n.dart';
import 'package:flutter_pecha/core/theme/theme_notifier.dart';
import 'package:flutter_pecha/features/notifications/services/notification_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_pecha/core/l10n/generated/app_localizations.dart';
import 'package:flutter_pecha/core/config/router/go_router.dart';
import 'package:flutter_pecha/core/config/locale/locale_notifier.dart';
import 'package:fquery/fquery.dart';
import 'core/theme/app_theme.dart';
import 'core/localization/material_localizations_bo.dart';
import 'core/localization/cupertino_localizations_bo.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:just_audio_background/just_audio_background.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");

  // Initialize background audio service
  await JustAudioBackground.init(
    androidNotificationChannelId: 'org.pecha.app.channel.audio',
    androidNotificationChannelName: 'Recitation Audio',
    androidNotificationOngoing: true,
  );

  // Initialize notification service
  final notificationService = NotificationService();
  await notificationService.initialize();
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(goRouterProvider);
    final locale = ref.watch(localeProvider);
    final themeMode = ref.watch(themeModeProvider);

    NotificationService.setRouter(router);

    // Add QueryClient provider wrapper
    return QueryClientProvider(
      queryClient: QueryClient(
        defaultQueryOptions: DefaultQueryOptions(
          staleDuration: const Duration(
            minutes: 5,
          ), // Data stays fresh for 5 minutes
          cacheDuration: const Duration(
            minutes: 10,
          ), // Cache persists for 10 minutes
          retryCount: 3, // Retry failed queries 3 times
        ),
      ),
      child: MaterialApp.router(
        title: 'Pecha',
        theme: AppTheme.lightTheme(locale),
        darkTheme: AppTheme.darkTheme(locale),
        themeMode: themeMode,
        locale: locale,
        localizationsDelegates: [
          MaterialLocalizationsBo.delegate,
          CupertinoLocalizationsBo.delegate,
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: L10n.all,
        debugShowCheckedModeBanner: false,
        routerConfig: router,
      ),
    );
  }
}
