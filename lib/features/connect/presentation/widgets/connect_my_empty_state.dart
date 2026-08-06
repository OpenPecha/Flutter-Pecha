import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/constants/app_assets.dart';
import 'package:flutter_pecha/core/theme/app_colors.dart';

enum ConnectMyEmptyStateType { feed, events, posts, groups }

/// Empty state shown in Connect tabs when the My segment has no content.
class ConnectMyEmptyState extends StatelessWidget {
  const ConnectMyEmptyState({
    super.key,
    required this.type,
    required this.onBrowseTap,
  });

  final ConnectMyEmptyStateType type;
  final VoidCallback onBrowseTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final titleColor =
        isDark ? AppColors.textPrimaryDark : AppColors.textPrimary;
    final subtitleColor =
        isDark ? AppColors.textTertiaryDark : AppColors.textSecondary;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          ClipOval(
            child: Image.asset(
              AppAssets.connect,
              width: 160,
              height: 160,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            _title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: titleColor,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            _subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 15, color: subtitleColor, height: 1.5),
          ),
          const SizedBox(height: 28),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onBrowseTap,
              style: ElevatedButton.styleFrom(
                backgroundColor: isDark ? Colors.white : Colors.black,
                foregroundColor: isDark ? Colors.black : Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                elevation: 0,
              ),
              child: Text(
                _browseLabel,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String get _title => switch (type) {
    ConnectMyEmptyStateType.feed => 'Your groups have been quiet',
    ConnectMyEmptyStateType.events => 'No upcoming events',
    ConnectMyEmptyStateType.posts => 'No posts yet',
    ConnectMyEmptyStateType.groups => 'No groups yet',
  };

  String get _subtitle => switch (type) {
    ConnectMyEmptyStateType.feed =>
      'Nothing new from the groups you have joined. Other groups are posting today.',
    ConnectMyEmptyStateType.events =>
      'None of your groups have anything scheduled. Other groups have events open to everyone.',
    ConnectMyEmptyStateType.posts =>
      'Your groups have not posted anything. See what other groups are sharing.',
    ConnectMyEmptyStateType.groups =>
      'You have not joined any groups yet. Discover communities to practice with.',
  };

  String get _browseLabel => switch (type) {
    ConnectMyEmptyStateType.feed => 'See what other groups share',
    ConnectMyEmptyStateType.events => 'Browse open events',
    ConnectMyEmptyStateType.posts => 'Browse other posts',
    ConnectMyEmptyStateType.groups => 'Discover groups',
  };
}
