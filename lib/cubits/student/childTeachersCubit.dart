import 'package:eschool/data/models/auth/student.dart';
import 'package:eschool/data/models/academic/subject.dart';
import 'package:eschool/data/models/academic/subjectTeacher.dart';
import 'package:eschool/data/repositories/auth/parentRepository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

abstract class ChildTeachersState {}

class ChildTeachersInitial extends ChildTeachersState {}

class ChildTeachersFetchInProgress extends ChildTeachersState {}

class ChildTeachersFetchSuccess extends ChildTeachersState {
  final List<SubjectTeacher> subjectTeachers;

  ChildTeachersFetchSuccess({required this.subjectTeachers});
}

class ChildTeachersFetchFailure extends ChildTeachersState {
  final String errorMessage;

  ChildTeachersFetchFailure(this.errorMessage);
}

class ChildTeachersCubit extends Cubit<ChildTeachersState> {
  final ParentRepository _parentRepository;

  ChildTeachersCubit(this._parentRepository) : super(ChildTeachersInitial());

  Future<void> fetchChildTeachers({required int childId}) async {
    emit(ChildTeachersFetchInProgress());
    try {
      // Fetch subject teachers and child profile concurrently
      final results = await Future.wait([
        _parentRepository.fetchChildTeachers(childId: childId),
        _parentRepository.fetchChildProfile(childId: childId),
      ]);

      final subjectTeachers = results[0] as List<SubjectTeacher>;
      final studentProfile = results[1] as Student;

      final classTeachers = studentProfile.classSection?.classTeachers ?? [];

      // Convert class teachers to SubjectTeacher with dummy subject
      final classTeachersWithSubject = classTeachers.map((e) {
        return e.copyWith(
          subject: Subject(
            name: "Wali Kelas",
            nameWithType: "Wali Kelas",
            type: "",
            image: "",
          ),
          subjectWithName: "Wali Kelas",
        );
      }).toList();

      // Combine lists: Class Teachers first
      final allTeachers = [...classTeachersWithSubject, ...subjectTeachers];

      emit(ChildTeachersFetchSuccess(subjectTeachers: allTeachers));
    } catch (e) {
      emit(ChildTeachersFetchFailure(e.toString()));
    }
  }
}
