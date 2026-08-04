import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/constants/app_assets.dart';
import 'package:flutter_pecha/core/extensions/context_ext.dart';
import 'package:flutter_pecha/features/group_profile/domain/entities/group_profile.dart';

abstract final class GroupProfileLinkUtils {
  static List<GroupProfileSocialLink> orderedLinks(
    List<GroupProfileSocialLink> links,
  ) {
    final website =
        links.where((l) => l.platform.toLowerCase() == 'website').toList();
    final others =
        links.where((l) => l.platform.toLowerCase() != 'website').toList();
    return [...website, ...others];
  }

  static IconData iconForPlatform(String platform) {
    switch (platform.toLowerCase()) {
      case 'instagram':
        return AppAssets.instagram;
      case 'facebook':
        return AppAssets.facebook;
      case 'twitter':
      case 'x':
        return AppAssets.twitter;
      case 'youtube':
        return AppAssets.youtube;
      case 'tiktok':
        return AppAssets.tiktok;
      case 'linkedin':
        return AppAssets.linkedin;
      case 'website':
        return AppAssets.linkSimple;
      default:
        return AppAssets.link;
    }
  }

  static String labelForPlatform(String platform, BuildContext context) {
    switch (platform.toLowerCase()) {
      case 'website':
        return context.l10n.about_social_website;
      case 'instagram':
        return 'Instagram';
      case 'facebook':
        return 'Facebook';
      case 'twitter':
      case 'x':
        return 'X (Twitter)';
      case 'youtube':
        return 'YouTube';
      case 'tiktok':
        return 'TikTok';
      case 'linkedin':
        return 'LinkedIn';
      default:
        return platform.isNotEmpty
            ? platform[0].toUpperCase() + platform.substring(1)
            : context.l10n.about_social_website;
    }
  }
}
