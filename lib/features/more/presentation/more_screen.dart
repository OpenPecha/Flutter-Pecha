import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/config/locale/locale_notifier.dart';
import 'package:flutter_pecha/core/l10n/generated/app_localizations.dart';
import 'package:flutter_pecha/core/theme/app_colors.dart';
import 'package:flutter_pecha/core/theme/theme_notifier.dart';
import 'package:flutter_pecha/core/widgets/cached_network_image_widget.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_pecha/features/auth/application/auth_notifier.dart';
import 'package:go_router/go_router.dart';
import '../../notifications/presentation/notification_settings_screen.dart';

class MoreScreen extends ConsumerWidget {
  const MoreScreen({super.key});
  final _supportedLocales = const [Locale('en'), Locale('zh'), Locale('bo')];

  String _getLanguageName(Locale locale) {
    switch (locale.languageCode) {
      case 'en':
        return 'English';
      case 'zh':
        return '中文 (Chinese)';
      case 'bo':
        return 'བོད་སྐད་ (Tibetan)';
      default:
        return locale.languageCode;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final locale = ref.watch(localeProvider);
    final localizations = AppLocalizations.of(context)!;
    final authState = ref.watch(authProvider);
    final isDarkMode = themeMode == ThemeMode.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        centerTitle: false,
        title: const Text(
          'More',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
        scrolledUnderElevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Profile Section
          if (authState.isLoggedIn && !authState.isGuest) ...[
            _buildSectionCard(
              context,
              children: [
                ListTile(
                  leading: Hero(
                    tag: 'profile-avatar',
                    child: CircleAvatar(
                      radius: 20,
                      backgroundColor: Colors.grey.shade300,
                      backgroundImage:
                          (authState.userProfile?.pictureUrl?.toString() ?? '')
                                  .isNotEmpty
                              ? authState.userProfile!.pictureUrl!
                                  .toString()
                                  .cachedNetworkImageProvider
                              : null,
                      child:
                          ((authState.userProfile?.pictureUrl?.toString() ?? '')
                                  .isEmpty)
                              ? const Icon(Icons.person, color: Colors.black54)
                              : null,
                    ),
                  ),
                  title: Text(
                    authState.userProfile?.name ??
                        '${authState.userProfile?.givenName ?? ''} ${authState.userProfile?.familyName ?? ''}'
                            .trim(),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: Text(
                    authState.userProfile?.email ?? '',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push('/profile'),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
          // Appearance Section
          _buildSectionHeader(context, 'Appearance'),
          _buildSectionCard(
            context,
            children: [
              ListTile(
                leading: Icon(
                  isDarkMode ? Icons.dark_mode : Icons.light_mode,
                  color: Theme.of(context).colorScheme.primary,
                ),
                title: Text(
                  isDarkMode
                      ? localizations.themeDark
                      : localizations.themeLight,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                subtitle: Text(
                  isDarkMode ? 'Dark theme enabled' : 'Light theme enabled',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                trailing: Switch(
                  value: isDarkMode,
                  onChanged:
                      (_) => ref.read(themeModeProvider.notifier).toggleTheme(),
                  activeColor: Theme.of(context).colorScheme.primary,
                  thumbColor: WidgetStateProperty.all(
                    themeMode == ThemeMode.dark ? Colors.white : Colors.black,
                  ),
                ),
              ),
              const Divider(height: 1),
              ListTile(
                leading: Icon(
                  Icons.language,
                  color: Theme.of(context).colorScheme.primary,
                ),
                title: Text(
                  'Language',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                subtitle: Text(
                  _getLanguageName(locale),
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _showLanguageBottomSheet(context, ref, locale),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Notification Settings
          _buildSectionHeader(context, 'Notifications'),
          _buildSectionCard(
            context,
            children: [
              ListTile(
                leading: Icon(
                  Icons.notifications,
                  color: Theme.of(context).colorScheme.primary,
                ),
                title: Text(
                  AppLocalizations.of(context)?.notificationSettings ??
                      'Notification Settings',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                subtitle: Text(
                  AppLocalizations.of(context)?.manageDailyReminders ??
                      'Manage daily reminders',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                onTap: () => context.push(NotificationSettingsScreen.routeName),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Account Section
          _buildSectionHeader(context, 'Account'),
          _buildSectionCard(
            context,
            children: [
              if (authState.isGuest) ...[
                // Show sign-in option for guest users
                ListTile(
                  leading: Icon(
                    Icons.login,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  title: Text(
                    localizations.common_sign_in,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  subtitle: Text(
                    'Sign in to sync your progress',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  onTap: () => ref.read(authProvider.notifier).logout(),
                ),
              ] else if (authState.isLoggedIn) ...[
                // Show logout option for authenticated users
                ListTile(
                  leading: Icon(Icons.logout, color: Colors.red.shade600),
                  title: Text(
                    'Logout',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Colors.red.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  subtitle: Text(
                    'Sign out of your account',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  onTap: () => _showLogoutDialog(context, ref),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, right: 16, bottom: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: AppColors.primary,
        ),
      ),
    );
  }

  Widget _buildSectionCard(
    BuildContext context, {
    required List<Widget> children,
  }) {
    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      color: Theme.of(context).cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: Theme.of(context).dividerColor.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: Column(children: children),
    );
  }

  void _showLanguageBottomSheet(
    BuildContext context,
    WidgetRef ref,
    Locale? currentLocale,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder:
          (context) => Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Text(
                  'Select Language',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 16),
                ..._supportedLocales.map((localeItem) {
                  final isSelected =
                      (currentLocale ?? Localizations.localeOf(context)) ==
                      localeItem;
                  return ListTile(
                    title: Text(
                      _getLanguageName(localeItem),
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    trailing:
                        isSelected
                            ? Icon(
                              Icons.check,
                              color: Theme.of(context).colorScheme.primary,
                            )
                            : null,
                    onTap: () {
                      ref.read(localeProvider.notifier).setLocale(localeItem);
                      Navigator.pop(context);
                    },
                  );
                }),
                const SizedBox(height: 16),
              ],
            ),
          ),
    );
  }

  void _showLogoutDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            title: Text(
              'Log Out',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
            ),
            content: Text(
              'Are you sure you want to log out?',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  ref.read(authProvider.notifier).logout();
                  Navigator.pop(context);
                },
                style: TextButton.styleFrom(
                  foregroundColor: Colors.red.shade600,
                ),
                child: const Text('Logout'),
              ),
            ],
          ),
    );
  }
}
