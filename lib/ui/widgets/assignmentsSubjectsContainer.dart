import 'package:eschool/cubits/academic/assignmentsCubit.dart';
import 'package:eschool/cubits/exam/examsOnlineCubit.dart';
import 'package:eschool/cubits/exam/resultsCubit.dart';
import 'package:eschool/data/models/academics/subject.dart';
import 'package:eschool/utils/labelKeys.dart';
import 'package:eschool/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

//It must be child of AssignmentsCibit
class AssignmentsSubjectContainer extends StatefulWidget {
  final List<Subject> subjects;
  final Function(int) onTapSubject;
  final int selectedClassSubjectId;
  final String cubitAndState;

  const AssignmentsSubjectContainer({
    Key? key,
    required this.subjects,
    required this.onTapSubject,
    required this.selectedClassSubjectId,
    required this.cubitAndState,
  }) : super(key: key);

  @override
  State<AssignmentsSubjectContainer> createState() =>
      _AssignmentsSubjectContainerState();
}

class _AssignmentsSubjectContainerState
    extends State<AssignmentsSubjectContainer> {
  late final ScrollController _scrollController = ScrollController();

  // NEW: anggap “tidak ada subject” = list kosong ATAU hanya berisi item dengan classSubjectId == 0 (All)
  bool get _hasRealSubjects =>
      widget.subjects.any((s) => (s.classSubjectId ?? 0) != 0);

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // NEW: sembunyikan seluruh komponen jika tidak ada subject “nyata”
    if (!_hasRealSubjects) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: MediaQuery.of(context).size.width * 0.05,
      ),
      child: Container(
        height: 45,
        decoration: BoxDecoration(
          color: const Color(0xFFEEEEEE), // Light gray background
          borderRadius: BorderRadius.circular(12.0),
        ),
        child: ListView.builder(
          controller: _scrollController,
          itemBuilder: (context, index) {
            final bool isSelected = widget.selectedClassSubjectId ==
                widget.subjects[index].classSubjectId;

            return GestureDetector(
              onTap: () {
                if (widget.cubitAndState == "onlineExam") {
                  if (context.read<ExamsOnlineCubit>().state
                      is ExamsOnlineFetchInProgress) {
                    return;
                  }
                } else if (widget.cubitAndState == "onlineResult") {
                  if (context.read<ResultsCubit>().state
                      is ResultsFetchInProgress) {
                    return;
                  }
                } else {
                  if (context.read<AssignmentsCubit>().state
                      is AssignmentsFetchInProgress) {
                    return;
                  }
                }

                if (isSelected) {
                  return;
                }

                final subjectIdIndex = widget.subjects.indexWhere(
                  (element) =>
                      widget.subjects[index].classSubjectId ==
                      element.classSubjectId,
                );

                final selectedSubjectIdIndex = widget.subjects.indexWhere(
                  (element) =>
                      widget.selectedClassSubjectId == element.classSubjectId,
                );

                _scrollController.animateTo(
                  _scrollController.offset +
                      (subjectIdIndex > selectedSubjectIdIndex ? 1 : -1) *
                          MediaQuery.of(context).size.width *
                          (0.2),
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                );

                widget.onTapSubject(widget.subjects[index].classSubjectId ?? 0);
              },
              child: Container(
                margin: const EdgeInsets.symmetric(
                  horizontal: 4.0,
                  vertical: 5.0,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Theme.of(context).colorScheme.primary
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(8.0),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 15),
                alignment: Alignment.center,
                child: Text(
                  widget.subjects[index].classSubjectId == 0
                      ? Utils.getTranslatedLabel(allSubjectsKey)
                      : widget.subjects[index].getSubjectName(context: context),
                  style: TextStyle(
                    color: isSelected
                        ? Colors.white
                        : Theme.of(context).colorScheme.onSurface,
                    fontWeight:
                        isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
            );
          },
          itemCount: widget.subjects.length,
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
        ),
      ),
    );
  }
}
