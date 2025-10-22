import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/l10n/generated/app_localizations.dart';
import 'package:go_router/go_router.dart';
import '../../../../shared/widgets/reusable_youtube_player.dart';

class MeditationVideo extends StatelessWidget {
  final String videoUrl;
  const MeditationVideo({super.key, required this.videoUrl});

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () {
            context.pop();
          },
        ),
        title: Text(localizations.home_meditationTitle),
      ),
      body: ReusableYoutubePlayer(
        videoUrl: videoUrl,
        aspectRatio: 9 / 16,
        autoPlay: true,
        mute: false,
      ),
    );
  }
}
