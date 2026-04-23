import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:eschool/data/models/extracurricular/studentExtracurricular.dart';
import 'package:eschool/data/repositories/extracurricularRepository.dart';

abstract class MyExtracurricularState {}

class MyExtracurricularInitial extends MyExtracurricularState {}

class MyExtracurricularFetchInProgress extends MyExtracurricularState {}

class MyExtracurricularFetchSuccess extends MyExtracurricularState {
  final List<StudentExtracurricular> myExtracurriculars;
  final int total;
  final int currentPage;
  final int lastPage;

  MyExtracurricularFetchSuccess({
    required this.myExtracurriculars,
    required this.total,
    required this.currentPage,
    required this.lastPage,
  });
}

class MyExtracurricularFetchFailure extends MyExtracurricularState {
  final String errorMessage;

  MyExtracurricularFetchFailure(this.errorMessage);
}

class MyExtracurricularCubit extends Cubit<MyExtracurricularState> {
  final ExtracurricularRepository _extracurricularRepository;

  MyExtracurricularCubit(this._extracurricularRepository) : super(MyExtracurricularInitial());

  Future<void> fetchMyExtracurriculars({
    String? search,
  }) async {
    emit(MyExtracurricularFetchInProgress());
    try {
      final result = await _extracurricularRepository.fetchMyExtracurriculars(
        search: search,
      );

      emit(MyExtracurricularFetchSuccess(
        myExtracurriculars: result['extracurriculars'],
        total: result['total'],
        currentPage: result['current_page'],
        lastPage: result['last_page'],
      ));
    } catch (e) {
      emit(MyExtracurricularFetchFailure(e.toString()));
    }
  }
}
