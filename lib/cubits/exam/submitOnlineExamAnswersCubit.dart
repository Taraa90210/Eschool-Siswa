import 'package:flutter/foundation.dart';
import 'package:eschool/data/repositories/exam/onlineExamRepository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

abstract class SubmitOnlineExamAnswersState {}

class SubmitOnlineExamAnswersInitial extends SubmitOnlineExamAnswersState {}

class SubmitOnlineExamAnswersInProgress extends SubmitOnlineExamAnswersState {}

class SubmitOnlineExamAnswersSuccess extends SubmitOnlineExamAnswersState {
  final String message;

  SubmitOnlineExamAnswersSuccess({required this.message});
}

class SubmitOnlineExamAnswersFailure extends SubmitOnlineExamAnswersState {
  final String errorMessage;

  SubmitOnlineExamAnswersFailure(this.errorMessage);
}

class SubmitOnlineExamAnswersCubit extends Cubit<SubmitOnlineExamAnswersState> {
  final OnlineExamRepository _onlineExamRepository;

  SubmitOnlineExamAnswersCubit(this._onlineExamRepository)
      : super(SubmitOnlineExamAnswersInitial());

  void submitAnswers(
      {required int examId, required Map<int, dynamic> answers}) async {
    emit(SubmitOnlineExamAnswersInProgress());
    try {
      debugPrint("-------X-------");
      emit(SubmitOnlineExamAnswersSuccess(
          message: await _onlineExamRepository.setExamOnlineAnswers(
              examId: examId, answerData: answers)));
    } catch (e) {
      debugPrint("-------Y-------");
      emit(SubmitOnlineExamAnswersFailure(e.toString()));
    }
  }
}


