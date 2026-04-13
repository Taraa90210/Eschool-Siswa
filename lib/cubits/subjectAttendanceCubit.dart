import 'package:flutter/foundation.dart';
import 'package:equatable/equatable.dart';
import 'package:eschool/data/models/subjectAttendanceModel.dart';
import 'package:eschool/data/repositories/studentRepository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:eschool/data/models/sessionYear.dart';

abstract class SubjectAttendanceState extends Equatable {
  @override
  List<Object?> get props => [];
}

class SubjectAttendanceInitial extends SubjectAttendanceState {}

class SubjectAttendanceFetchInProgress extends SubjectAttendanceState {}

class SubjectAttendanceFetchSuccess extends SubjectAttendanceState {
  final List<SubjectAttendance> subjectAttendances;
  final SessionYear sessionYear;
  final DateTime date;

  SubjectAttendanceFetchSuccess({
    required this.subjectAttendances,
    required this.sessionYear,
    required this.date,
  });

  @override
  List<Object?> get props => [subjectAttendances, sessionYear, date];
}

class SubjectAttendanceFetchFailure extends SubjectAttendanceState {
  final String errorMessage;

  SubjectAttendanceFetchFailure(this.errorMessage);

  @override
  List<Object?> get props => [errorMessage];
}

class SubjectAttendanceCubit extends Cubit<SubjectAttendanceState> {
  final StudentRepository _studentRepository;

  SubjectAttendanceCubit(this._studentRepository)
      : super(SubjectAttendanceInitial());

  Future<void> fetchSubjectAttendance({
    required bool useParentApi,
    required int childId,
    required DateTime date,
  }) async {
    try {
      emit(SubjectAttendanceFetchInProgress());

      final result = await _studentRepository.fetchSubjectAttendance(
        useParentApi: useParentApi,
        childId: childId,
      );

      emit(SubjectAttendanceFetchSuccess(
        subjectAttendances: result['subjectAttendances'],
        sessionYear: result['sessionYear'],
        date: date,
      ));
    } catch (e) {
      debugPrint("Error in cubit: $e"); // Untuk debugging
      emit(SubjectAttendanceFetchFailure(e.toString()));
    }
  }
}


