import 'dart:io';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:retrosicav2/services/FileOperationsService.dart';
import 'package:retrosicav2/services/AudioPlayerService.dart';

class Mp3List extends StatefulWidget {
  const Mp3List({super.key});

  @override
  State<Mp3List> createState() => _Mp3ListState();
}

class _Mp3ListState extends State<Mp3List> with TickerProviderStateMixin {
  final FileOperationsService _fileService = FileOperationsService();
  final AudioPlayerService _audioService = AudioPlayerService();
  
  List<File> _files = [];
  bool _loading = true;
  String? _error;
  bool _importing = false;
  bool _isStatsExpanded = true;

  @override
  void initState() {
    super.initState();
    _initFilesAndPlayer();
  }

  @override
  void dispose() {
    _audioService.dispose();
    super.dispose();
  }

  Future<void> _initFilesAndPlayer() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final files = await _fileService.getAudioFilesInDirectory();
      setState(() => _files = files);

      if (files.isNotEmpty) {
        await _audioService.loadFiles(files);
      }
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _importFiles() async {
    if (_importing) return;
    
    setState(() => _importing = true);
    
    try {
      final importedFiles = await _fileService.importAudioFiles();
      if (importedFiles.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Successfully imported ${importedFiles.length} file(s)'),
            backgroundColor: Colors.green,
            action: SnackBarAction(
              label: 'OK',
              textColor: Colors.white,
              onPressed: () {},
            ),
          ),
        );
        await _initFilesAndPlayer(); // Refresh the list
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Import failed: ${e.toString()}'),
          backgroundColor: Colors.red,
          action: SnackBarAction(
            label: 'OK',
            textColor: Colors.white,
            onPressed: () {},
          ),
        ),
      );
    } finally {
      setState(() => _importing = false);
    }
  }

  Future<void> _onTapItem(int index) async {
    try {
      await _audioService.player.seek(Duration.zero, index: index);
      await _audioService.play();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error playing track: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _onReorder(int oldIndex, int newIndex) async {
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    
    setState(() {
      final File item = _files.removeAt(oldIndex);
      _files.insert(newIndex, item);
    });

    // Update the audio service with the new order
    await _audioService.reorderFiles(_files);
  }

  Future<void> _deleteFile(File file, int index) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete File'),
        content: Text('Are you sure you want to delete "${file.uri.pathSegments.last}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (result == true) {
      final success = await _fileService.deleteAudioFile(file);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('File deleted successfully')),
        );
        await _initFilesAndPlayer(); // Refresh the list
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to delete file'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    if (duration.inHours > 0) {
      return "${twoDigits(duration.inHours)}:$twoDigitMinutes:$twoDigitSeconds";
    }
    return "$twoDigitMinutes:$twoDigitSeconds";
  }

  Widget _buildStatisticsCard() {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        _isStatsExpanded = !_isStatsExpanded;
                      });
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          Text(
                            'Library Stats',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 8),
                          AnimatedRotation(
                            turns: _isStatsExpanded ? 0.5 : 0,
                            duration: const Duration(milliseconds: 200),
                            child: Icon(
                              Icons.expand_more,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.add),
                      onPressed: _importing ? null : _importFiles,
                      tooltip: 'Import Music',
                    ),
                    IconButton(
                      icon: const Icon(Icons.refresh),
                      onPressed: _initFilesAndPlayer,
                      tooltip: 'Refresh',
                    ),
                  ],
                ),
              ],
            ),
            AnimatedCrossFade(
              firstChild: const SizedBox.shrink(),
              secondChild: Column(
                children: [
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Column(
                        children: [
                          Icon(Icons.library_music, size: 32, color: Theme.of(context).colorScheme.primary),
                          const SizedBox(height: 8),
                          Text(
                            '${_files.length}',
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                          Text(
                            'Tracks',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                      FutureBuilder<double>(
                        future: _fileService.getTotalAudioSize(),
                        builder: (context, snapshot) {
                          return Column(
                            children: [
                              Icon(Icons.storage, size: 32, color: Theme.of(context).colorScheme.secondary),
                              const SizedBox(height: 8),
                              Text(
                                snapshot.hasData ? '${snapshot.data!.toStringAsFixed(1)} MB' : '...',
                                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).colorScheme.secondary,
                                ),
                              ),
                              Text(
                                'Storage',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Playback controls row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // Shuffle button
                      StreamBuilder<bool>(
                        stream: _audioService.player.shuffleModeEnabledStream,
                        builder: (context, snapshot) {
                          final isShuffleEnabled = snapshot.data ?? false;
                          return Container(
                            decoration: BoxDecoration(
                              color: isShuffleEnabled 
                                  ? Theme.of(context).colorScheme.primary.withOpacity(0.2)
                                  : Theme.of(context).colorScheme.surface,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isShuffleEnabled 
                                    ? Theme.of(context).colorScheme.primary
                                    : Theme.of(context).colorScheme.outline.withOpacity(0.3),
                              ),
                            ),
                            child: IconButton(
                              icon: Icon(
                                Icons.shuffle,
                                color: isShuffleEnabled 
                                    ? Theme.of(context).colorScheme.primary
                                    : Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                              ),
                              onPressed: () => _audioService.toggleShuffle(),
                              tooltip: isShuffleEnabled ? 'Disable Shuffle' : 'Enable Shuffle',
                            ),
                          );
                        },
                      ),
                      // Repeat button
                      StreamBuilder<LoopMode>(
                        stream: _audioService.player.loopModeStream,
                        builder: (context, snapshot) {
                          final loopMode = snapshot.data ?? LoopMode.all;
                          IconData icon;
                          String tooltip;
                          Color color;
                          bool isActive;
                          
                          switch (loopMode) {
                            case LoopMode.off:
                              icon = Icons.repeat;
                              tooltip = 'Repeat Off';
                              color = Theme.of(context).colorScheme.onSurface.withOpacity(0.7);
                              isActive = false;
                              break;
                            case LoopMode.one:
                              icon = Icons.repeat_one;
                              tooltip = 'Repeat One';
                              color = Theme.of(context).colorScheme.secondary;
                              isActive = true;
                              break;
                            case LoopMode.all:
                              // Treat "all" as invisible default - show inactive repeat icon
                              icon = Icons.repeat;
                              tooltip = 'Repeat (Default)';
                              color = Theme.of(context).colorScheme.onSurface.withOpacity(0.7);
                              isActive = false;
                              break;
                          }
                          
                          return Container(
                            decoration: BoxDecoration(
                              color: isActive 
                                  ? Theme.of(context).colorScheme.secondary.withOpacity(0.2)
                                  : Theme.of(context).colorScheme.surface,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isActive 
                                    ? Theme.of(context).colorScheme.secondary
                                    : Theme.of(context).colorScheme.outline.withOpacity(0.3),
                              ),
                            ),
                            child: IconButton(
                              icon: Icon(icon, color: color),
                              onPressed: () => _audioService.toggleLoopMode(),
                              tooltip: tooltip,
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
              crossFadeState: _isStatsExpanded 
                  ? CrossFadeState.showSecond 
                  : CrossFadeState.showFirst,
              duration: const Duration(milliseconds: 300),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentTrackHeader() {
    return StreamBuilder<int?>(
      stream: _audioService.player.currentIndexStream,
      builder: (context, snapshot) {
        final currentIndex = snapshot.data;
        if (currentIndex == null || currentIndex >= _files.length) {
          return const SizedBox.shrink();
        }
        
        final currentFile = _files[currentIndex];
        final fileName = currentFile.uri.pathSegments.isNotEmpty 
            ? currentFile.uri.pathSegments.last 
            : currentFile.path;

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Theme.of(context).colorScheme.primaryContainer,
                Theme.of(context).colorScheme.secondaryContainer,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.music_note,
                  color: Theme.of(context).colorScheme.onPrimary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Now Playing',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      fileName,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 2,
                    ),
                  ],
                ),
              ),
              StreamBuilder<bool>(
                stream: _audioService.player.playingStream,
                builder: (context, playingSnapshot) {
                  final isPlaying = playingSnapshot.data ?? false;
                  return Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      isPlaying ? Icons.volume_up : Icons.pause,
                      color: Theme.of(context).colorScheme.primary,
                      size: 20,
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBottomPlayer() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.surface,
            Theme.of(context).colorScheme.surface.withOpacity(0.9),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Progress bar
          StreamBuilder<Duration>(
            stream: _audioService.player.positionStream,
            builder: (context, positionSnapshot) {
              return StreamBuilder<Duration?>(
                stream: _audioService.player.durationStream,
                builder: (context, durationSnapshot) {
                  final position = positionSnapshot.data ?? Duration.zero;
                  final duration = durationSnapshot.data ?? Duration.zero;
                  
                  return Column(
                    children: [
                      SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          trackHeight: 3,
                          thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                          overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
                        ),
                        child: Slider(
                          value: duration.inMilliseconds > 0 
                              ? (position.inMilliseconds / duration.inMilliseconds).clamp(0.0, 1.0)
                              : 0.0,
                          onChanged: (value) {
                            final newPosition = Duration(
                              milliseconds: (value * duration.inMilliseconds).round(),
                            );
                            _audioService.seek(newPosition);
                          },
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _formatDuration(position),
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                              ),
                            ),
                            Text(
                              _formatDuration(duration),
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              );
            },
          ),
          
          // Controls and track info
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              children: [
                // Track info
                Expanded(
                  child: StreamBuilder<int?>(
                    stream: _audioService.player.currentIndexStream,
                    builder: (context, snapshot) {
                      final currentIndex = snapshot.data;
                      if (currentIndex == null || currentIndex >= _files.length) {
                        return Text(
                          'No track selected',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                          ),
                        );
                      }
                      
                      final currentFile = _files[currentIndex];
                      final fileName = currentFile.uri.pathSegments.isNotEmpty 
                          ? currentFile.uri.pathSegments.last 
                          : 'Unknown';
                      
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            fileName,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Track ${currentIndex + 1} of ${_files.length}',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
                
                // Previous button
                Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: IconButton(
                    icon: Icon(
                      Icons.skip_previous,
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                    onPressed: () async {
                      if (_audioService.player.hasPrevious) {
                        await _audioService.player.seekToPrevious();
                      }
                    },
                  ),
                ),
                
                const SizedBox(width: 8),
                
                // Play/Pause button
                StreamBuilder<bool>(
                  stream: _audioService.player.playingStream,
                  builder: (context, snapshot) {
                    final isPlaying = snapshot.data ?? false;
                    return Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Theme.of(context).colorScheme.primary,
                            Theme.of(context).colorScheme.secondary,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: IconButton(
                        icon: Icon(
                          isPlaying ? Icons.pause : Icons.play_arrow,
                          color: Theme.of(context).colorScheme.onPrimary,
                          size: 32,
                        ),
                        onPressed: () {
                          if (isPlaying) {
                            _audioService.pause();
                          } else {
                            _audioService.play();
                          }
                        },
                      ),
                    );
                  },
                ),
                
                const SizedBox(width: 8),
                
                // Next button
                Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: IconButton(
                    icon: Icon(
                      Icons.skip_next,
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                    onPressed: () async {
                      if (_audioService.player.hasNext) {
                        await _audioService.player.seekToNext();
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(
                  Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Loading your music...',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
          ),
        ),
      );
    }
    
    if (_error != null) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 80,
                  color: Theme.of(context).colorScheme.error,
                ),
                const SizedBox(height: 24),
                Text(
                  'Oops! Something went wrong',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  _error!,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: _initFilesAndPlayer,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Try Again'),
                ),
              ],
            ),
          ),
        ),
      );
    }
    
    if (_files.isEmpty) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.music_off,
                  size: 80,
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
                ),
                const SizedBox(height: 24),
                Text(
                  'No Music Found',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Import some audio files to get started',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                ElevatedButton.icon(
                  onPressed: _importing ? null : _importFiles,
                  icon: _importing 
                      ? SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Theme.of(context).colorScheme.onPrimary,
                            ),
                          ),
                        )
                      : const Icon(Icons.add),
                  label: Text(_importing ? 'Importing...' : 'Import Music'),
                ),
                const SizedBox(height: 16),
                TextButton.icon(
                  onPressed: _initFilesAndPlayer,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Refresh'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      body: Column(
        children: [
          _buildCurrentTrackHeader(),
          _buildStatisticsCard(),
          Expanded(
            child: ReorderableListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              itemCount: _files.length,
              onReorder: _onReorder,
              itemBuilder: (context, index) {
                final file = _files[index];
                final fileName = file.uri.pathSegments.isNotEmpty 
                    ? file.uri.pathSegments.last 
                    : file.path;
                
                return StreamBuilder<int?>(
                  key: ValueKey(file.path),
                  stream: _audioService.player.currentIndexStream,
                  builder: (context, snapshot) {
                    final isCurrentTrack = snapshot.data == index;
                    
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                      elevation: isCurrentTrack ? 4 : 1,
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        leading: Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            gradient: isCurrentTrack 
                                ? LinearGradient(
                                    colors: [
                                      Theme.of(context).colorScheme.primary,
                                      Theme.of(context).colorScheme.secondary,
                                    ],
                                  )
                                : null,
                            color: isCurrentTrack 
                                ? null 
                                : Theme.of(context).colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            isCurrentTrack ? Icons.music_note : Icons.audiotrack,
                            color: isCurrentTrack 
                                ? Theme.of(context).colorScheme.onPrimary
                                : Theme.of(context).colorScheme.onPrimaryContainer,
                          ),
                        ),
                        title: Text(
                          fileName,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: isCurrentTrack ? FontWeight.bold : FontWeight.normal,
                            color: isCurrentTrack 
                                ? Theme.of(context).colorScheme.primary 
                                : null,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Row(
                          children: [
                            Text('Track ${index + 1}'),
                            const SizedBox(width: 8),
                            if (isCurrentTrack)
                              StreamBuilder<bool>(
                                stream: _audioService.player.playingStream,
                                builder: (context, playingSnapshot) {
                                  final isPlaying = playingSnapshot.data ?? false;
                                  return Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      isPlaying ? 'Playing' : 'Paused',
                                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                        color: Theme.of(context).colorScheme.primary,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  );
                                },
                              ),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            PopupMenuButton<String>(
                              onSelected: (value) {
                                if (value == 'delete') {
                                  _deleteFile(file, index);
                                }
                              },
                              itemBuilder: (context) => [
                                const PopupMenuItem(
                                  value: 'delete',
                                  child: Row(
                                    children: [
                                      Icon(Icons.delete, color: Colors.red),
                                      SizedBox(width: 8),
                                      Text('Delete'),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(width: 8),
                            ReorderableDragStartListener(
                              index: index,
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.5),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  Icons.drag_handle,
                                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                                  size: 20,
                                ),
                              ),
                            ),
                          ],
                        ),
                        onTap: () => _onTapItem(index),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          _buildBottomPlayer(),
        ],
      ),
    );
  }
}