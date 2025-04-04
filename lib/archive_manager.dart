import 'dart:io';
import 'package:archive/archive.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

class ArchiveManager {
  static const int maxTempSize = 512 * 1024 * 1024; // 512MB in bytes
  static ArchiveManager? _instance;
  late Directory _tempDir;
  final Map<String, DateTime> _extractedFiles = {};

  ArchiveManager._();

  static Future<ArchiveManager> getInstance() async {
    if (_instance == null) {
      _instance = ArchiveManager._();
      await _instance!._initialize();
    }
    return _instance!;
  }

  Future<void> _initialize() async {
    _tempDir = await getTemporaryDirectory();
    _tempDir = Directory(path.join(_tempDir.path, 'comicviewer_extracted'));
    if (!await _tempDir.exists()) {
      await _tempDir.create(recursive: true);
    }
    await _cleanupIfNeeded();
  }

  Future<String> extractArchive(String archivePath) async {
    await _cleanupIfNeeded();

    final fileName = path.basenameWithoutExtension(archivePath);
    final extractDir = Directory(path.join(_tempDir.path, fileName));

    if (await extractDir.exists()) {
      _extractedFiles[extractDir.path] = DateTime.now();
      return extractDir.path;
    }

    await extractDir.create(recursive: true);

    final bytes = await File(archivePath).readAsBytes();
    final archive = ZipDecoder().decodeBytes(bytes);

    for (final file in archive) {
      final filename = file.name;
      if (file.isFile) {
        final data = file.content as List<int>;
        final outFile = File(path.join(extractDir.path, filename));
        await outFile.create(recursive: true);
        await outFile.writeAsBytes(data);
      }
    }

    _extractedFiles[extractDir.path] = DateTime.now();
    return extractDir.path;
  }

  Future<void> _cleanupIfNeeded() async {
    int totalSize = 0;
    final files = await _tempDir.list().toList();
    
    for (var file in files) {
      if (file is File) {
        totalSize += await file.length();
      } else if (file is Directory) {
        totalSize += await _getDirectorySize(file);
      }
    }

    if (totalSize > maxTempSize) {
      // Sort by last access time
      final sortedFiles = _extractedFiles.entries.toList()
        ..sort((a, b) => a.value.compareTo(b.value));

      // Remove oldest files until under limit
      for (var entry in sortedFiles) {
        if (totalSize <= maxTempSize) break;
        
        final dir = Directory(entry.key);
        if (await dir.exists()) {
          totalSize -= await _getDirectorySize(dir);
          await dir.delete(recursive: true);
          _extractedFiles.remove(entry.key);
        }
      }
    }
  }

  Future<int> _getDirectorySize(Directory dir) async {
    int size = 0;
    await for (var entity in dir.list(recursive: true)) {
      if (entity is File) {
        size += await entity.length();
      }
    }
    return size;
  }

  Future<void> cleanup() async {
    if (await _tempDir.exists()) {
      await _tempDir.delete(recursive: true);
    }
    _extractedFiles.clear();
  }
} 