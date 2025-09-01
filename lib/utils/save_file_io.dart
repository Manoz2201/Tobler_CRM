import 'dart:io';
import 'package:path_provider/path_provider.dart';

Future<String> saveTextFile({
  required String fileName,
  required String content,
}) async {
  // Prefer Downloads directory when available
  Directory directory;
  try {
    if (Platform.isWindows) {
      // On Windows, try to get the Downloads directory
      final downloadsDir = await getDownloadsDirectory();
      directory = downloadsDir ?? Directory.systemTemp;
    } else {
      // On other platforms, use system temp as fallback
      directory = Directory.systemTemp;
    }
  } catch (e) {
    // Fallback to temp directory if Downloads directory cannot be accessed
    directory = Directory.systemTemp;
  }

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

Future<String> saveBytes({
  required String fileName,
  required List<int> bytes,
}) async {
  Directory directory;
  try {
    if (Platform.isWindows) {
      // On Windows, try to get the Downloads directory
      final downloadsDir = await getDownloadsDirectory();
      directory = downloadsDir ?? Directory.systemTemp;
    } else {
      // On other platforms, use system temp as fallback
      directory = Directory.systemTemp;
    }
  } catch (e) {
    // Fallback to temp directory if Downloads directory cannot be accessed
    directory = Directory.systemTemp;
  }

  final file = File('${directory.path}${Platform.pathSeparator}$fileName');
  await file.writeAsBytes(bytes, flush: true);
  return file.path;
}
