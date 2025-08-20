import 'dart:io';

Future<String> saveTextFile({required String fileName, required String content}) async {
  // Prefer Downloads directory when available
  final directory = Directory.systemTemp; // fallback to temp
  final file = File('${directory.path}${Platform.pathSeparator}$fileName');
  await file.writeAsString(content);
  return file.path;
}

Future<void> openFilePath(String path) async {
  try {
    if (Platform.isWindows) {
      await Process.run('notepad', [path]);
    } else if (Platform.isMacOS) {
      await Process.run('open', [path]);
    } else if (Platform.isLinux) {
      await Process.run('xdg-open', [path]);
    }
  } catch (_) {}
}

Future<String> saveBytes({required String fileName, required List<int> bytes}) async {
  final directory = Directory.systemTemp;
  final file = File('${directory.path}${Platform.pathSeparator}$fileName');
  await file.writeAsBytes(bytes, flush: true);
  return file.path;
}


