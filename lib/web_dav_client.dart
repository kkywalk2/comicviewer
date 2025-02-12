import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:xml/xml.dart';

class WebDavClient {
  late final String domainUrl;
  late final String rootPath;
  late final String scheme;
  final String username;
  final String password;
  final List<String> browseHistory = [];
  String? currentPath;

  WebDavClient({
    required String serverUrl,
    required this.username,
    required this.password,
  }) {
    Uri parsedUrl = Uri.parse(serverUrl);
    domainUrl = parsedUrl.host;
    rootPath = parsedUrl.path;
    scheme = parsedUrl.scheme;
  }

  Map<String, String> _createHeaders() {
    final credentials = base64Encode(utf8.encode('$username:$password'));
    return {
      'Authorization': 'Basic $credentials',
      'Content-Type': 'application/xml',
    };
  }

  Future<List<Map<String, dynamic>>> listFiles(String path) async {
    String realPath = path.isEmpty ? rootPath : path;
    if (realPath == "..") {
      realPath = browseHistory.removeLast();
    } else {
      if (currentPath != null) {
        browseHistory.add(currentPath!);
      }
    }
    currentPath = realPath;

    final url = Uri.parse('$scheme://$domainUrl$realPath');
    final response = http.Request('PROPFIND', url)
      ..headers.addAll(_createHeaders())
      ..body = '''
        <?xml version="1.0" encoding="UTF-8"?>
        <d:propfind xmlns:d="DAV:">
          <d:prop>
            <d:displayname />
            <d:getcontentlength />
            <d:resourcetype />
          </d:prop>
        </d:propfind>
      ''';

    final streamedResponse = await http.Client().send(response);
    final responseBody = await streamedResponse.stream.bytesToString();

    if (streamedResponse.statusCode == 207) {
      return _parsePropfindResponse(responseBody);
    } else {
      throw Exception('Failed to fetch files: ${streamedResponse.statusCode}');
    }
  }

  Future<Uint8List> getImage(String path) async {
    String realPath = path.isEmpty ? rootPath : path;
    currentPath = realPath;

    final url = Uri.parse('$scheme://$domainUrl$realPath');
    final response = http.Request('GET', url)..headers.addAll(_createHeaders());

    final streamedResponse = await http.Client().send(response);

    if (streamedResponse.statusCode == 200) {
      return streamedResponse.stream.toBytes();
    } else {
      throw Exception('Failed to fetch files: ${streamedResponse.statusCode}');
    }
  }

  List<Map<String, dynamic>> _parsePropfindResponse(String responseBody) {
    final document = XmlDocument.parse(responseBody);
    final responses = document.findAllElements('D:response');

    final items = responses.map((node) {
      final name = node.findAllElements('D:displayname').first.innerText;
      final type =
          node.findAllElements('D:collection').isNotEmpty ? 'folder' : 'file';
      final href = node.findAllElements('D:href').first.innerText;
      // final size = int.tryParse(node.findElements('D:getcontentlength').first.value ?? "0");

      return {
        'name': name,
        'type': type,
        'href': href,
        //'size': size,
      };
    }).toList();

    // TODO: webdav 응답에서 현재 폴더가 가장 최상단에 오는지 확인 필요
    items.removeAt(0);

    if (browseHistory.isNotEmpty) {
      items.insert(0, {
        'name': "..",
        'type': "folder",
        'href': "..",
      });
    }

    return items;
  }
}
