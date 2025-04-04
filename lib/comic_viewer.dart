import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;
import 'package:comicviewer/archive_manager.dart';

class ComicViewer extends StatefulWidget {
  final String filePath;
  final List<String>? additionalFiles;

  const ComicViewer({
    Key? key, 
    required this.filePath,
    this.additionalFiles,
  }) : super(key: key);

  @override
  State<ComicViewer> createState() => _ComicViewerState();
}

class _ComicViewerState extends State<ComicViewer> {
  List<String> _imageFiles = [];
  int _currentIndex = 0;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadImages();
  }

  Future<void> _loadImages() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final file = File(widget.filePath);
      if (!await file.exists()) {
        throw Exception('File not found');
      }

      final extension = path.extension(widget.filePath).toLowerCase();
      String imageDirectory;

      if (extension == '.zip' || extension == '.cbz') {
        // Handle archive files
        final archiveManager = await ArchiveManager.getInstance();
        imageDirectory = await archiveManager.extractArchive(widget.filePath);
      } else if (widget.additionalFiles != null) {
        // Use provided additional files
        _imageFiles = widget.additionalFiles!;
        _currentIndex = _imageFiles.indexOf(widget.filePath);
        setState(() {
          _isLoading = false;
        });
        return;
      } else {
        // Handle single image file
        imageDirectory = path.dirname(widget.filePath);
        _imageFiles = [widget.filePath];
      }

      if (_imageFiles.isEmpty) {
        // Load all image files from directory
        final dir = Directory(imageDirectory);
        _imageFiles = await dir
            .list()
            .where((entity) => entity is File)
            .map((entity) => entity.path)
            .where((filePath) {
          final ext = path.extension(filePath).toLowerCase();
          return ['.jpg', '.jpeg', '.png', '.gif', '.webp'].contains(ext);
        }).toList()
          ..sort();
      }

      if (_imageFiles.isEmpty) {
        throw Exception('No image files found');
      }

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_error != null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Error: $_error',
                style: const TextStyle(color: Colors.red),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadImages,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('${_currentIndex + 1} / ${_imageFiles.length}'),
      ),
      body: GestureDetector(
        onTapUp: (details) {
          final screenWidth = MediaQuery.of(context).size.width;
          if (details.globalPosition.dx < screenWidth / 3) {
            _previousPage();
          } else if (details.globalPosition.dx > screenWidth * 2 / 3) {
            _nextPage();
          }
        },
        child: InteractiveViewer(
          child: Image.file(
            File(_imageFiles[_currentIndex]),
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }

  void _nextPage() {
    if (_currentIndex < _imageFiles.length - 1) {
      setState(() {
        _currentIndex++;
      });
    }
  }

  void _previousPage() {
    if (_currentIndex > 0) {
      setState(() {
        _currentIndex--;
      });
    }
  }
} 