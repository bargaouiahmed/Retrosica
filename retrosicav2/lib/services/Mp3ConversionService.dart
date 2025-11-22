
import 'dart:convert';
import 'dart:async'; // Required for Future.delayed
import 'dart:io';   // Required for File and Directory operations

import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart'; // Required for finding save directory
import 'package:permission_handler/permission_handler.dart';

class Mp3Converter {
  // IMPORTANT: Storing API keys directly in code is not secure for production apps.
  // Consider using environment variables or a configuration file.
  final String _apiKey = 'YOUR-API-KEY-HERE';
  final String _apiHost = 'youtube-mp36.p.rapidapi.com';

  /// Request storage permissions based on Android version
  Future<bool> _requestStoragePermission() async {
    if (Platform.isAndroid) {
      // For Android 13+ (API 33+)
      if (await Permission.audio.request().isGranted) {
        return true;
      }
      
      // For Android 11-12 (API 30-32)
      if (await Permission.storage.request().isGranted) {
        return true;
      }
      
      // For older Android versions
      if (await Permission.manageExternalStorage.request().isGranted) {
        return true;
      }
      
      return false;
    }
    return true; // iOS doesn't need explicit storage permissions for downloads
  }

  /// Fetches the MP3 download link and title from the API.
  /// Handles the "processing" status by polling the API.
  Future<Map<String, String>?> _fetchMp3Info(String videoId) async {
    final url = Uri.https(_apiHost, '/dl', {'id': videoId});
    final headers = {
      'X-RapidAPI-Key': _apiKey,
      'X-RapidAPI-Host': _apiHost,
    };

    try {
      print('Fetching MP3 info for video ID: $videoId...');
      final response = await http.get(url, headers: headers);

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        final String status = data['status'] ?? 'fail'; // Default to 'fail' if status is null
        final String? msg = data['msg'];

        print('API Response:');
        print('  Status: $status');
        if (data.containsKey('title')) print('  Title: ${data['title']}');
        if (msg != null && msg.isNotEmpty) print('  Message: $msg');

        if (status == 'ok') {
          if (data.containsKey('link') && data.containsKey('title')) {
            print('MP3 info received successfully.');
            return {'link': data['link'], 'title': data['title']};
          } else {
            print('Error: API status "ok" but "link" or "title" is missing.');
            return null;
          }
        } else if (status == 'processing') {
          print('Conversion is processing. Retrying in 1 second...');
          await Future.delayed(Duration(seconds: 1));
          return _fetchMp3Info(videoId); // Recursive call to poll
        } else if (status == 'fail') {
          print('Conversion failed. Message: $msg');
          return null;
        } else {
          print('Unknown API status received: $status. Message: $msg');
          return null;
        }
      } else {
        print('API request failed with status: ${response.statusCode}.');
        print('Response body: ${response.body}');
        return null;
      }
    } catch (e) {
      print('Error during API request or JSON parsing: $e');
      return null;
    }
  }

  /// Gets the directory where MP3s will be saved.
  /// Creates an 'mp3' subdirectory if it doesn't exist.
  Future<Directory> _getMp3SaveDirectory() async {
    // Get the application's private documents directory.
    // Files stored here are internal to the application.
    final Directory appDocDir = await getApplicationDocumentsDirectory();
    final Directory mp3Dir = Directory('${appDocDir.path}/mp3');

    if (!await mp3Dir.exists()) {
      await mp3Dir.create(recursive: true);
      print('Created directory: ${mp3Dir.path}');
    }
    return mp3Dir;
  }

  /// Sanitizes a string to be a valid filename.
  /// Replaces most non-alphanumeric characters with underscores.
  String _sanitizeFileName(String fileName) {
    String sanitized = fileName.replaceAll(RegExp(r'[^\w\s.-]'), '_');
    // Replace multiple spaces/underscores with a single underscore
    sanitized = sanitized.replaceAll(RegExp(r'[\s_]+'), '_');
    return sanitized.trim(); // Trim leading/trailing whitespace/underscores
  }

  /// Public method to download an MP3 for a given YouTube video ID.
  /// Returns the file path of the downloaded MP3, or null on failure.
  Future<String?> downloadAndSaveMp3(String url) async {
    // Check and request storage permissions first
    bool hasPermission = await _requestStoragePermission();
    if (!hasPermission) {
      throw Exception('Storage permission denied. Please grant permission to download files.');
    }
    
    final String videoId = extractVideoId(url);
    // 1. Fetch the MP3 link and title from the API
    final mp3Info = await _fetchMp3Info(videoId);

    if (mp3Info == null || !mp3Info.containsKey('link') || !mp3Info.containsKey('title')) {
      print('Could not retrieve MP3 information for video ID: $videoId.');
      return null;
    }

    final String mp3DownloadLink = mp3Info['link']!;
    final String title = mp3Info['title']!;

    try {
      // 2. Download the actual MP3 file from the obtained link
      print('Downloading MP3 titled "$title" from: $mp3DownloadLink');
      final http.Response mp3FileResponse = await http.get(Uri.parse(mp3DownloadLink));

      if (mp3FileResponse.statusCode == 200) {
        // 3. Get the save directory and prepare the file path
        final Directory saveDir = await _getMp3SaveDirectory();
        final String sanitizedTitle = _sanitizeFileName(title);
        // Use a more unique name if titles might not be unique, e.g., include videoId
        final String fileName = '${sanitizedTitle}_${videoId}.mp3';
        final File mp3File = File('${saveDir.path}/$fileName');

        // 4. Write the downloaded bytes to the file
        await mp3File.writeAsBytes(mp3FileResponse.bodyBytes);
        print('MP3 downloaded and saved successfully to: ${mp3File.path}');
        return mp3File.path; // Return the path of the saved file
      } else {
        print('Failed to download MP3 file. Status: ${mp3FileResponse.statusCode}');
        print('Response body: ${mp3FileResponse.body}');
        return null;
      }
    } catch (e) {
      print('Error downloading or saving MP3 file: $e');
      return null;
    }
  }

  String extractVideoId(String url){
    if (url.contains("youtube.com")){
      if (url.contains("v=")){
        return url.split("v=")[1].split("&")[0];
      }
    }
    else if (url.contains("youtu.be")){
      //url could be https://youtu.be/I3f-P65is7A?si=pYmVRa69he_GZ
      return url.split("youtu.be/")[1].split("?")[0];
    }
    return "";
  }
}

/*
// Example of how to use this class from your UI or other logic:
void main() async { // Make sure your calling function is async
  final converter = Mp3Converter();
  final String? filePath = await converter.downloadAndSaveMp3('UxxajLWwzqY'); // Example video ID

  if (filePath != null) {
    print('Process complete. MP3 saved at: $filePath');
    // Now you can use this filePath to play the MP3, list it in your app, etc.
  } else {
    print('Process failed. Could not download or save MP3.');
  }
}
*/
