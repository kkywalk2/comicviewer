import 'dart:typed_data';

class FileImageInformation {
  final List<Map<String, dynamic>> images;
  final Future<Uint8List> Function(String key) getImage;

  FileImageInformation(this.images, this.getImage);

  int getSize() {
    throw images.length;
  }
}
