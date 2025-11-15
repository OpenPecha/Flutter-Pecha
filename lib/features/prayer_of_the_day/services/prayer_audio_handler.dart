import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';

/// Audio handler for prayer audio playback with background support
class PrayerAudioHandler extends BaseAudioHandler with SeekHandler {
  final AudioPlayer _player = AudioPlayer();

  PrayerAudioHandler() {
    // Listen to player state changes and broadcast to the system
    _player.playbackEventStream.listen(_broadcastState);

    // Listen to player state to update playing status
    _player.playerStateStream.listen((state) {
      final playing = state.playing;
      final processingState = _getProcessingState(state.processingState);

      playbackState.add(
        playbackState.value.copyWith(
          playing: playing,
          processingState: processingState,
        ),
      );
    });

    // Listen to position updates
    _player.positionStream.listen((position) {
      playbackState.add(playbackState.value.copyWith(updatePosition: position));
    });

    // Listen to duration changes
    _player.durationStream.listen((duration) {
      mediaItem.add(mediaItem.value?.copyWith(duration: duration));
    });
  }

  AudioProcessingState _getProcessingState(ProcessingState state) {
    switch (state) {
      case ProcessingState.idle:
        return AudioProcessingState.idle;
      case ProcessingState.loading:
        return AudioProcessingState.loading;
      case ProcessingState.buffering:
        return AudioProcessingState.buffering;
      case ProcessingState.ready:
        return AudioProcessingState.ready;
      case ProcessingState.completed:
        return AudioProcessingState.completed;
    }
  }

  void _broadcastState(PlaybackEvent event) {
    playbackState.add(
      playbackState.value.copyWith(
        controls: [
          MediaControl.rewind,
          if (_player.playing) MediaControl.pause else MediaControl.play,
          MediaControl.fastForward,
          MediaControl.stop,
        ],
        systemActions: const {
          MediaAction.seek,
          MediaAction.seekForward,
          MediaAction.seekBackward,
        },
        androidCompactActionIndices: const [0, 1, 2],
        processingState: _getProcessingState(_player.processingState),
        playing: _player.playing,
        updatePosition: _player.position,
        bufferedPosition: _player.bufferedPosition,
        speed: _player.speed,
      ),
    );
  }

  /// Initialize and load audio source
  Future<Duration?> setAudioSource({
    required String url,
    required MediaItem item,
    Map<String, String>? headers,
  }) async {
    // Update the media item
    mediaItem.add(item);

    Duration? duration;
    if (url.startsWith('http://') || url.startsWith('https://')) {
      // Remote URL
      final source = AudioSource.uri(Uri.parse(url), headers: headers);
      duration = await _player.setAudioSource(source);
    } else {
      // Local asset
      duration = await _player.setAsset(url);
    }

    // Broadcast initial state
    _broadcastState(_player.playbackEvent);

    return duration;
  }

  @override
  Future<void> play() => _player.play();

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> seek(Duration position) => _player.seek(position);

  @override
  Future<void> stop() async {
    await _player.stop();
    await super.stop();
  }

  Future<void> skipForward() async {
    final newPosition = _player.position + const Duration(seconds: 10);
    final duration = _player.duration ?? Duration.zero;
    await _player.seek(newPosition < duration ? newPosition : duration);
  }

  Future<void> skipBackward() async {
    final newPosition = _player.position - const Duration(seconds: 10);
    await _player.seek(
      newPosition > Duration.zero ? newPosition : Duration.zero,
    );
  }

  @override
  Future<void> fastForward() => skipForward();

  @override
  Future<void> rewind() => skipBackward();

  @override
  Future<void> setSpeed(double speed) async {
    await _player.setSpeed(speed);
    playbackState.add(playbackState.value.copyWith(speed: speed));
  }

  /// Get the audio player instance for direct access to streams
  AudioPlayer get player => _player;

  /// Clean up resources
  Future<void> dispose() async {
    await _player.dispose();
  }
}
