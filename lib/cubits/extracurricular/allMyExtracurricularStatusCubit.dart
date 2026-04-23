import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:eschool/data/models/extracurricular/studentExtracurricular.dart';
import 'package:eschool/data/repositories/extracurricularRepository.dart';

abstract class AllMyExtracurricularStatusState {}

class AllMyExtracurricularStatusInitial extends AllMyExtracurricularStatusState {}

class AllMyExtracurricularStatusFetchInProgress extends AllMyExtracurricularStatusState {}

class AllMyExtracurricularStatusFetchSuccess extends AllMyExtracurricularStatusState {
  final List<StudentExtracurricular> allMyExtracurriculars;
  final int total;

  AllMyExtracurricularStatusFetchSuccess({
    required this.allMyExtracurriculars,
    required this.total,
  });

  // Helper method to get status by extracurricular ID
  StudentExtracurricular? getStatusByExtracurricularId(int extracurricularId) {
    try {
      return allMyExtracurriculars.firstWhere(
        (element) => element.extracurricularId == extracurricularId,
      );
    } catch (_) {
      return null; // Not found
    }
  }
}

class AllMyExtracurricularStatusFetchFailure extends AllMyExtracurricularStatusState {
  final String errorMessage;

  AllMyExtracurricularStatusFetchFailure(this.errorMessage);
}

class AllMyExtracurricularStatusCubit extends Cubit<AllMyExtracurricularStatusState> {
  final ExtracurricularRepository _extracurricularRepository;

  AllMyExtracurricularStatusCubit(this._extracurricularRepository) 
    : super(AllMyExtracurricularStatusInitial());

  Future<void> fetchAllMyExtracurricularStatuses() async {
    emit(AllMyExtracurricularStatusFetchInProgress());
    try {
      final result = await _extracurricularRepository.fetchAllMyExtracurricularStatuses();

      emit(AllMyExtracurricularStatusFetchSuccess(
        allMyExtracurriculars: result['extracurriculars'],
        total: result['total'],
      ));
    } catch (e) {
      emit(AllMyExtracurricularStatusFetchFailure(e.toString()));
    }
  }

  void reset() {
    emit(AllMyExtracurricularStatusInitial());
  }
}
