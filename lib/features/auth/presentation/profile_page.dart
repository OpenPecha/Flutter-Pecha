import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../application/auth_provider.dart';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);

    if (authState.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (!authState.isLoggedIn || authState.userProfile == null) {
      return const Scaffold(body: Center(child: Text('Not logged in')));
    }

    final user = authState.userProfile!;
    final pictureUrl = user.pictureUrl?.toString();
    final fullName =
        (user.name ?? _joinNames(user.givenName, user.familyName)).trim();
    final email = user.email ?? '';
    final bio = "Welcome to WeBuddhist";
    final location = _deriveLocation(user);

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Row(
              children: [
                Center(
                  child: Hero(
                    tag: 'profile-avatar',
                    child: CircleAvatar(
                      radius: 48,
                      backgroundColor: Colors.grey.shade300,
                      backgroundImage:
                          pictureUrl != null && pictureUrl.isNotEmpty
                              ? NetworkImage(pictureUrl)
                              : null,
                      child:
                          (pictureUrl == null || pictureUrl.isEmpty)
                              ? Text(
                                _initialsFromName(fullName),
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black54,
                                ),
                              )
                              : null,
                    ),
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        fullName.isNotEmpty
                            ? fullName
                            : (user.nickname ?? 'Anonymous'),
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 4),
                      Text(email, style: Theme.of(context).textTheme.bodyLarge),
                      const SizedBox(height: 4),
                      if (bio.isNotEmpty)
                        Text(
                          bio,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyLarge
                              ?.copyWith(color: Colors.black87),
                        ),
                      if (bio.isNotEmpty) const SizedBox(height: 8),
                      if (location.isNotEmpty)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            const Icon(Icons.location_on_outlined, size: 18),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                location,
                                style: Theme.of(context).textTheme.bodySmall,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static String _initialsFromName(String name) {
    if (name.trim().isEmpty) return '?';
    final parts = name.trim().split(RegExp(r"\s+"));
    final first =
        parts.isNotEmpty && parts.first.isNotEmpty ? parts.first[0] : '';
    final last = parts.length > 1 && parts.last.isNotEmpty ? parts.last[0] : '';
    return (first + last).toUpperCase();
  }

  static String _joinNames(String? given, String? family) {
    final g = (given ?? '').trim();
    final f = (family ?? '').trim();
    return [g, f].where((e) => e.isNotEmpty).join(' ');
  }

  static String _deriveLocation(user) {
    final address = user.address as Map<String, String>?;
    final locality = address?['locality'];
    final region = address?['region'];
    final country = address?['country'];
    final zoneinfo = user.zoneinfo as String?;
    final locale = user.locale as String?;
    final candidates =
        [locality, region, country, zoneinfo, locale]
            .whereType<String>()
            .map((s) => s.trim())
            .where((s) => s.isNotEmpty)
            .toList();
    return candidates.isNotEmpty ? candidates.first : "San Francisco, CA";
  }
}
