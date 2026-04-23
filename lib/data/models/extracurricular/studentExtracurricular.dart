import 'package:eschool/data/models/extracurricular/extracurricular.dart';
import 'package:eschool/data/models/auth/student.dart';

class StudentExtracurricular {
  final int? id;
  final int? studentId;
  final int? extracurricularId;
  final String? createdAt;
  final String? updatedAt;
  final String? deletedAt;
  final int? status;
  final Extracurricular? extracurricular;
  final Student? student;

  StudentExtracurricular({
    this.id,
    this.studentId,
    this.extracurricularId,
    this.createdAt,
    this.updatedAt,
    this.deletedAt,
    this.status,
    this.extracurricular,
    this.student,
  });

  StudentExtracurricular copyWith({
    int? id,
    int? studentId,
    int? extracurricularId,
    String? createdAt,
    String? updatedAt,
    String? deletedAt,
    int? status,
    Extracurricular? extracurricular,
    Student? student,
  }) {
    return StudentExtracurricular(
      id: id ?? this.id,
      studentId: studentId ?? this.studentId,
      extracurricularId: extracurricularId ?? this.extracurricularId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      status: status ?? this.status,
      extracurricular: extracurricular ?? this.extracurricular,
      student: student ?? this.student,
    );
  }

  factory StudentExtracurricular.fromJson(Map<String, dynamic> json) {
    return StudentExtracurricular(
      id: _parseInt(json['id']),
      studentId: _parseInt(json['student_id']),
      extracurricularId: _parseInt(json['estrakulikuler_id']),
      createdAt: json['created_at']?.toString(),
      updatedAt: json['updated_at']?.toString(),
      deletedAt: json['deleted_at']?.toString(),
      status: _parseInt(json['status']),
      extracurricular: json['estrakulikuler'] != null
          ? Extracurricular.fromJson(Map.from(json['estrakulikuler']))
          : null,
      student: json['student'] != null
          ? Student.fromJson(Map.from(json['student']))
          : null,
    );
  }

  static int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is String) return int.tryParse(value);
    return null;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'student_id': studentId,
      'estrakulikuler_id': extracurricularId,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'deleted_at': deletedAt,
      'status': status,
      'estrakulikuler': extracurricular?.toJson(),
      'student': student?.toJson(),
    };
  }

  bool get isActive => status == 1; // 0 = pending, 1 = active/approved

  @override
  String toString() {
    return 'StudentExtracurricular{id: $id, studentId: $studentId, extracurricularId: $extracurricularId, status: $status}';
  }
}
