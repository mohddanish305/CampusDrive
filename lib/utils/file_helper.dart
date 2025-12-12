import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:campusdrive/models/file_model.dart';
import 'package:uuid/uuid.dart';
import 'package:path/path.dart' as p;

class FileHelper {
  static Future<FileModel?> pickAndProcessFile() async {
    final result = await FilePicker.platform.pickFiles();
    if (result != null && result.files.single.path != null) {
      final file = File(result.files.single.path!);
      final ext = p.extension(file.path);
      final category = FileModel.autoCategorize(ext);
      
      return FileModel(
        id: const Uuid().v4(),
        path: file.path,
        name: p.basename(file.path),
        category: category,
        type: ext,
        addedDate: DateTime.now(),
        tags: [],
      );
    }
    return null;
  }
}
