import 'package:eschool/data/models/academic/studyMaterial.dart';

class Announcement {
  Announcement({
    required this.id,
    required this.title,
    required this.description,
    required this.createdAt,
    this.creator = "",
    this.files = const [],
  });

  final int id;
  final String title;
  final String description;
  final DateTime createdAt;
  final String creator;
  final List<StudyMaterial> files;

  factory Announcement.fromJson(Map<String, dynamic> json) {
    return Announcement(
      id: json['id'] ?? 0,
      title: json['title'] ?? "",
      description: json['description'] ?? "",
      createdAt: json['created_at'] == null
          ? DateTime.now()
          : DateTime.parse(json['created_at']),
      creator: json['creator'] ?? "",
      files: ((json['file'] ?? []) as List)
          .map((file) => StudyMaterial.fromJson(Map.from(file)))
          .toList(),
    );
  }
}
