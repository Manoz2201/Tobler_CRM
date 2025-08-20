import 'dart:convert';
import 'dart:typed_data';
import 'package:web/web.dart' as web;

Future<String> saveTextFile({required String fileName, required String content}) async {
  final Uint8List bytes = Uint8List.fromList(utf8.encode(content));
  await saveBytes(fileName: fileName, bytes: bytes, mime: 'text/plain');
  return fileName;
}

Future<void> openFilePath(String path) async {
  // No-op on web; user already received the file via download.
}

Future<String> saveBytes({required String fileName, required List<int> bytes, String mime = 'application/octet-stream'}) async {
  final String base64Data = base64Encode(bytes);
  final String href = 'data:$mime;base64,$base64Data';
  final anchor = web.document.createElement('a') as web.HTMLAnchorElement
    ..href = href
    ..style.display = 'none'
    ..download = fileName;
  web.document.body!.append(anchor);
  anchor.click();
  anchor.remove();
  return fileName;
}

