import 'package:intl/intl.dart';

class Contact {
  final int id;
  final String name;
  final String email;
  final String subject;
  final String message;
  final String type; // "inquiry" or "report"
  final String status; // "new", "replied", "closed"
  final String? adminReply;
  final DateTime? repliedAt;
  final DateTime createdAt;

  Contact({
    required this.id,
    required this.name,
    required this.email,
    required this.subject,
    required this.message,
    required this.type,
    required this.status,
    this.adminReply,
    this.repliedAt,
    required this.createdAt,
  });

  // Helper method to parse date in multiple formats
  static DateTime? _parseDateTime(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return null;

    try {
      // Try ISO 8601 format first (standard format)
      return DateTime.parse(dateStr);
    } catch (e) {
      try {
        // Try DD/MM/YYYY HH:mm:ss format (Indonesian format)
        final formatter = DateFormat('dd/MM/yyyy HH:mm:ss');
        return formatter.parse(dateStr);
      } catch (e) {
        try {
          // Try DD/MM/YYYY format without time
          final formatter = DateFormat('dd/MM/yyyy');
          return formatter.parse(dateStr);
        } catch (e) {
          // If all parsing attempts fail, return null
          return null;
        }
      }
    }
  }

  factory Contact.fromJson(Map<String, dynamic> json) {
    return Contact(
      id: json['id'] ?? 0,
      name: json['name'] ?? "",
      email: json['email'] ?? "",
      subject: json['subject'] ?? "",
      message: json['message'] ?? "",
      type: json['type'] ?? "inquiry",
      status: json['status'] ?? "new",
      adminReply: json['admin_reply'],
      repliedAt: _parseDateTime(json['replied_at']),
      createdAt: _parseDateTime(json['created_at']) ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'subject': subject,
      'message': message,
      'type': type,
      'status': status,
      'admin_reply': adminReply,
      'replied_at': repliedAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }

  // Helper methods
  bool get isInquiry => type == "inquiry";
  bool get isReport => type == "report";
  bool get isNew => status == "new";
  bool get isReplied => status == "replied";
  bool get isClosed => status == "closed";

  String get typeDisplayName {
    switch (type) {
      case "inquiry":
        return "Pertanyaan";
      case "report":
        return "Laporan";
      default:
        return type;
    }
  }

  String get statusDisplayName {
    switch (status) {
      case "new":
        return "Baru";
      case "replied":
        return "Dibalas";
      case "closed":
        return "Ditutup";
      default:
        return status;
    }
  }
}
