import 'package:flutter/material.dart';
import 'package:comicviewer/comic_viewer.dart';
import 'web_dav_client.dart';

class WebDavBrowser extends StatefulWidget {
  final String host;
  final String id;
  final String password;

  const WebDavBrowser(
      {super.key,
      required this.host,
      required this.id,
      required this.password});

  @override
  WebDavBrowserState createState() => WebDavBrowserState();
}

class WebDavBrowserState extends State<WebDavBrowser> {
  late WebDavClient _client;
  late Future<List<Map<String, dynamic>>> _files;

  @override
  void initState() {
    super.initState();
    _client = WebDavClient(
      serverUrl: widget.host,
      username: widget.id,
      password: widget.password,
    );
    _files = _client.listFiles('');
  }

  Future<void> _handleFileTap(Map<String, dynamic> file, int index) async {
    if (file['type'] == "folder") {
      setState(() {
        _files = _client.listFiles(file['href']);
      });
    } else {
      String extension = file['name'].split('.').last.toLowerCase();
      if (["jpg", "jpeg", "png", "gif", "bmp", "zip", "cbz"].contains(extension)) {
        try {
          // Show loading indicator
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => const Center(
              child: CircularProgressIndicator(),
            ),
          );

          if (["zip", "cbz"].contains(extension)) {
            // Handle archive files
            final localPath = await _client.downloadFile(file['href']);
            
            // Hide loading indicator
            if (context.mounted) {
              Navigator.pop(context);
            }

            // Open in ComicViewer
            if (context.mounted) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ComicViewer(filePath: localPath),
                ),
              );
            }
          } else {
            // Handle image files
            // Get current directory path
            final currentDir = file['href'].substring(0, file['href'].lastIndexOf('/'));
            
            // Get all files in the current directory
            final dirFiles = await _client.listFiles(currentDir);
            
            // Filter image files and sort them
            final imageFiles = dirFiles
                .where((f) => ["jpg", "jpeg", "png", "gif", "bmp"]
                    .contains(f['name'].split('.').last.toLowerCase()))
                .toList()
              ..sort((a, b) => a['name'].compareTo(b['name']));

            // Find the index of the clicked image
            final clickedIndex = imageFiles.indexWhere((f) => f['href'] == file['href']);
            
            // Download all images in the directory
            final List<String> localPaths = [];
            for (var imageFile in imageFiles) {
              final localPath = await _client.downloadFile(imageFile['href']);
              localPaths.add(localPath);
            }

            // Hide loading indicator
            if (context.mounted) {
              Navigator.pop(context);
            }

            // Open in ComicViewer with all images
            if (context.mounted) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ComicViewer(
                    filePath: localPaths[clickedIndex],
                    additionalFiles: localPaths,
                  ),
                ),
              );
            }
          }
        } catch (e) {
          // Hide loading indicator if it's showing
          if (context.mounted) {
            Navigator.pop(context);
          }

          // Show error
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error: ${e.toString()}'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _files,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No files found'));
          }

          final files = snapshot.data!;
          return ListView.builder(
            itemCount: files.length,
            itemBuilder: (context, index) {
              final file = files[index];
              return ListTile(
                title: Text(file['name']),
                subtitle: Text(file['type']),
                onTap: () => _handleFileTap(file, index),
              );
            },
          );
        },
      ),
    );
  }
}
