import 'package:equatable/equatable.dart';
import 'package:eschool/data/models/academic/sessionYear.dart';
import 'package:eschool/data/models/student/attendanceDay.dart';
import 'package:eschool/data/repositories/student/studentRepository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/foundation.dart';

abstract class AttendanceState extends Equatable {}

class AttendanceInitial extends AttendanceState {
  @override
  List<Object?> get props => [];
}

class AttendanceFetchInProgress extends AttendanceState {
  @override
  List<Object?> get props => [];
}

class AttendanceFetchSuccess extends AttendanceState {
  final List<AttendanceDay> attendanceDays;
  final SessionYear sessionYear;

  AttendanceFetchSuccess(
      {required this.attendanceDays, required this.sessionYear,});
  @override
  List<Object?> get props => [attendanceDays];
}

class AttendanceFetchFailure extends AttendanceState {
  final String errorMessage;

  AttendanceFetchFailure(this.errorMessage);

  @override
  List<Object?> get props => [errorMessage];
}

class AttendanceCubit extends Cubit<AttendanceState> {
  final StudentRepository _studentRepository;

  AttendanceCubit(this._studentRepository) : super(AttendanceInitial());

  void fetchAttendance(
      {required int month,
      required int year,
      required bool useParentApi,
      int? childId,}) async {
    emit(AttendanceFetchInProgress());

    try {
      // Fetch attendance normal
      final attendanceResult = await _studentRepository.fetchAttendance(
        month: month,
        year: year,
        childId: childId ?? 0,
        useParentApi: useParentApi,
      );

      List<AttendanceDay> attendanceDays = attendanceResult['attendanceDays'];
      final SessionYear sessionYear = attendanceResult['sessionYear'];

      // Fetch subject attendance untuk merge data
      try {
        final subjectAttendanceResult = await _studentRepository.fetchSubjectAttendance(
          childId: childId ?? 0,
          useParentApi: useParentApi,
        );

        final subjectAttendances = subjectAttendanceResult['subjectAttendances'];

        // Filter subject attendance hanya untuk bulan dan tahun yang diminta
        final filteredSubjectAttendances = subjectAttendances.where((sa) {
          final date = DateTime.parse(sa.subjectAttendance.date);
          return date.month == month && date.year == year;
        }).toList();

        if (kDebugMode) {
          print("Original attendance days: ${attendanceDays.length}");
          print("Subject attendances for month $month: ${filteredSubjectAttendances.length}");
        }

        // Convert subject attendance ke AttendanceDay dan merge
        for (var subjectAttendance in filteredSubjectAttendances) {
          final date = DateTime.parse(subjectAttendance.subjectAttendance.date);
          
          // Cek apakah tanggal ini sudah ada di attendanceDays
          final existingIndex = attendanceDays.indexWhere(
            (ad) => ad.date.year == date.year && 
                    ad.date.month == date.month && 
                    ad.date.day == date.day
          );

          if (existingIndex == -1) {
            // Tanggal belum ada, tambahkan dari subject attendance
            final newAttendanceDay = AttendanceDay.fromSubjectAttendance(subjectAttendance);
            attendanceDays.add(newAttendanceDay);
            
            if (kDebugMode) {
              print("Added attendance from subject: ${date} type: ${subjectAttendance.type}");
            }
          } else {
            // Tanggal sudah ada, update jika type dari subject attendance lebih "buruk"
            // Priority: 4 (Alpa) > 0 (Absent) > 3 (Izin) > 2 (Sakit) > 1 (Hadir)
            final existingType = attendanceDays[existingIndex].type;
            final newType = subjectAttendance.type;
            
            if (_isWorseAttendanceType(newType, existingType)) {
              attendanceDays[existingIndex] = AttendanceDay.fromSubjectAttendance(subjectAttendance);
              
              if (kDebugMode) {
                print("Updated attendance for ${date}: $existingType -> $newType");
              }
            }
          }
        }

        if (kDebugMode) {
          print("Merged attendance days: ${attendanceDays.length}");
        }
      } catch (e) {
        if (kDebugMode) {
          print("Failed to fetch subject attendance, using attendance data only: $e");
        }
        // Jika gagal fetch subject attendance, lanjutkan dengan data attendance saja
      }

      emit(AttendanceFetchSuccess(
        sessionYear: sessionYear,
        attendanceDays: attendanceDays,
      ));
    } catch (e) {
      emit(AttendanceFetchFailure(e.toString()));
    }
  }

  // Helper method untuk menentukan attendance type mana yang lebih buruk
  // Return true jika newType lebih buruk dari existingType
  bool _isWorseAttendanceType(int newType, int existingType) {
    const typePriority = {
      4: 4, // Alpa - paling buruk
      0: 3, // Absent
      3: 2, // Izin
      2: 1, // Sakit
      1: 0, // Hadir - paling baik
    };
    
    return (typePriority[newType] ?? 0) > (typePriority[existingType] ?? 0);
  }
}
