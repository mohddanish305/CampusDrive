enum FileType { folder, pdf, word, excel, image, notes, assignment, other }

class StudyItem {
  final String id;
  final String name;
  final String path;
  final String? parentId;
  final FileType type;
  final DateTime createdAt;
  final DateTime modifiedAt;
  final bool isSynced;
  final String? supabasePath;
  final String? supabaseUrl;
  final bool isFavorite;
  final String? userId;

  StudyItem({
    required this.id,
    required this.name,
    required this.path,
    this.parentId,
    required this.type,
    required this.createdAt,
    required this.modifiedAt,
    this.isSynced = false,
    this.supabasePath,
    this.supabaseUrl,
    this.isFavorite = false,
    this.userId,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'path': path,
      'parent_id': parentId,
      'type': type.index,
      'created_at': createdAt.toIso8601String(),
      'modified_at': modifiedAt.toIso8601String(),
      'is_synced': isSynced ? 1 : 0,
      'supabase_path': supabasePath,
      'supabase_url': supabaseUrl,
      'is_favorite': isFavorite ? 1 : 0,
      'user_id': userId,
    };
  }

  factory StudyItem.fromMap(Map<String, dynamic> map) {
    return StudyItem(
      id: map['id'],
      name: map['name'],
      path: map['path'],
      parentId: map['parent_id'],
      type: FileType.values[map['type']],
      createdAt: map['created_at'] is int
          ? DateTime.fromMillisecondsSinceEpoch(map['created_at'])
          : DateTime.parse(map['created_at']),
      modifiedAt: map['modified_at'] is int
          ? DateTime.fromMillisecondsSinceEpoch(map['modified_at'])
          : DateTime.parse(map['modified_at']),
      isSynced: map['is_synced'] == 1,
      supabasePath: map['supabase_path'],
      supabaseUrl: map['supabase_url'],
      isFavorite: map['is_favorite'] == 1,
      userId: map['user_id'],
    );
  }

  StudyItem copyWith({
    String? name,
    String? path,
    String? parentId,
    DateTime? modifiedAt,
    bool? isSynced,
    String? supabasePath,
    String? supabaseUrl,
    bool? isFavorite,
    String? userId,
  }) {
    return StudyItem(
      id: id,
      name: name ?? this.name,
      path: path ?? this.path,
      parentId: parentId ?? this.parentId,
      type: type,
      createdAt: createdAt,
      modifiedAt: modifiedAt ?? this.modifiedAt,
      isSynced: isSynced ?? this.isSynced,
      supabasePath: supabasePath ?? this.supabasePath,
      supabaseUrl: supabaseUrl ?? this.supabaseUrl,
      isFavorite: isFavorite ?? this.isFavorite,
      userId: userId ?? this.userId,
    );
  }
}
