import 'package:eschool/utils/system/labelKeys.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class AssignmentsTabSelectionState {
  //Assigned or completed
  final String assignmentFilterTabTitle;
  final int assignmentFilterByClassSubjectId;

  AssignmentsTabSelectionState({
    required this.assignmentFilterByClassSubjectId,
    required this.assignmentFilterTabTitle,
  });
}

class AssignmentsTabSelectionCubit extends Cubit<AssignmentsTabSelectionState> {
  AssignmentsTabSelectionCubit()
      : super(
          AssignmentsTabSelectionState(
            assignmentFilterByClassSubjectId: 0,
            assignmentFilterTabTitle: assignedKey,
          ),
        ); //Not-submitted/Assigned by default

  void changeAssignmentFilterTabTitle(String assignmentFilterTabTitle) {
    emit(
      AssignmentsTabSelectionState(
        assignmentFilterByClassSubjectId:
            state.assignmentFilterByClassSubjectId,
        assignmentFilterTabTitle: assignmentFilterTabTitle,
      ),
    );
  }

  void changeAssignmentFilterBySubjectId(int assignmentFilterByClassSubjectId) {
    emit(
      AssignmentsTabSelectionState(
        assignmentFilterByClassSubjectId: assignmentFilterByClassSubjectId,
        assignmentFilterTabTitle: state.assignmentFilterTabTitle,
      ),
    );
  }

  int isAssignmentSubmitted() {
    return state.assignmentFilterTabTitle == assignedKey ? 0 : 1;
  }
}
