import 'package:flutter/material.dart';
import 'package:flutter_pecha/core/l10n/generated/app_localizations.dart';
import 'package:flutter_pecha/core/widgets/audio_progress_bar.dart';
import 'package:flutter_pecha/features/home/models/prayer_data.dart';
import 'package:just_audio/just_audio.dart';
import 'package:go_router/go_router.dart';

class TextSegment {
  final String text;
  final Duration startTime;
  final Duration endTime;

  TextSegment({
    required this.text,
    required this.startTime,
    required this.endTime,
  });

  @override
  String toString() {
    return 'TextSegment(text: $text, startTime: $startTime, endTime: $endTime)';
  }

  factory TextSegment.fromJson(Map<String, String> json) {
    return TextSegment(
      text: json['text']!,
      startTime: _parseDuration(json['startTime']!),
      endTime: _parseDuration(json['endTime']!),
    );
  }

  static Duration _parseDuration(String timeStr) {
    final parts = timeStr.split(':');
    final minutes = int.parse(parts[0]);
    final seconds = int.parse(parts[1]);
    return Duration(minutes: minutes, seconds: seconds);
  }
}

class PrayerOfTheDayScreen extends StatefulWidget {
  final String audioUrl;
  final List<PrayerData> prayerData;
  const PrayerOfTheDayScreen({
    super.key,
    required this.audioUrl,
    required this.prayerData,
  });

  @override
  State<PrayerOfTheDayScreen> createState() => _PrayerOfTheDayScreenState();
}

class _PrayerOfTheDayScreenState extends State<PrayerOfTheDayScreen> {
  late AudioPlayer _audioPlayer;
  bool _isPlaying = false;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;
  final ScrollController _scrollController = ScrollController();
  // List<TextSegment> _textSegments = [];
  int _currentSegmentIndex = 0;
  final Map<int, GlobalKey> _segmentKeys = {};

  @override
  void initState() {
    super.initState();
    _initializeAudioPlayer();
    // _initializeTextSegments();
    // Initialize keys for each segment
    for (int i = 0; i < widget.prayerData.length; i++) {
      _segmentKeys[i] = GlobalKey();
    }
  }

  // void _initializeTextSegments() {
  //   _textSegments =
  //       prayerOfTheDayJson.map((json) => TextSegment.fromJson(json)).toList();
  // }

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
    _audioPlayer = AudioPlayer();
    try {
      final duration = await _audioPlayer.setAsset(
        // 'assets/audios/Tibetan_prayer.mp3',
        'assets/audios/monday_prayer.mp3',
      );
      if (mounted) {
        setState(() {
          _duration = duration ?? Duration.zero;
        });
      }
    } catch (e) {
      debugPrint('Error initializing audio player: $e');
    }

    _audioPlayer.positionStream.listen((pos) {
      if (mounted) {
        setState(() {
          _position = pos;
        });
        _updateCurrentSegment(pos);
      }
    });

