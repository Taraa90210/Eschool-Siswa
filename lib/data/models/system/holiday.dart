class Holiday {
  Holiday({
    required this.id,
    required this.startDate,
    required this.endDate,
    required this.title,
    required this.description,
    required this.createdAt,
    required this.updatedAt,
  });
  late final int id;
  late final DateTime startDate;
  late final DateTime endDate;
  late final String title;
  late final String description;
  late final String createdAt;
  late final String updatedAt;

  Holiday.fromJson(Map<String, dynamic> json) {
    id = json['id'] ?? 0;
    startDate = DateTime.parse(json['start_date']);
    endDate = DateTime.parse(json['end_date']);
    title = json['title'] ?? "";
    description = json['description'] ?? "";
    createdAt = json['created_at'] ?? "";
    updatedAt = json['updated_at'] ?? "";
  }
}
