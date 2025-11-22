import 'dart:io';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';

/// Audio player service with background support and system controls.
class AudioPlayerService {
  final AudioPlayer _player = AudioPlayer();
  List<File> _originalFiles = [];

  AudioPlayer get player => _player;

  /// Get current shuffle mode
  bool get isShuffleEnabled => _player.shuffleModeEnabled;
  
  /// Get current loop mode
  LoopMode get loopMode => _player.loopMode;

  /// Set shuffle mode
  Future<void> setShuffleMode(bool enabled) async {
    await _player.setShuffleModeEnabled(enabled);
  }

  /// Set loop mode (off, one, all)
  Future<void> setLoopMode(LoopMode mode) async {
    await _player.setLoopMode(mode);
  }

  /// Toggle shuffle mode
  Future<void> toggleShuffle() async {
    await setShuffleMode(!isShuffleEnabled);
  }

  /// Cycle through loop modes: one -> off -> one
  Future<void> toggleLoopMode() async {
    switch (loopMode) {
      case LoopMode.all:
        await setLoopMode(LoopMode.one);
        break;
      case LoopMode.one:
        await setLoopMode(LoopMode.off);
        break;
      case LoopMode.off:
        await setLoopMode(LoopMode.one);
        break;
    }
  }

  /// Reorder files in the playlist
  Future<void> reorderFiles(List<File> newOrder) async {
    _originalFiles = List.from(newOrder);
    await loadFiles(_originalFiles);
  }

  /// Load a list of local files and prepare a playlist for playback.
  /// Each file gets proper MediaItem metadata for notifications and lockscreen.
  Future<void> loadFiles(List<File> files) async {
    _originalFiles = List.from(files);
    final sequence = <AudioSource>[];

    for (int i = 0; i < files.length; i++) {
      final f = files[i];
      final fileName = f.uri.pathSegments.isNotEmpty ? f.uri.pathSegments.last : f.path;
      final title = fileName.replaceAll(RegExp(r'\.[^.]*$'), ''); // Remove extension
      
      // Create MediaItem for notification and lockscreen controls
      final mediaItem = MediaItem(
        id: f.path,
        album: 'Local Music',
        title: title,
        artist: 'Unknown Artist',
        genre: 'Audio',
        duration: null, // Will be set when duration is known
        artUri: null,
        playable: true,
        extras: {'index': i, 'filePath': f.path},
      );

      final uri = Uri.file(f.path);
      sequence.add(AudioSource.uri(uri, tag: mediaItem));
    }

    if (sequence.isNotEmpty) {
      final playlist = ConcatenatingAudioSource(children: sequence);
      await _player.setAudioSource(playlist, preload: false);
      // Set default loop mode to all
      await _player.setLoopMode(LoopMode.all);
    }
  }

  Future<void> play() => _player.play();
  Future<void> pause() => _player.pause();
  Future<void> stop() => _player.stop();
  Future<void> seek(Duration position) => _player.seek(position);

  void dispose() {
    _player.dispose();
  }
}
