// lib/formcheck/storage.dart
import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

class FCStorage {
  /// Writes the session JSON to:
  ///   <app-docs>/formcheck/<filename>
  /// Returns the created File.
  static Future<File> writeSessionJson(
    Map<String, dynamic> session, {
    String filename = 'squat_validation.json',
  }) async {
    final dir = await getApplicationDocumentsDirectory();
    final outDir = Directory('${dir.path}/formcheck');
    if (!await outDir.exists()) {
      await outDir.create(recursive: true);
    }

    final file = File('${outDir.path}/$filename');
    final pretty = const JsonEncoder.withIndent('  ').convert(session);
    await file.writeAsString(pretty);
    return file;
  }

  /// Read a previously saved session JSON file back into a Map.
  static Future<Map<String, dynamic>> readSessionJson(File file) async {
    final txt = await file.readAsString();
    return jsonDecode(txt) as Map<String, dynamic>;
  }

  /// List saved session files in <app-docs>/formcheck
  static Future<List<FileSystemEntity>> listSessions() async {
    final dir = await getApplicationDocumentsDirectory();
    final outDir = Directory('${dir.path}/formcheck');
    if (!await outDir.exists()) return <FileSystemEntity>[];
    return outDir.list(followLinks: false).toList();
  }

  /// Delete a saved session file.
  static Future<void> deleteFile(File file) async {
    if (await file.exists()) {
      await file.delete();
    }
  }
}
