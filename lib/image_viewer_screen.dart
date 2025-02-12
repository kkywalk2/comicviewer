import 'package:comicviewer/image_information.dart';
import 'package:flutter/material.dart';
import 'dart:typed_data';

class ImageViewerScreen extends StatefulWidget {
  final FileImageInformation imageInformation;
  final int initialIndex;

  const ImageViewerScreen({
    super.key,
    required this.imageInformation,
    required this.initialIndex,
  });

  @override
  ImageViewerScreenState createState() => ImageViewerScreenState();
}

class ImageViewerScreenState extends State<ImageViewerScreen> {
  late int currentIndex;
  late Future<Uint8List> imageFuture;

  @override
  void initState() {
    super.initState();
    currentIndex = widget.initialIndex;

    final currentFile = widget.imageInformation.images[currentIndex];
    imageFuture = widget.imageInformation.getImage(currentFile['href']);
  }

  /// 📌 이전 이미지 보기
  void showPreviousImage() {
    if (currentIndex > 0) {
      setState(() {
        currentIndex--;

        final prevFile = widget.imageInformation.images[currentIndex];
        imageFuture = widget.imageInformation.getImage(prevFile['href']);
      });
    }
  }

  /// 📌 다음 이미지 보기
  void showNextImage() {
    if (currentIndex < widget.imageInformation.images.length - 1) {
      setState(() {
        currentIndex++;

        final nextFile = widget.imageInformation.images[currentIndex];
        imageFuture = widget.imageInformation.getImage(nextFile['href']);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.imageInformation.images[currentIndex]['name'])),
      body: Column(
        children: [
          Expanded(
            child: Center(
              child: FutureBuilder<Uint8List>(
                future: imageFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const CircularProgressIndicator();
                  } else if (snapshot.hasError) {
                    return Text('Error: ${snapshot.error}');
                  } else if (snapshot.hasData) {
                    return Image.memory(snapshot.data!);
                  } else {
                    return const Text('No image available.');
                  }
                },
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: currentIndex > 0 ? showPreviousImage : null,
                  child: const Text('이전'),
                ),
                ElevatedButton(
                  onPressed: currentIndex < widget.imageInformation.images.length - 1 ? showNextImage : null,
                  child: const Text('다음'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
