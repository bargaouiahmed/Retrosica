
import 'package:flutter/material.dart';
import '../services/Mp3ConversionService.dart'; // Assuming your service is here

class Mp3ConversionPage extends StatefulWidget {
  const Mp3ConversionPage({super.key});

  @override
  State<Mp3ConversionPage> createState() => _Mp3ConversionPageState();
}

class _Mp3ConversionPageState extends State<Mp3ConversionPage> {
  final TextEditingController _urlController = TextEditingController();
  final Mp3Converter _mp3Converter = Mp3Converter();
  String _statusMessage = 'Enter a YouTube URL to download as MP3.';
  bool _isLoading = false;
  bool _isValidUrl = false;

  @override
  void initState() {
    super.initState();
    _urlController.addListener(_validateUrl);
  }

  void _validateUrl() {
    final url = _urlController.text.trim();
    final isValid = _isYouTubeUrl(url);
    
    if (_isValidUrl != isValid) {
      setState(() {
        _isValidUrl = isValid;
        if (url.isNotEmpty && !isValid) {
          _statusMessage = 'Please enter a valid YouTube URL (youtube.com or youtu.be)';
        } else if (url.isEmpty) {
          _statusMessage = 'Enter a YouTube URL to download as MP3.';
        } else {
          _statusMessage = 'Ready to download!';
        }
      });
    }
  }

  bool _isYouTubeUrl(String url) {
    if (url.isEmpty) return false;
    
    // Normalize the URL to lowercase for easier checking
    final lowerUrl = url.toLowerCase();
    
    // Check for various YouTube URL patterns
    final isYouTube = lowerUrl.contains('youtube.com/watch') ||
                     lowerUrl.contains('youtu.be/') ||
                     lowerUrl.contains('youtube.com/embed/') ||
                     lowerUrl.contains('youtube.com/v/');
    
    // Basic URL structure check
    final hasProtocol = lowerUrl.startsWith('http://') || lowerUrl.startsWith('https://');
    
    return isYouTube && hasProtocol;
  }

  Future<void> _downloadMp3() async {
    final url = _urlController.text.trim();
    
    if (url.isEmpty) {
      setState(() {
        _statusMessage = 'Please enter a YouTube URL.';
      });
      return;
    }

    if (!_isValidUrl) {
      setState(() {
        _statusMessage = 'Please enter a valid YouTube URL (youtube.com or youtu.be)';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _statusMessage = 'Starting download...';
    });

    try {
      final String? filePath = await _mp3Converter.downloadAndSaveMp3(url);

      if (filePath != null) {
        // Extract just the filename from the full path for cleaner message
        final fileName = filePath.split('/').last;
        
        setState(() {
          _statusMessage = '✅ Successfully downloaded: $fileName';
        });
        
        // Clear the input field on successful download
        _urlController.clear();
        
        // Show success snackbar
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text('MP3 downloaded successfully!'),
                  ),
                ],
              ),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 3),
            ),
          );
        }
      } else {
        setState(() {
          _statusMessage = '❌ Failed to download MP3. Please try again.';
        });
      }
    } catch (e) {
      setState(() {
        _statusMessage = '❌ Download failed: ${e.toString()}';
      });
      print('Error in _downloadMp3: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('YouTube to MP3 Downloader'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            TextField(
              controller: _urlController,
              decoration: const InputDecoration(
                labelText: 'YouTube Video URL',
                hintText: 'e.g., https://www.youtube.com/watch?v=dQw4w9WgXcQ',
                border: OutlineInputBorder(),
              ),
              enabled: !_isLoading,
            ),
            const SizedBox(height: 16.0),
            ElevatedButton(
              onPressed: (_isLoading || !_isValidUrl) ? null : _downloadMp3,
              child: _isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Download MP3'),
            ),
            const SizedBox(height: 24.0),
            Text(
              'Status:',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8.0),
            Text(
              _statusMessage,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}
