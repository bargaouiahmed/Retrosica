
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:permission_handler/permission_handler.dart';

class FileOperationsService {
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
    return true; // iOS doesn't need explicit storage permissions for file_picker
  }
  /// Returns a list of audio files from the app documents `mp3` directory.
  /// Filters by common audio extensions and returns `File` objects only.
  Future<List<File>> getAudioFilesInDirectory() async {
    final directory = await getApplicationDocumentsDirectory();
    final mp3Dir = Directory('${directory.path}/mp3');

    if (!await mp3Dir.exists()) {
      // Create the directory if it doesn't exist
      await mp3Dir.create(recursive: true);
      return [];
    }

    final allEntities = mp3Dir.listSync(recursive: false);
    final audioFiles = <File>[];

    const audioExts = ['.mp3', '.m4a', '.wav', '.aac', '.flac', '.ogg'];

    for (final e in allEntities) {
      if (e is File) {
        final pathLower = e.path.toLowerCase();
        for (final ext in audioExts) {
          if (pathLower.endsWith(ext)) {
            audioFiles.add(e);
            break;
          }
        }
      }
    }

    return audioFiles;
  }

  /// Import MP3/audio files from device storage to the app's mp3 directory
  Future<List<File>> importAudioFiles() async {
    try {
      // Check and request storage permissions first
      bool hasPermission = await _requestStoragePermission();
      if (!hasPermission) {
        throw Exception('Storage permission denied. Please grant permission to import files.');
      }
      
      // Pick multiple audio files
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['mp3', 'm4a', 'wav', 'aac', 'flac', 'ogg'],
        allowMultiple: true,
      );

      if (result != null) {
        final directory = await getApplicationDocumentsDirectory();
        final mp3Dir = Directory('${directory.path}/mp3');
        
        // Ensure the mp3 directory exists
        if (!await mp3Dir.exists()) {
          await mp3Dir.create(recursive: true);
        }

        final importedFiles = <File>[];

        for (final file in result.files) {
          if (file.path != null) {
            final sourceFile = File(file.path!);
            final fileName = file.name;
            final destinationPath = '${mp3Dir.path}/$fileName';
            
            // Copy the file to our mp3 directory
            final copiedFile = await sourceFile.copy(destinationPath);
            importedFiles.add(copiedFile);
          }
        }

        return importedFiles;
      }
    } catch (e) {
      throw Exception('Failed to import audio files: $e');
    }
    
    return [];
  }

  /// Delete an audio file from the mp3 directory
  Future<bool> deleteAudioFile(File file) async {
    try {
      await file.delete();
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Get the total number of audio files
  Future<int> getAudioFileCount() async {
    final files = await getAudioFilesInDirectory();
    return files.length;
  }

  /// Get total size of audio files in MB
  Future<double> getTotalAudioSize() async {
    final files = await getAudioFilesInDirectory();
    int totalBytes = 0;
    
    for (final file in files) {
      try {
        final stat = await file.stat();
        totalBytes += stat.size;
      } catch (e) {
        // Skip files that can't be read
      }
    }
    
    return totalBytes / (1024 * 1024); // Convert to MB
  }
}
