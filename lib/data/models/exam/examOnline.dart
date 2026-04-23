import 'package:eschool/data/models/academic/subject.dart';

class ExamOnline {
  late int? id;
  late int? classSectionId;
  late int? classSubjectId;
  late String? title;
  late int? examKey;
  late int? duration;
  late String? startDate;
  late String? endDate;
  late int? sessionYearId;
  late int? schoolId;
  late String? createdAt;
  late String? updatedAt;
  late String? classSectionWithMedium;
  late String? subjectWithName;
  late Subject? subject;
  late String? totalMarks;
  late String? examStaus;
  late String? subjectName;
  late int? status;

  ExamOnline(
      {this.id,
      this.totalMarks,
      this.classSectionId,
      this.classSubjectId,
      this.title,
      this.examKey,
      this.duration,
      this.startDate,
      this.endDate,
      this.sessionYearId,
      this.schoolId,
      this.createdAt,
      this.updatedAt,
      this.classSectionWithMedium,
      this.subjectWithName,
      this.subject,
      this.examStaus,
      this.subjectName,
      this.status});

  ExamOnline copyWith(
      {int? id,
      int? classSectionId,
      String? examStatus,
      int? classSubjectId,
      String? title,
      int? examKey,
      int? duration,
      String? startDate,
      String? endDate,
      int? sessionYearId,
      int? schoolId,
      String? createdAt,
      String? updatedAt,
      String? classSectionWithMedium,
      String? subjectWithName,
      Subject? subject,
      String? subjectName,
      String? totalMarks,
      int? status}) {
    return ExamOnline(
      examStaus: examStaus ?? this.examStaus,
      subject: subject ?? this.subject,
      totalMarks: totalMarks ?? this.totalMarks,
      id: id ?? this.id,
      classSectionId: classSectionId ?? this.classSectionId,
      classSubjectId: classSubjectId ?? this.classSubjectId,
      title: title ?? this.title,
      examKey: examKey ?? this.examKey,
      duration: duration ?? this.duration,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      sessionYearId: sessionYearId ?? this.sessionYearId,
      schoolId: schoolId ?? this.schoolId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      classSectionWithMedium:
          classSectionWithMedium ?? this.classSectionWithMedium,
      subjectWithName: subjectWithName ?? this.subjectWithName,
      subjectName: subjectName ?? this.subjectName,
      status: status ?? this.status
    );
  }

  ExamOnline.fromJson(Map<String, dynamic> json) {
    print("OK1");
    id = json['id'] as int?;
    // print("OK2");
    classSectionId = json['class_section_id'] as int?;
    // print("OK3");
    classSubjectId = json['class_subject_id'] as int?;
    // print("OK4");
    title = json['title'] as String?;
    // print("OK5");
    examKey = json['exam_key'] as int?;
    // print("OK6");
    duration = json['duration'] as int?;
    // print("OK7");
    startDate = json['start_date'] as String?;
    // print("OK8");
    endDate = json['end_date'] as String?;
    // print("OK9");
    sessionYearId = json['session_year_id'] as int?;
    print("OK10");
    schoolId = json['school_id'] as int?;
    // print("OK11");
    createdAt = json['created_at'] as String?;
    // print("OK12");
    updatedAt = json['updated_at'] as String?;
    // print("OK13");
    subjectName = json['subject_name'] ?? '';
    print(subjectName);
    // print("+++");
    classSectionWithMedium = json['class_section_with_medium'] as String?;
    // print("OK14");
    if (json['class_subject'] != null &&
        json['class_subject']['subject'] != null) {
      // print("OK15");
      subject = Subject.fromJson(
          Map<String, dynamic>.from(json['class_subject']['subject']));
      // Ambil subject name dari object subject jika subjectName kosong
      if (subjectName == null || subjectName!.isEmpty) {
        subjectName = subject?.name ?? '';
      }
    } else if (json['subject'] != null) {
      // Untuk parent API yang mengembalikan subject langsung
      subject = Subject.fromJson(
          Map<String, dynamic>.from(json['subject']));
      // Ambil subject name dari object subject jika subjectName kosong
      if (subjectName == null || subjectName!.isEmpty) {
        subjectName = subject?.name ?? '';
      }
    } else {
      // print("OK16");
      subject = null;
    }

    totalMarks = (json['total_points'] ?? 0).toString();
    // print("OK17");
    status = int.tryParse(json['status'].toString()) ?? 0;
    final now = DateTime.now();
    final startDateTime = startDate != null ? DateTime.parse(startDate!) : null;
    final endDateTime = endDate != null ? DateTime.parse(endDate!) : null;

    if (startDateTime == null || endDateTime == null) {
      examStaus = "Unknown";
    } else if (now.isBefore(startDateTime)) {
      examStaus = "Upcoming";
    } else if (now.isAfter(endDateTime)) {
      examStaus = "Completed";
    } else {
      examStaus = "On Going";
    }

    // print("OK18");
    subjectWithName = json['subject_with_name'] as String?;
    // print("Ok19");
  }

  ///[Exam status will be (On Going) and (Upcoming) ]
  bool get isExamStarted => examStaus == "On Going" ? true : false;

  Map<String, dynamic> toJson() => {
        'id': id,
        'class_section_id': classSectionId,
        'class_subject_id': classSubjectId,
        'title': title,
        'exam_key': examKey,
        'duration': duration,
        'start_date': startDate,
        'end_date': endDate,
        'session_year_id': sessionYearId,
        'school_id': schoolId,
        'created_at': createdAt,
        'updated_at': updatedAt,
        'total_marks': totalMarks,
        'class_section_with_medium': classSectionWithMedium,
        'subject_with_name': subjectWithName,
        'exam_status_name': examStaus,
        'class_subject': {'subject': subject?.toJson()}
      };
}
