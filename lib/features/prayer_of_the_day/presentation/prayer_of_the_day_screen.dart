import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/l10n/generated/app_localizations.dart';
import 'package:flutter_pecha/core/services/audio/audio_handler.dart';
import 'package:flutter_pecha/core/services/service_providers.dart';
import 'package:flutter_pecha/core/utils/app_logger.dart';
import 'package:flutter_pecha/core/widgets/audio_progress_bar.dart';
import 'package:flutter_pecha/features/home/models/prayer_data.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import 'package:audio_service/audio_service.dart';
import 'package:go_router/go_router.dart';

class PrayerOfTheDayScreen extends ConsumerStatefulWidget {
  final String audioUrl;
  final List<PrayerData> prayerData;
  final Map<String, String>? audioHeaders;

  const PrayerOfTheDayScreen({
    super.key,
    required this.audioUrl,
    required this.prayerData,
    this.audioHeaders,
  });

  @override
  ConsumerState<PrayerOfTheDayScreen> createState() =>
      _PrayerOfTheDayScreenState();
}

class _PrayerOfTheDayScreenState extends ConsumerState<PrayerOfTheDayScreen> {
  final _logger = AppLogger('PrayerOfTheDayScreen');
  AudioPlayer? _audioPlayer;
  bool _isPlaying = false;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  final ScrollController _scrollController = ScrollController();
  int _currentSegmentIndex = 0;
  final Map<int, GlobalKey> _segmentKeys = {};
  bool _isAudioInitialized = false;
  // Store the audio handler reference early (nullable if service failed to initialize)
  AppAudioHandler? _audioHandler;

  @override
  void initState() {
    super.initState();
    // Initialize keys for each segment
    for (int i = 0; i < widget.prayerData.length; i++) {
      _segmentKeys[i] = GlobalKey();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isAudioInitialized) {
      _isAudioInitialized = true;
      // Store the audio handler reference immediately
      final handler = ref.read(appAudioHandlerProvider);
      if (handler != null) {
        _audioHandler = handler;
        _initializeAudioPlayer();
      }
    }
  }

