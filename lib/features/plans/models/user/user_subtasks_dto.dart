class UserSubtasksDto {
  final String id;
  final bool isCompleted;
  final String contentType;
  final String content;
  final int? displayOrder;
  final String? duration;

  UserSubtasksDto({
    required this.id,
    required this.isCompleted,
    required this.contentType,
    required this.content,
    this.displayOrder,
    this.duration,
  });

  factory UserSubtasksDto.fromJson(Map<String, dynamic> json) {
    return UserSubtasksDto(
      id: json['id'] as String,
      isCompleted: json['is_completed'] as bool,
      contentType: json['content_type'] as String,
      content: json['content'] as String,
      displayOrder: json['display_order'] as int?,
      duration: json['duration'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'is_completed': isCompleted,
      'content_type': contentType,
      'content': content,
      'display_order': displayOrder,
      'duration': duration,
    };
  }
}
