import 'package:flutter/foundation.dart';
import 'package:eschool/data/models/leave.dart';
import 'package:eschool/data/repositories/leavesRepository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

abstract class LeavesState extends Equatable {}

class LeavesInitial extends LeavesState {
  @override
  List<Object?> get props => [];
}

class LeavesFetchInProgress extends LeavesState {
  @override
  List<Object?> get props => [];
}

class LeavesFetchSuccess extends LeavesState {
  final List<Leave> leaves;

  LeavesFetchSuccess({required this.leaves});
  
  @override
  List<Object?> get props => [leaves];
}

class LeavesFetchFailure extends LeavesState {
  final String errorMessage;

  LeavesFetchFailure(this.errorMessage);

  @override
  List<Object?> get props => [errorMessage];
}

class LeavesCubit extends Cubit<LeavesState> {
  final LeavesRepository _leavesRepository;

  LeavesCubit(this._leavesRepository) : super(LeavesInitial());

  void fetchLeaves({required int childId}) {
    debugPrint("Fetching leaves for childId: $childId");
    emit(LeavesFetchInProgress());

    _leavesRepository
        .fetchChildLeaves(childId: childId)
        .then((value) {
          debugPrint("Fetch successful, leaves: $value");
          emit(LeavesFetchSuccess(leaves: value));
        })
        .catchError((e) {
          debugPrint("Fetch failed, error: ${e.toString()}");
          emit(LeavesFetchFailure(e.toString()));
        });
  }

  void refreshLeaves({required int childId}) {
    debugPrint("Refreshing leaves for childId: $childId");
    fetchLeaves(childId: childId);
  }
}

