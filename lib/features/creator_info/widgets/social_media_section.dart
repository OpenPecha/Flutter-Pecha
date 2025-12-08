import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class SocialMediaSection extends StatelessWidget {
  const SocialMediaSection({super.key, required this.item});
  final Map<String, dynamic> item;

  void launchSocialUrl(BuildContext context, String url) async {
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (context.mounted) {
          _showErrorSnackBar(context, 'Cannot open this link');
        }
      }
    } catch (e) {
      if (context.mounted) {
        _showErrorSnackBar(context, 'Invalid URL format');
      }
    }
  }

  void launchEmail(BuildContext context, String email) async {
    try {
      if (await canLaunchUrl(Uri.parse(email))) {
        await launchUrl(Uri.parse('mailto:$email'));
      } else {
        if (context.mounted) {
          _showErrorSnackBar(context, 'Cannot open this email');
        }
      }
    } catch (e) {
      if (context.mounted) {
        _showErrorSnackBar(context, 'Invalid email format');
      }
    }
  }

  void _showErrorSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  IconData getIcon(String account) {
    switch (account) {
      case 'email':
        return FontAwesomeIcons.envelope;
      case 'facebook':
        return FontAwesomeIcons.facebook;
      case 'linkedin':
        return FontAwesomeIcons.linkedin;
      case 'youtube':
        return FontAwesomeIcons.youtube;
      case 'twitter':
      case 'x':
        return FontAwesomeIcons.twitter;
      default:
        return FontAwesomeIcons.link;
    }
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        if (item['account'] == 'email') {
          launchEmail(context, item['url']);
        } else {
          launchSocialUrl(context, item['url']);
        }
      },
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: FaIcon(
          getIcon(item['account']),
          size: 22,
          color: Theme.of(context).iconTheme.color,
        ),
      ),
    );
  }
}
