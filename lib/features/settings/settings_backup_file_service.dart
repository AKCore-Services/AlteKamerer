import 'dart:convert';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';

abstract interface class SettingsBackupFileService {
  Future<bool> save(String contents);

  Future<String?> pick();
}

class FilePickerSettingsBackupFileService implements SettingsBackupFileService {
  const FilePickerSettingsBackupFileService();

  static const fileName = 'altekamerer-settings.json';

  @override
  Future<bool> save(String contents) async {
    final uri = await FilePicker.saveFile(
      fileName: fileName,
      bytes: Uint8List.fromList(utf8.encode(contents)),
      mimeType: 'application/json',
      type: FileType.custom,
      allowedExtensions: const ['json'],
    );

    return uri != null;
  }

  @override
  Future<String?> pick() async {
    final file = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: const ['json'],
    );

    if (file == null) {
      return null;
    }

    final bytes = await file.readAsBytes();

    try {
      return utf8.decode(bytes);
    } on FormatException catch (error) {
      throw SettingsBackupFileFormatException(error);
    }
  }
}

class SettingsBackupFileFormatException implements Exception {
  const SettingsBackupFileFormatException(this.cause);

  final Object cause;

  @override
  String toString() => 'The selected settings file is not valid UTF-8.';
}
