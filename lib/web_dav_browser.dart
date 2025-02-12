import 'package:comicviewer/image_information.dart';
import 'package:flutter/material.dart';

import 'image_viewer_screen.dart';
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _files,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('No files found'));
          }

          final files = snapshot.data!;
          return ListView.builder(
            itemCount: files.length,
            itemBuilder: (context, index) {
              final file = files[index];
              return ListTile(
                title: Text(file['name']),
                subtitle: Text(file['type']),
                //trailing: Text('${file['size']} bytes'),
                onTap: () {
                  if (file['type'] == "folder") {
                    setState(() {
                      _files = _client.listFiles(file['href']);
                    });
                  } else {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ImageViewerScreen(
                              imageInformation:
                              FileImageInformation(files, _client.getImage),
                              initialIndex: index),
                        ));
                  }
                },
              );
            },
          );
        },
      ),
    );
  }
}