  void _scrollToCurrentSegment() {
    if (_currentSegmentIndex >= 0 &&
        _currentSegmentIndex < widget.prayerData.length) {
      final currentKey = _segmentKeys[_currentSegmentIndex];
      if (currentKey?.currentContext != null && _scrollController.hasClients) {
        final RenderBox renderBox =
            currentKey!.currentContext!.findRenderObject() as RenderBox;
        final RenderBox listViewBox =
            _scrollController.position.context.storageContext.findRenderObject()
                as RenderBox;

        // Position of the segment relative to the ListView
        final segmentOffset =
            renderBox.localToGlobal(Offset.zero, ancestor: listViewBox).dy;
        final segmentHeight = renderBox.size.height;
        final viewportHeight = _scrollController.position.viewportDimension;
        final maxScroll = _scrollController.position.maxScrollExtent;
        final currentScroll = _scrollController.offset;

        // Calculate the target scroll position for centering
        final targetScroll =
            currentScroll +
            segmentOffset -
            (viewportHeight / 2 - segmentHeight / 2);

        // Check if we're at the last segment
        final isLastSegment =
            _currentSegmentIndex == widget.prayerData.length - 1;

        // Check if the segment is already fully visible
        final isFullyVisible =
            segmentOffset >= 0 &&
            segmentOffset + segmentHeight <= viewportHeight;

        // If it's the last segment and it's already fully visible, don't scroll
        if (isLastSegment && isFullyVisible) {
          return;
        }

        // If we're near the end of the text, adjust the scroll to keep the segment visible
        if (targetScroll > maxScroll - viewportHeight / 2) {
          _scrollController.animateTo(
            maxScroll,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        } else if (segmentOffset + segmentHeight > viewportHeight / 2) {
          _scrollController.animateTo(
            targetScroll,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        }
      }
    }
  }

  void _updateCurrentSegment(Duration position) {
    for (int i = 0; i < widget.prayerData.length; i++) {
      if (position >= widget.prayerData[i].startTime &&
          position < widget.prayerData[i].endTime) {
        if (_currentSegmentIndex != i) {
          setState(() {
            _currentSegmentIndex = i;
          });
          _scrollToCurrentSegment();
        }
        break;
      }
    }
  }

  Future<void> _initializeAudioPlayer() async {
    try {
      final url = widget.audioUrl.trim();
      final localizations = AppLocalizations.of(context)!;

      // Use the stored audio handler reference
      _audioPlayer = _audioHandler!.player;

      // Create MediaItem for background playback
      final mediaItem = MediaItem(
        id: 'prayer_of_day',
        album: 'WeBuddhist',
        title: localizations.home_prayerTitle,
        artUri: Uri.parse('https://pecha.org/static/icons/favicon-pecha.png'),
      );

      // Load the audio source
      final duration = await _audioHandler!.setAudioSource(
        url: url,
        item: mediaItem,
        headers: widget.audioHeaders,
      );

      if (mounted) {
        setState(() {
          _duration = duration ?? Duration.zero;
        });
      }

      // Listen to position updates for text synchronization
      _audioPlayer!.positionStream.listen((pos) {
        if (mounted) {
          setState(() {
            _position = pos;
          });
          _updateCurrentSegment(pos);
        }
      });

      // Listen to player state changes
      _audioPlayer!.playerStateStream.listen((state) {
        if (mounted) {
          setState(() {
            _isPlaying = state.playing;
          });

          // Handle audio completion
          if (state.processingState == ProcessingState.completed) {
            setState(() {
              _isPlaying = false;
              _currentSegmentIndex = 0;
              _position = Duration.zero;
            });
          }
        }
      });
    } catch (e) {
      _logger.error('Error initializing audio player', e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Unable to load audio. Please check your connection and try again.',
            ),
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    // Stop audio when leaving the screen using the stored reference
    _audioHandler?.stop();
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
            _audioHandler!.stop();
            context.pop();
          },
        ),
        title: Text(localizations.home_prayerTitle),
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 12.0,
              ),
              itemCount: widget.prayerData.length,
              itemBuilder: (context, index) {
                final segment = widget.prayerData[index];
                final isCurrentSegment = index == _currentSegmentIndex;
                return Container(
                  key: _segmentKeys[index],
                  child: Text(
                    segment.text,
                    style: TextStyle(
                      fontSize: 20,
                      height: 1.5,
                      color:
                          isCurrentSegment
                              ? Theme.of(context).primaryColor
                              : null,
                      fontWeight:
                          isCurrentSegment
                              ? FontWeight.w600
                              : FontWeight.normal,
                    ),
                    textAlign: TextAlign.left,
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 16, right: 16, bottom: 28),
            child: Column(
              children: [
                // Progress bar
                if (_audioPlayer != null)
                  AudioProgressBar(
                    audioPlayer: _audioPlayer!,
                    duration: _duration,
                    position: _position,
                  ),
                const SizedBox(height: 8),
                // Controls
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      color: Theme.of(context).appBarTheme.foregroundColor,
                      icon: const Icon(Icons.close, size: 28),
                      onPressed: () => context.pop(),
                      padding: EdgeInsets.zero,
                    ),
                    IconButton(
                      color: Theme.of(context).appBarTheme.foregroundColor,
                      icon: const Icon(Icons.replay_10, size: 32),
                      onPressed:
                          _audioHandler != null
                              ? () => _audioHandler!.skipBackward()
                              : null,
                    ),
                    IconButton(
                      color: Theme.of(context).appBarTheme.foregroundColor,
                      icon: Icon(
                        _isPlaying
                            ? Icons.pause_circle_outline
                            : Icons.play_circle_outline,
                        size: 44,
                      ),
                      onPressed:
                          _audioHandler != null
                              ? () {
                                if (_isPlaying) {
                                  _audioHandler!.pause();
                                } else {
                                  _audioHandler!.play();
                                }
                              }
                              : null,
                    ),
                    IconButton(
                      color: Theme.of(context).appBarTheme.foregroundColor,
                      icon: const Icon(Icons.forward_10, size: 32),
                      onPressed:
                          _audioHandler != null
                              ? () => _audioHandler!.skipForward()
                              : null,
                    ),
                    StatefulBuilder(
                      builder: (context, setState) {
                        final List<double> speeds = [
                          1.0,
                          0.6,
                          0.7,
                          0.8,
                          0.9,
                          1.0,
                        ];
                        int currentSpeedIndex = speeds.indexOf(
                          _audioPlayer?.speed ?? 1.0,
                        );
                        if (currentSpeedIndex == -1) currentSpeedIndex = 0;
                        return IconButton(
                          color: Theme.of(context).appBarTheme.foregroundColor,
                          onPressed:
                              _audioHandler != null
                                  ? () {
                                    int nextIndex =
                                        (currentSpeedIndex + 1) % speeds.length;
                                    _audioHandler!.setSpeed(speeds[nextIndex]);
                                    setState(() {});
                                  }
                                  : null,
                          icon: Text(
                            'x${(_audioPlayer?.speed ?? 1.0) == 1.0 ? 1 : (_audioPlayer?.speed ?? 1.0).toStringAsFixed(1)}',
                            style: const TextStyle(fontSize: 20),
                          ),
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
