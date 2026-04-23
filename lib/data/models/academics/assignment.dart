import 'package:eschool/data/models/academics/studyMaterial.dart';
import 'package:eschool/data/models/academics/subject.dart';

class Assignment {
  Assignment({
    required this.id,
    required this.classSectionId,
    required this.subjectId,
    required this.name,
    required this.instructions,
    required this.dueDate,
    required this.points,
    required this.resubmission,
    required this.extraDaysForResubmission,
    required this.sessionYearId,
    required this.subject,
    required this.createdAt,
    required this.assignmentSubmission,
    required this.referenceMaterials,
    required this.schoolId,
    required this.max_file,
    required this.filetypes,
    required this.isText,
  });

  late final int id;
  late final int classSectionId;
  late final int subjectId;
  late final String name;
  late final DateTime createdAt; //It will work as assigned date
  late List<StudyMaterial> referenceMaterials;
  late final String instructions;
  late final DateTime dueDate;
  late final int points;
  late final int resubmission;
  late final int extraDaysForResubmission;
  late final int sessionYearId;
  late final int schoolId;
  late final int max_file;
  late final AssignmentSubmission assignmentSubmission;
  late final Subject subject;
  late final List<String> filetypes; // Properti baru
  late final bool isText;

  Assignment updateAssignmentSubmission(
    AssignmentSubmission newAssignmentSubmission,
  ) {
    return Assignment(
        schoolId: schoolId,
        createdAt: createdAt,
        id: id,
        classSectionId: classSectionId,
        subjectId: subjectId,
        name: name,
        instructions: instructions,
        dueDate: dueDate,
        points: points,
        resubmission: resubmission,
        extraDaysForResubmission: extraDaysForResubmission,
        sessionYearId: sessionYearId,
        subject: subject,
        assignmentSubmission: newAssignmentSubmission,
        referenceMaterials: referenceMaterials,
        filetypes: filetypes,
        isText: isText,
        max_file: max_file);
  }

  Assignment.fromJson(Map<String, dynamic> json) {
    id = int.tryParse(json['id']?.toString() ?? '') ?? 0;

    classSectionId =
        int.tryParse(json['class_section_id']?.toString() ?? '') ?? 0;

    subjectId = int.tryParse(json['subject_id']?.toString() ?? '') ?? 0;

    name = json['name'] ?? "";

    instructions = json['instructions'] ?? "";

    dueDate = json['due_date'] == null
        ? DateTime.now()
        : DateTime.parse(json['due_date']);

    points = int.tryParse(json['points']?.toString() ?? '') ?? 0;

    resubmission = int.tryParse(json['resubmission']?.toString() ?? '') ?? -1;

    extraDaysForResubmission =
        int.tryParse(json['extra_days_for_resubmission']?.toString() ?? '') ??
            0;

    sessionYearId =
        int.tryParse(json['session_year_id']?.toString() ?? '') ?? 0;

    referenceMaterials = ((json['file'] ?? []) as List)
        .map((file) => StudyMaterial.fromJson(Map.from(file)))
        .toList();

    assignmentSubmission =
        AssignmentSubmission.fromJson(Map.from(json['submission'] ?? {}));

    subject =
        Subject.fromJson(Map.from(json['class_subject']?['subject'] ?? {}));

    createdAt = json['created_at'] == null
        ? DateTime.now()
        : DateTime.parse(json['created_at'].toString());

    schoolId = int.tryParse(json['school_id']?.toString() ?? '') ?? 0;

    filetypes = List<String>.from(
        (json['filetypes'] ?? []).where((element) => element != null));

    max_file = int.tryParse(json['max_file']?.toString() ?? '') ?? 1;

    var textValue = json['text'];

    if (textValue is int) {
      isText = textValue == 1;
    } else if (textValue is bool) {
      isText = textValue;
    } else {
      isText = false;
    }
  }
}

class AssignmentSubmission {
  AssignmentSubmission({
    required this.id,
    required this.assignmentId,
    required this.studentId,
    required this.sessionYearId,
    required this.feedback,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    required this.points,
    required this.submittedFiles,
    required this.content,
  });
  late final int id;
  late final List<StudyMaterial> submittedFiles;
  late final int assignmentId;
  late final int studentId;
  late final int sessionYearId;
  late final String feedback;
  late final int status;
  late final DateTime createdAt;
  late final int points;
  late final DateTime updatedAt;
  late final String content;

  AssignmentSubmission.fromJson(Map<String, dynamic> json) {
    id = int.tryParse(json['id']?.toString() ?? '') ?? 0;
    points = int.tryParse(json['points']?.toString() ?? '') ?? 0;
    assignmentId = int.tryParse(json['assignment_id']?.toString() ?? '') ?? 0;
    studentId = int.tryParse(json['student_id']?.toString() ?? '') ?? 0;
    sessionYearId =
        int.tryParse(json['session_year_id']?.toString() ?? '') ?? 0;
    feedback = json['feedback'] ?? "";
    status = int.tryParse(json['status']?.toString() ?? '') ?? -1;
    createdAt = json['created_at'] == null
        ? DateTime.now()
        : DateTime.parse(json['created_at']);
    updatedAt = json['updated_at'] == null
        ? DateTime.now()
        : DateTime.parse(json['updated_at']);
    submittedFiles = ((json['file'] ?? []) as List)
        .map(
          (submittedFiles) => StudyMaterial.fromJson(Map.from(submittedFiles)),
        )
        .toList();
    content = json['content'] ?? "";
  }
}
