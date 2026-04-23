import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:eschool/data/models/extracurricular/extracurricular.dart';
import 'package:eschool/data/repositories/extracurricular/extracurricularRepository.dart';

abstract class ExtracurricularState {}

class ExtracurricularInitial extends ExtracurricularState {}

class ExtracurricularFetchInProgress extends ExtracurricularState {}

class ExtracurricularFetchSuccess extends ExtracurricularState {
  final List<Extracurricular> extracurriculars;
  final int total;
  final int currentPage;
  final int lastPage;

  ExtracurricularFetchSuccess({
    required this.extracurriculars,
    required this.total,
    required this.currentPage,
    required this.lastPage,
  });
}

class ExtracurricularFetchFailure extends ExtracurricularState {
  final String errorMessage;

  ExtracurricularFetchFailure(this.errorMessage);
}

class ExtracurricularCubit extends Cubit<ExtracurricularState> {
  final ExtracurricularRepository _extracurricularRepository;

  ExtracurricularCubit(this._extracurricularRepository) : super(ExtracurricularInitial());

  Future<void> fetchExtracurriculars({
    int? offset,
    int? limit,
    String? sort,
    String? order,
    String? search,
  }) async {
    emit(ExtracurricularFetchInProgress());
    try {
      final result = await _extracurricularRepository.fetchExtracurriculars(
        offset: offset,
        limit: limit,
        sort: sort,
        order: order,
        search: search,
      );

      emit(ExtracurricularFetchSuccess(
        extracurriculars: result['extracurriculars'],
        total: result['total'],
        currentPage: result['current_page'],
        lastPage: result['last_page'],
      ));
    } catch (e) {
      emit(ExtracurricularFetchFailure(e.toString()));
    }
  }

  Future<void> searchExtracurriculars(String query) async {
    await fetchExtracurriculars(search: query);
  }

  void updateExtracurriculars(List<Extracurricular> updatedExtracurriculars) {
    if (state is ExtracurricularFetchSuccess) {
      final currentState = state as ExtracurricularFetchSuccess;
      emit(ExtracurricularFetchSuccess(
        extracurriculars: updatedExtracurriculars,
        total: currentState.total,
        currentPage: currentState.currentPage,
        lastPage: currentState.lastPage,
      ));
    }
  }
}
