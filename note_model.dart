class NoteModel {
  int? id;
  String title;
  String content;
  String color;
  bool isPinned;
  bool isLocked;
  bool isDeleted;
  String? category;
  DateTime createdAt;
  DateTime updatedAt;

  NoteModel({
    this.id,
    required this.title,
    required this.content,
    this.color = '#FFFFFF',
    this.isPinned = false,
    this.isLocked = false,
    this.isDeleted = false,
    this.category,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'color': color,
      'isPinned': isPinned ? 1 : 0,
      'isLocked': isLocked ? 1 : 0,
      'isDeleted': isDeleted ? 1 : 0,
      'category': category,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory NoteModel.fromMap(Map<String, dynamic> map) {
    return NoteModel(
      id: map['id'],
      title: map['title'] ?? '',
      content: map['content'] ?? '',
      color: map['color'] ?? '#FFFFFF',
      isPinned: map['isPinned'] == 1,
      isLocked: map['isLocked'] == 1,
      isDeleted: map['isDeleted'] == 1,
      category: map['category'],
      createdAt: DateTime.parse(map['createdAt']),
      updatedAt: DateTime.parse(map['updatedAt']),
    );
  }

  NoteModel copyWith({
    int? id,
    String? title,
    String? content,
    String? color,
    bool? isPinned,
    bool? isLocked,
    bool? isDeleted,
    String? category,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return NoteModel(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      color: color ?? this.color,
      isPinned: isPinned ?? this.isPinned,
      isLocked: isLocked ?? this.isLocked,
      isDeleted: isDeleted ?? this.isDeleted,
      category: category ?? this.category,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
