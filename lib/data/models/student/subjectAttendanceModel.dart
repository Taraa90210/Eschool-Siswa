import 'package:eschool/data/models/academic/subject.dart';
import 'package:eschool/utils/system/constants.dart';

class SubjectAttendance {
  SubjectAttendance({
    required this.id,
    required this.subjectAttendanceId,
    required this.studentId,
    required this.type,
    this.note,
    required this.createdAt,
    required this.updatedAt,
    required this.sessionYear,
    required this.subjectAttendance,
  });

  late final int id;
  late final int subjectAttendanceId;
  late final int studentId;
  late final int type;
  late final String? note;
  late final String createdAt;
  late final String updatedAt;
  late final Map<String, dynamic> sessionYear;
  late final SubjectAttendanceDetails subjectAttendance;

  SubjectAttendance.fromJson(Map<String, dynamic> json) {
    id = json['id'] ?? 0;
    subjectAttendanceId = json['subject_attendance_id'] ?? 0;
    studentId = json['student_id'] ?? 0;
    type = json['type'] ?? 0;
    note = json['note'];
    createdAt = json['created_at'] ?? '';
    updatedAt = json['updated_at'] ?? '';
    sessionYear = json['session_year'] ?? {};
    subjectAttendance = SubjectAttendanceDetails.fromJson(json['subject_attendance'] ?? {});
  }

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{};
    data['id'] = id;
    data['subject_attendance_id'] = subjectAttendanceId;
    data['student_id'] = studentId;
    data['type'] = type;
    data['note'] = note;
    data['created_at'] = createdAt;
    data['updated_at'] = updatedAt;
    data['session_year'] = sessionYear;
    data['subject_attendance'] = subjectAttendance.toJson();
    return data;
  }
}

class SubjectAttendanceDetails {
  SubjectAttendanceDetails({
    required this.id,
    required this.classSectionId,
    required this.sessionYearId,
    required this.date,
    required this.schoolId,
    required this.timetableId,
    required this.jumlahJp,
    required this.materi,
    this.lampiran,
    required this.createdAt,
    required this.updatedAt,
    required this.rollNumber,
    required this.timetable,
  });

  late final int id;
  late final int classSectionId;
  late final int sessionYearId;
  late final String date;
  late final int schoolId;
  late final int timetableId;
  late final int jumlahJp;
  late final String materi;
  late final String? lampiran;
  late final String createdAt;
  late final String updatedAt;
  late final String rollNumber;
  late final Timetable timetable;

  SubjectAttendanceDetails.fromJson(Map<String, dynamic> json) {
    id = json['id'] ?? 0;
    classSectionId = json['class_section_id'] ?? 0;
    sessionYearId = json['session_year_id'] ?? 0;
    date = json['date'] ?? '';
    schoolId = json['school_id'] ?? 0;
    timetableId = json['timetable_id'] ?? 0;
    jumlahJp = json['jumlah_jp'] ?? 0;
    materi = json['materi'] ?? '';
    
    // Format lampiran dengan base URL dan storage
    final lampiranValue = json['lampiran'];
    if (lampiranValue != null && lampiranValue.toString().isNotEmpty) {
      lampiran = lampiranValue.toString().startsWith('http')
          ? lampiranValue
          : '$baseUrl/storage/$lampiranValue';
    } else {
      lampiran = null;
    }
    
    createdAt = json['created_at'] ?? '';
    updatedAt = json['updated_at'] ?? '';
    rollNumber = json['roll_number'] ?? '';
    timetable = Timetable.fromJson(json['timetable'] ?? {});
  }

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{};
    data['id'] = id;
    data['class_section_id'] = classSectionId;
    data['session_year_id'] = sessionYearId;
    data['date'] = date;
    data['school_id'] = schoolId;
    data['timetable_id'] = timetableId;
    data['jumlah_jp'] = jumlahJp;
    data['materi'] = materi;
    data['lampiran'] = lampiran;
    data['created_at'] = createdAt;
    data['updated_at'] = updatedAt;
    data['roll_number'] = rollNumber;
    data['timetable'] = timetable.toJson();
    return data;
  }
}

class Timetable {
  Timetable({
    required this.id,
    required this.subjectTeacherId,
    required this.classSectionId,
    required this.subjectId,
    required this.startTime,
    required this.endTime,
    this.note,
    required this.day,
    required this.type,
    this.semesterId,
    required this.schoolId,
    required this.title,
    required this.subject,
  });

  late final int id;
  late final int subjectTeacherId;
  late final int classSectionId;
  late final int subjectId;
  late final String startTime;
  late final String endTime;
  late final String? note;
  late final String day;
  late final String type;
  late final int? semesterId;
  late final int schoolId;
  late final String title;
  late final Subject subject;

  Timetable.fromJson(Map<String, dynamic> json) {
    id = json['id'] ?? 0;
    subjectTeacherId = json['subject_teacher_id'] ?? 0;
    classSectionId = json['class_section_id'] ?? 0;
    subjectId = json['subject_id'] ?? 0;
    startTime = json['start_time'] ?? '';
    endTime = json['end_time'] ?? '';
    note = json['note'];
    day = json['day'] ?? '';
    type = json['type'] ?? '';
    semesterId = json['semester_id'];
    schoolId = json['school_id'] ?? 0;
    title = json['title'] ?? '';
    subject = Subject.fromJson(json['subject'] ?? {});
  }

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{};
    data['id'] = id;
    data['subject_teacher_id'] = subjectTeacherId;
    data['class_section_id'] = classSectionId;
    data['subject_id'] = subjectId;
    data['start_time'] = startTime;
    data['end_time'] = endTime;
    data['note'] = note;
    data['day'] = day;
    data['type'] = type;
    data['semester_id'] = semesterId;
    data['school_id'] = schoolId;
    data['title'] = title;
    data['subject'] = subject.toJson();
    return data;
  }
}

// class SessionYear {
//   SessionYear({
//     required this.id,
//     required this.name,
//     required this.default_,
//     required this.startDate,
//     required this.endDate,
//     required this.schoolId,
//     required this.createdAt,
//     required this.updatedAt,
//     this.deletedAt,
//   });

//   late final int id;
//   late final String name;
//   late final int default_;
//   late final String startDate;
//   late final String endDate;
//   late final int schoolId;
//   late final String createdAt;
//   late final String updatedAt;
//   late final String? deletedAt;

//   SessionYear.fromJson(Map<String, dynamic> json) {
//     id = json['id'] ?? 0;
//     name = json['name'] ?? '';
//     default_ = json['default'] ?? 0;
//     startDate = json['start_date'] ?? '';
//     endDate = json['end_date'] ?? '';
//     schoolId = json['school_id'] ?? 0;
//     createdAt = json['created_at'] ?? '';
//     updatedAt = json['updated_at'] ?? '';
//     deletedAt = json['deleted_at'];
//   }

//   Map<String, dynamic> toJson() {
//     final data = <String, dynamic>{};
//     data['id'] = id;
//     data['name'] = name;
//     data['default'] = default_;
//     data['start_date'] = startDate;
//     data['end_date'] = endDate;
//     data['school_id'] = schoolId;
//     data['created_at'] = createdAt;
//     data['updated_at'] = updatedAt;
//     data['deleted_at'] = deletedAt;
//     return data;
//   }
// }