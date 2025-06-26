import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/l10n/generated/app_localizations.dart';
import 'package:flutter_pecha/core/widgets/audio_controls.dart';
import 'package:flutter_pecha/core/widgets/audio_progress_bar.dart';
import 'package:just_audio/just_audio.dart';
import 'package:go_router/go_router.dart';

class MeditationOfTheDayScreen extends StatefulWidget {
  final String audioUrl;
  final String imageUrl;
  const MeditationOfTheDayScreen({
    super.key,
    required this.audioUrl,
    required this.imageUrl,
  });

  @override
  State<MeditationOfTheDayScreen> createState() =>
      _MeditationOfTheDayScreenState();
}

class _MeditationOfTheDayScreenState extends State<MeditationOfTheDayScreen> {
  late AudioPlayer _audioPlayer;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;

  @override
  void initState() {
    super.initState();
    _initializeAudioPlayer();
  }

  Future<void> _initializeAudioPlayer() async {
    try {
      _audioPlayer = AudioPlayer();

      // Set up listeners before loading audio
      _audioPlayer.durationStream.listen((duration) {
        if (mounted) {
          setState(() {
            _duration = duration ?? Duration.zero;
          });
        }
      });

      _audioPlayer.positionStream.listen((pos) {
        if (mounted) {
          setState(() {
            _position = pos;
          });
        }
      });

      // Load and play audio for url
      // await _audioPlayer.setUrl(widget.audioUrl);
      // for assets
      await _audioPlayer.setAsset("assets/audios/monday_meditation.mp3");
      if (mounted) {
        await _audioPlayer.play();
      }
    } catch (e) {
      debugPrint('Error initializing audio player: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load meditation audio: ${e.toString()}'),
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _audioPlayer.stop();
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () {
            _audioPlayer.stop();
            context.pop();
          },
        ),
        title: Text(localizations.home_meditationTitle),
        centerTitle: true,
        elevation: 0,
      ),
      body: Column(
        children: [
          const SizedBox(height: 40),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                widget.imageUrl,
                fit: BoxFit.cover,
                width: double.infinity,
                frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
                  if (wasSynchronouslyLoaded) return child;
                  return AnimatedOpacity(
                    opacity: frame == null ? 0 : 1,
                    duration: const Duration(milliseconds: 300),
                    child: child,
                  );
                },
                loadingBuilder: (context, child, loadingProgress) {
                  return child;
                },
              ),
            ),
          ),
          // Audio player controls
          Padding(
            padding: const EdgeInsets.only(
              left: 16.0,
              right: 16.0,
              top: 0.0,
              bottom: 16.0,
            ),
            child: Column(
              children: [
                // Progress bar
                AudioProgressBar(
                  audioPlayer: _audioPlayer,
                  duration: _duration,
                  position: _position,
                ),
                // Controls
                AudioControls(
                  audioPlayer: _audioPlayer,
                  duration: _duration,
                  position: _position,
                ),
                const SizedBox(height: 28),
                // Row(
                //   mainAxisAlignment: MainAxisAlignment.spaceBetween,
                //   children: [
                //     IconButton(
                //       color: Theme.of(context).appBarTheme.foregroundColor,
                //       icon: const Icon(Icons.close, size: 28),
                //       onPressed: () => context.pop(),
                //     ),
                //     IconButton(
                //       color: Theme.of(context).appBarTheme.foregroundColor,
                //       icon: const Icon(Icons.music_note, size: 28),
                //       onPressed: () {},
                //     ),
                //     StatefulBuilder(
                //       builder: (context, setState) {
                //         final List<double> speeds = [
                //           1.0,
                //           0.6,
                //           0.7,
                //           0.8,
                //           0.9,
                //           1.0,
                //         ];
                //         int currentSpeedIndex = speeds.indexOf(
                //           _audioPlayer.speed,
                //         );
                //         if (currentSpeedIndex == -1) currentSpeedIndex = 0;
                //         return IconButton(
                //           color: Theme.of(context).appBarTheme.foregroundColor,
                //           onPressed: () {
                //             int nextIndex =
                //                 (currentSpeedIndex + 1) % speeds.length;
                //             _audioPlayer.setSpeed(speeds[nextIndex]);
                //             setState(() {});
                //           },
                //           icon: Text(
                //             'x${_audioPlayer.speed == 1.0 ? 1 : _audioPlayer.speed.toStringAsFixed(1)}',
                //             style: TextStyle(fontSize: 20),
                //           ),
                //         );
                //       },
                //     ),
                //   ],
                // ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
