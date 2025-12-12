class FileModel {
  final String id;
  final String path;
  final String name;
  final String category;
  final String type;
  final DateTime addedDate;
  final List<String> tags;

  FileModel({
    required this.id,
    required this.path,
    required this.name,
    required this.category,
    required this.type,
    required this.addedDate,
    required this.tags,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'path': path,
      'name': name,
      'category': category,
      'type': type,
      'added_date': addedDate.millisecondsSinceEpoch,
      'tags': tags.join(','),
    };
  }

  factory FileModel.fromMap(Map<String, dynamic> map) {
    return FileModel(
      id: map['id'],
      path: map['path'],
      name: map['name'],
      category: map['category'],
      type: map['type'],
      addedDate: DateTime.fromMillisecondsSinceEpoch(map['added_date']),
      tags: (map['tags'] as String).split(','),
    );
  }

  static String autoCategorize(String extension) {
    extension = extension.toLowerCase().replaceAll('.', '');
    if (['pdf'].contains(extension)) return 'PDF';
    if (['png', 'jpg', 'jpeg', 'heic'].contains(extension)) return 'Images';
    if (['doc', 'docx', 'txt'].contains(extension)) return 'Documents';
    return 'Others';
  }
}
