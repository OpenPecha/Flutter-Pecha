import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/config/locale_provider.dart';
import 'package:flutter_pecha/features/creator_info/widgets/social_media_section.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CreatorInfoScreen extends ConsumerWidget {
  const CreatorInfoScreen({super.key});

  static const List<String> _planItems = ["Medicine Buddha Healing"];

  static const credits = [
    {
      "language": "bo",
      "name": "ཡེ་ཤེས་ལྷུན་གྲུབ།",
      "bio":
          "ཡེ་ཤེས་ལྷུན་གྲུབ་ནི་ནང་པ་ཞིག་ཡིན་པ་དང་། ཁོང་གིས་དབྱིན་ཡིག་ཐོག་ཏུ་བརྩེ་བ་དང་ཤེས་རབ་གཉིས་བསྡོམས་ན་བདེ་བ་ཡིན་ཞེས་པའི་དེབ་ཅིག་བྲིས་ཡོད།",
    },
    {
      "language": "zh",
      "name": "耶喜嘉措（Jay）",
      "bio": "希望能把佛法的內容以現代化的方式，傳達給所有對佛法有興趣的人。",
    },
    {"language": "en", "name": "Kevin", "bio": "大家好，我是Kevin, 來自台灣。"},
  ];

  static const socialMedia = [
    {"account": "email", "url": "kevin@gmail.com"},
    {
      "account": "facebook",
      "url": "https://www.facebook.com/profile.php?id=100063506767189",
    },
    {
      "account": "linkedin",
      "url": "https://www.linkedin.com/in/kevin-chen-63506350635063506350/",
    },
    {"account": "youtube", "url": "https://www.youtube.com/kevin.chen/"},
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final language = ref.watch(localeProvider);
    final currentLanguage = language?.languageCode ?? 'en';
    final currentCredits = credits.firstWhere(
      (credit) => credit['language'] == currentLanguage,
      orElse: () => credits.firstWhere((credit) => credit['language'] == 'en'),
    );
    return Scaffold(
      appBar: AppBar(),
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context, currentCredits),
            _buildBioSection(context, currentCredits),
            _buildFeaturedPlanSection(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    Map<String, dynamic> currentCredits,
  ) {
    return Column(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 50,
              backgroundImage: const AssetImage('assets/images/pecha_logo.png'),
              backgroundColor: Colors.grey[800],
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Text(
                        currentCredits['name'],
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Wrap(
                      alignment: WrapAlignment.start,
                      children: [
                        ...socialMedia.map(
                          (item) => SocialMediaSection(item: item),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBioSection(
    BuildContext context,
    Map<String, dynamic> currentCredits,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 16.0),
      child: Text(
        currentCredits['bio'],
        style: TextStyle(fontSize: 15, height: 1.7),
        softWrap: true,
        overflow: TextOverflow.visible,
      ),
    );
  }

  Widget _buildFeaturedPlanSection(BuildContext context) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Featured Plan',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView(
                children: [
                  ..._planItems.map((item) => _buildPlanItem(context, item)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlanItem(BuildContext context, String title) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: Theme.of(context).appBarTheme.foregroundColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 16),
          Text(title, style: const TextStyle(fontSize: 14)),
        ],
      ),
    );
  }
}