    _audioPlayer.playerStateStream.listen((state) {
      if (mounted) {
        setState(() {
          _isPlaying = state.playing;
        });
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
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
                      fontFamily: 'Jomolhari',
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
                AudioProgressBar(
                  audioPlayer: _audioPlayer,
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
                      onPressed: () async {
                        final newPosition =
                            _position - const Duration(seconds: 10);
                        await _audioPlayer.seek(
                          newPosition > Duration.zero
                              ? newPosition
                              : Duration.zero,
                        );
                      },
                    ),
                    IconButton(
                      color: Theme.of(context).appBarTheme.foregroundColor,
                      icon: Icon(
                        _isPlaying
                            ? Icons.pause_circle_outline
                            : Icons.play_circle_outline,
                        size: 44,
                      ),
                      onPressed: () async {
                        if (_isPlaying) {
                          await _audioPlayer.pause();
                        } else {
                          await _audioPlayer.play();
                        }
                      },
                    ),
                    IconButton(
                      color: Theme.of(context).appBarTheme.foregroundColor,
                      icon: const Icon(Icons.forward_10, size: 32),
                      onPressed: () async {
                        final newPosition =
                            _position + const Duration(seconds: 10);
                        await _audioPlayer.seek(
                          newPosition < _duration ? newPosition : _duration,
                        );
                      },
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
                          _audioPlayer.speed,
                        );
                        if (currentSpeedIndex == -1) currentSpeedIndex = 0;
                        return IconButton(
                          color: Theme.of(context).appBarTheme.foregroundColor,
                          onPressed: () {
                            int nextIndex =
                                (currentSpeedIndex + 1) % speeds.length;
                            _audioPlayer.setSpeed(speeds[nextIndex]);
                            setState(() {});
                          },
                          icon: Text(
                            'x${_audioPlayer.speed == 1.0 ? 1 : _audioPlayer.speed.toStringAsFixed(1)}',
                            style: TextStyle(fontSize: 20),
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

const prayerText = """
སངས་རྒྱས་ཆོས་དང་ཚོགས་ཀྱི་མཆོག་རྣམས་ལ། །
བྱང་ཆུབ་བར་དུ་བདག་ནི་སྐྱབས་སུ་མཆི། །
བདག་གི་སྦྱིན་སོགས་བགྱིས་པའི་བསོད་ནམས་ཀྱིས། །
འགྲོ་ལ་ཕན་ཕྱིར་སངས་རྒྱས་འགྲུབ་པར་ཤོག །
ཐབས་མཁས་ཐུགས་རྗེ་ཤཱཀྱའི་རིགས་སུ་འཁྲུངས། །
གཞན་གྱིས་མི་ཐུབ་བདུད་ཀྱི་དཔུང་འཇོམས་པ། །
གསེར་གྱི་ལྷུན་པོ་ལྟ་བུར་བརྗིད་པའི་སྐུ། །
ཤཱཀྱའི་རྒྱལ་པོ་ཁྱོད་ལ་ཕྱག་འཚལ་ལོ། །
གང་གིས་དང་པོར་བྱང་ཆུབ་ཐུགས་བསྐྱེད་ནས། །
བསོད་ནམས་ཡེ་ཤེས་ཚོགས་གཉིས་རྫོགས་མཛད་ཅིང་། །
དུས་འདིར་མཛད་པ་རྒྱ་ཆེན་འགྲོ་བ་ཡི། །
མགོན་གྱུར་ཁྱོད་ལ་བདག་གིས་བསྟོད་པར་བགྱི། །
ལྷ་རྣམས་དོན་མཛད་འདུལ་བའི་དུས་མཁྱེན་ནས། །
ལྷ་ལས་བབས་ནས་གླང་ཆེན་ལྟར་གཤེགས་ཤིང་། །
རིགས་ལ་གཟིགས་ནས་ལྷ་མོ་སྒྱུ་འཕྲུལ་མའི། །
ལྷུམས་སུ་ཞུགས་པར་མཛད་ལ་ཕྱག་འཚལ་ལོ། །
ཟླ་བ་བཅུ་རྫོགས་ཤཱཀྱའི་སྲས་པོ་ནི། །
བཀྲ་ཤིས་ལུམྦིའི་ཚལ་དུ་བལྟམས་པའི་ཚེ། །
ཚངས་དང་བརྒྱ་བྱིན་གྱིས་བཏུད་མཚན་མཆོག་ནི། །
བྱང་ཆུབ་རིགས་སུ་ངེས་མཛད་ཕྱག་འཚལ་ལོ། །
གཞོན་ནུ་སྟོབས་ལྡན་མི་ཡི་སེང་གེ་དེས། །
ཨ་གྷ་མ་ག་དྷར་ནི་སྒྱུ་རྩལ་བསྟན། །
སྐྱེ་བོ་དྲེགས་པ་ཅན་རྣམས་ཚར་བཅད་ནས། །
འགྲན་ཟླ་མེད་པར་མཛད་ལ་ཕྱག་འཚལ་ལོ། །
འཇིག་རྟེན་ཆོས་དང་མཐུན་པར་བྱ་བ་དང་། །
ཁ་ན་མ་ཐོ་སྤང་ཕྱིར་བཙུན་མོ་ཡི། །
འཁོར་དང་ལྡན་མཛད་ཐབས་ལ་མཁས་པ་ཡིས། །
རྒྱལ་སྲིད་སྐྱོང་བར་མཛད་ལ་ཕྱག་འཚལ་ལོ། །
འཁོར་བའི་བྱ་བར་སྙིང་པོ་མེད་གཟིགས་ནས། །
ཁྱིམ་ནས་བྱུང་སྟེ་མཁའ་ལ་གཤེགས་ནས་ཀྱང་། །
མཆོད་རྟེན་རྣམ་དག་དྲུང་དུ་ཉིད་ལས་ཉིད། །
རབ་ཏུ་བྱུང་བར་མཛད་ལ་ཕྱག་འཚལ་ལོ། །
བརྩོན་པས་བྱང་ཆུབ་སྒྲུབ་པར་དགོངས་ནས་ནི། །
ནཻ་རཉྫ་ནའི་འགྲམ་དུ་ལོ་དྲུག་ཏུ། །
དཀའ་བ་སྤྱད་མཛད་བརྩོན་འགྲུས་མཐར་ཕྱིན་པས། །
བསམ་གཏན་མཆོག་བརྙེས་མཛད་ལ་ཕྱག་འཚལ་ལོ། །
ཐོག་མ་མེད་ནས་འབད་པ་དོན་ཡོད་ཕྱིར། །
མ་ག་དྷ་ཡི་བྱང་ཆུབ་ཤིང་དྲུང་དུ། །
སྐྱིལ་ཀྲུང་མི་གཡོ་མངོན་པར་སངས་རྒྱས་ནས། །
བྱང་ཆུབ་རྫོགས་པར་མཛད་ལ་ཕྱག་འཚལ་ལོ། །
ཐུགས་རྗེས་འགྲོ་ལ་མྱུར་དུ་གཟིགས་ནས་ནི། །
ཝ་ར་ཎཱ་སི་ལ་སོགས་གནས་མཆོག་ཏུ། །
ཆོས་ཀྱི་འཁོར་ལོ་བསྐོར་ནས་གདུལ་བྱ་རྣམས། །
ཐེག་པ་གསུམ་ལ་འགོད་མཛད་ཕྱག་འཚལ་ལོ། །
གཞན་གྱི་རྒོལ་བ་ངན་པ་ཚར་བཅད་ཕྱིར། །
མུ་སྟེགས་སྟོན་པ་དྲུག་དང་ལྷས་བྱིན་སོགས། །
འཁོར་མོ་འཇིག་གི་ཡུལ་དུ་བདུད་རྣམས་བཏུལ། །
ཐུབ་པ་གཡུལ་ལས་རྒྱལ་ལ་ཕྱག་འཚལ་ལོ། །
སྲིད་པ་གསུམ་ན་དཔེ་མེད་ཡོན་ཏན་གྱི། །
མཉན་དུ་ཡོད་པར་ཆོ་འཕྲུལ་ཆེན་པོ་བསྟན། །
ལྷ་མི་འགྲོ་བ་ཀུན་གྱིས་རབ་མཆོད་པ། །
བསྟན་པ་རྒྱས་པར་མཛད་ལ་ཕྱག་འཚལ་ལོ། །
ལེ་ལོ་ཅན་རྣམས་ཆོས་ལ་བསྐུལ་བྱའི་ཕྱིར། །
རྩྭ་མཆོག་གྲོང་གི་ས་གཞི་གཙང་མ་རུ། །
འཆི་མེད་རྡོ་རྗེ་ལྟ་བུའི་སྐུ་གཤེགས་ནས། །
མྱ་ངན་འདའ་བར་མཛད་ལ་ཕྱག་འཚལ་ལོ། །
ཡང་དག་ཉིད་དུ་འཇིག་པ་མེད་ཕྱིར་དང་། །
མ་འོངས་སེམས་ཅན་བསོད་ནམས་ཐོབ་བྱའི་ཕྱིར། །
དེ་ཉིད་དུ་ནི་རིང་བསྲེལ་མང་སྤྲུལ་ནས། །
སྐུ་གདུང་ཆ་བརྒྱད་མཛད་ལ་ཕྱག་འཚལ་ལོ། །
༈ གང་ཚེ་རྐང་གཉིས་གཙོ་བོ་ཁྱོད་བལྟམས་ཚེ། །
ས་ཆེན་འདི་ལ་གོམ་པ་བདུན་བོར་ནས། །
ང་ནི་འཇིག་རྟེན་འདི་ན་མཆོག་ཅེས་གསུངས། །
དེ་ཚེ་མཁས་པ་ཁྱོད་ལ་ཕྱག་འཚལ་ལོ། །
དང་པོ་དགའ་ལྡན་ལྷ་ཡི་ཡུལ་ནས་བྱོན། །
རྒྱལ་པོའི་ཁབ་ཏུ་ཡུམ་གྱི་ལྷུམས་སུ་ཞུགས། །
ལུམྦི་ནི་ཡི་ཚལ་དུ་ཐུབ་པ་བལྟམས། །
བཅོམ་ལྡན་ལྷ་ཡི་ལྷ་ལ་ཕྱག་འཚལ་ལོ། །
གཞལ་ཡས་ཁང་དུ་མ་མ་བརྒྱད་བཞིས་མཆོད། །
ཤཱཀྱའི་གྲོང་དུ་གཞོན་ནུས་རོལ་རྩེད་མཛད། །
སེར་སྐྱའི་གནས་སུ་ས་འཚོ་ཁབ་ཏུ་བཞེས། །
སྲིད་གསུམ་མཚུངས་མེད་སྐུ་ལ་ཕྱག་འཚལ་ལོ། །
གྲོང་ཁྱེར་སྒོ་བཞིར་སྐྱོ་བའི་ཚུལ་བསྟན་ནས། །
མཆོད་རྟེན་རྣམ་དག་དྲུང་དུ་དབུ་སྐྲ་བསིལ། །
ནཻ་རཉྫ་ནའི་འགྲམ་དུ་དཀའ་ཐུབ་མཛད། །
སྒྲིབ་གཉིས་སྐྱོན་དང་བྲལ་ལ་ཕྱག་འཚལ་ལོ། །
རྒྱལ་པོའི་ཁབ་ཏུ་གླང་ཆེན་སྨྱོན་པ་བཏུལ། །
ཡངས་པ་ཅན་དུ་སྤྲེའུས་སྦྲང་རྩི་ཕུལ། །
མ་ག་དྷ་རུ་ཐུབ་པ་མངོན་སངས་རྒྱས། །
མཁྱེན་པའི་ཡེ་ཤེས་འབར་ལ་ཕྱག་འཚལ་ལོ། །
ཝ་ར་ཎཱ་སིར་ཆོས་ཀྱི་འཁོར་ལོ་བསྐོར། །
ཛེ་ཏའི་ཚལ་དུ་ཆོ་འཕྲུལ་ཆེན་པོ་བསྟན། །
རྩྭ་མཆོག་གྲོང་དུ་དགོངས་པ་མྱ་ངན་འདས། །
ཐུགས་ནི་ནམ་མཁའ་འདྲ་ལ་ཕྱག་འཚལ་ལོ། །
འདི་ལྟར་བསྟན་པའི་བདག་པོ་བཅོམ་ལྡན་འདས། །
མཛད་པའི་ཚུལ་ལ་མདོ་ཙམ་བསྟོད་པ་ཡི། །
དགེ་བས་འགྲོ་བ་ཀུན་གྱི་སྤྱོད་པ་ཡང་། །
བདེ་གཤེགས་ཉིད་ཀྱི་མཛད་དང་མཚུངས་པར་ཤོག །
དེ་བཞིན་གཤེགས་པ་ཁྱེད་སྐུ་ཅི་འདྲ་དང་། །
འཁོར་དང་སྐུ་ཚེའི་ཚད་དང་ཞིང་ཁམས་དང་། །
ཁྱེད་ཀྱི་མཚན་མཆོག་བཟང་པོ་ཅི་འདྲ་བ། །
དེ་འདྲ་ཁོ་ནར་བདག་སོགས་འགྱུར་བར་ཤོག །
ཁྱེད་ལ་བསྟོད་ཅིང་གསོལ་བ་བཏབ་པའི་མཐུས། །
བདག་སོགས་གང་དུ་གནས་པའི་ས་ཕྱོགས་སུ། །
ནད་དང་དབུལ་ཕོངས་འཐབ་རྩོད་ཞི་བ་དང་། །
ཆོས་དང་བཀྲ་ཤིས་འཕེལ་བར་མཛད་དུ་གསོལ། །
སྟོན་པ་འཇིག་རྟེན་ཁམས་སུ་འབྱོན་པ་དང་། །
བསྟན་པ་ཉི་འོད་བཞིན་དུ་གསལ་བ་དང་། །
བསྟན་འཛིན་བུ་སློབ་དར་ཞིང་རྒྱས་པ་ཡིས། །
བསྟན་པ་ཡུན་རིང་གནས་པའི་བཀྲ་ཤིས་ཤོག། །།
""";
