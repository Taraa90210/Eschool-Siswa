import 'package:eschool/cubits/academic/assignmentsCubit.dart';
import 'package:eschool/cubits/auth/authCubit.dart';
import 'package:eschool/cubits/academic/studentSubjectAndSlidersCubit.dart';

import 'package:eschool/data/models/academics/subject.dart';
import 'package:eschool/ui/screens/home/cubits/assignmentsTabSelectionCubit.dart';
import 'package:eschool/ui/widgets/assignmentFilterBottomsheetContainer.dart';
import 'package:eschool/ui/widgets/assignmentListContainer.dart';
import 'package:eschool/ui/widgets/assignmentsSubjectsContainer.dart';
import 'package:eschool/ui/widgets/customRefreshIndicator.dart';
import 'package:eschool/ui/widgets/svgButton.dart';
import 'package:eschool/ui/widgets/screenTopBackgroundContainer.dart';
import 'package:eschool/utils/labelKeys.dart';
import 'package:eschool/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

enum AssignmentFilters {
  assignedDateLatest,
  assignedDateOldest,
  dueDateLatest,
  dueDateOldest
}

class AssignmentsContainer extends StatefulWidget {
  final bool isForBottomMenuBackground;
  const AssignmentsContainer({
    Key? key,
    required this.isForBottomMenuBackground,
  }) : super(key: key);

  @override
  State<AssignmentsContainer> createState() => _AssignmentsContainerState();
}

class _AssignmentsContainerState extends State<AssignmentsContainer> {
  late AssignmentFilters selectedAssignmentFilter =
      AssignmentFilters.assignedDateLatest;

  late final ScrollController _scrollController = ScrollController()
    ..addListener(_assignmentsScrollListener);

  void _assignmentsScrollListener() {
    if (_scrollController.offset ==
        _scrollController.position.maxScrollExtent) {
      if (context.read<AssignmentsCubit>().hasMore()) {
        context.read<AssignmentsCubit>().fetchMoreAssignments(
              childId: 0,
              isSubmitted: context
                  .read<AssignmentsTabSelectionCubit>()
                  .isAssignmentSubmitted(),
              useParentApi: context.read<AuthCubit>().isParent(),
            );
        Future.delayed(const Duration(milliseconds: 10), () {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeIn,
          );
        });
      }
    }
  }

  @override
  void initState() {
    Future.delayed(Duration.zero, () {
      if (!widget.isForBottomMenuBackground) {
        fetchAssignments();
      }
    });
    super.initState();
  }

  @override
  void dispose() {
    _scrollController.removeListener(_assignmentsScrollListener);
    _scrollController.dispose();
    super.dispose();
  }

  void fetchAssignments() {
    context.read<AssignmentsCubit>().fetchAssignments(
          childId: 0,
          isSubmitted: context
              .read<AssignmentsTabSelectionCubit>()
              .isAssignmentSubmitted(),
          classSubjectId: context
              .read<AssignmentsTabSelectionCubit>()
              .state
              .assignmentFilterByClassSubjectId,
          useParentApi: context.read<AuthCubit>().isParent(),
        );
  }

  void changeAssignmentFilter(AssignmentFilters assignmentFilter) {
    setState(() {
      selectedAssignmentFilter = assignmentFilter;
    });
  }

  void onTapFilterButton() {
    showModalBottomSheet(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(Utils.bottomSheetTopRadius),
          topRight: Radius.circular(Utils.bottomSheetTopRadius),
        ),
      ),
      context: context,
      builder: (_) => AssignmentFilterBottomsheetContainer(
        changeAssignmentFilter: changeAssignmentFilter,
        initialAssignmentFilterValue: selectedAssignmentFilter,
      ),
    );
  }

  Widget _buildMySubjectsListContainer() {
    return BlocBuilder<StudentSubjectsAndSlidersCubit,
        StudentSubjectsAndSlidersState>(
      builder: (context, state) {
        List<Subject> subjects = context
            .read<StudentSubjectsAndSlidersCubit>()
            .getSubjectsForAssignmentContainer();

        return BlocBuilder<AssignmentsTabSelectionCubit,
            AssignmentsTabSelectionState>(
          bloc: context.read<AssignmentsTabSelectionCubit>(),
          builder: (context, state) {
            return AssignmentsSubjectContainer(
              cubitAndState: "assignment",
              subjects: subjects,
              onTapSubject: (int classSubjectId) {
                context
                    .read<AssignmentsTabSelectionCubit>()
                    .changeAssignmentFilterBySubjectId(classSubjectId);
                fetchAssignments();
              },
              selectedClassSubjectId: state.assignmentFilterByClassSubjectId,
            );
          },
        );
      },
    );
  }

  Widget _buildAppBarContainer() {
    return ScreenTopBackgroundContainer(
      heightPercentage: Utils.appBarBiggerHeightPercentage -
          (Utils.appBarBiggerHeightPercentage * 0.1),
      child: LayoutBuilder(
        builder: (context, boxConstraints) {
          return Stack(
            children: [
              BlocBuilder<AssignmentsTabSelectionCubit,
                  AssignmentsTabSelectionState>(
                builder: (context, state) {
                  return state.assignmentFilterTabTitle == submittedKey
                      ? const SizedBox()
                      : Align(
                          alignment: AlignmentDirectional.topEnd,
                          child: Padding(
                            padding: EdgeInsetsDirectional.only(
                              end: Utils.screenContentHorizontalPadding,
                            ),
                            child: SvgButton(
                              onTap: () {
                                onTapFilterButton();
                              },
                              svgIconUrl: Utils.getImagePath("filter_icon.svg"),
                            ),
                          ),
                        );
                },
              ),
              Align(
                alignment: Alignment.topCenter,
                child: Container(
                  alignment: Alignment.topCenter,
                  width: boxConstraints.maxWidth * (0.5),
                  child: Text(
                    Utils.getTranslatedLabel(assignmentsKey),
                    style: TextStyle(
                      color: Theme.of(context).scaffoldBackgroundColor,
                      fontSize: Utils.screenTitleFontSize,
                    ),
                  ),
                ),
              ),
              Align(
                alignment:
                    Alignment(0.0, 0.3), // Moved down to reduce empty space
                child: Container(
                  width: boxConstraints.maxWidth * (0.7),
                  height: 45,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEEEEEE).withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: BlocBuilder<AssignmentsTabSelectionCubit,
                            AssignmentsTabSelectionState>(
                          bloc: context.read<AssignmentsTabSelectionCubit>(),
                          builder: (context, state) {
                            final bool isSelected =
                                state.assignmentFilterTabTitle == assignedKey;
                            return GestureDetector(
                              onTap: () {
                                context
                                    .read<AssignmentsTabSelectionCubit>()
                                    .changeAssignmentFilterTabTitle(
                                        assignedKey);
                                fetchAssignments();
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
                                alignment: Alignment.center,
                                child: Text(
                                  Utils.getTranslatedLabel(assignedKey),
                                  style: TextStyle(
                                    color: isSelected
                                        ? Colors.white
                                        : Theme.of(context)
                                            .scaffoldBackgroundColor,
                                    fontWeight: isSelected
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      Expanded(
                        child: BlocBuilder<AssignmentsTabSelectionCubit,
                            AssignmentsTabSelectionState>(
                          bloc: context.read<AssignmentsTabSelectionCubit>(),
                          builder: (context, state) {
                            final bool isSelected =
                                state.assignmentFilterTabTitle == submittedKey;
                            return GestureDetector(
                              onTap: () {
                                context
                                    .read<AssignmentsTabSelectionCubit>()
                                    .changeAssignmentFilterTabTitle(
                                        submittedKey);
                                fetchAssignments();
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
                                alignment: Alignment.center,
                                child: Text(
                                  Utils.getTranslatedLabel(submittedKey),
                                  style: TextStyle(
                                    color: isSelected
                                        ? Colors.white
                                        : Theme.of(context)
                                            .scaffoldBackgroundColor,
                                    fontWeight: isSelected
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        CustomRefreshIndicator(
          displacment: Utils.getScrollViewTopPadding(
            context: context,
            appBarHeightPercentage: Utils.appBarBiggerHeightPercentage -
                (Utils.appBarBiggerHeightPercentage * 0.1),
          ),
          onRefreshCallback: () {
            fetchAssignments();
          },
          child: SizedBox(
            height: double.maxFinite,
            child: SingleChildScrollView(
              controller: _scrollController,
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.only(
                top: Utils.getScrollViewTopPadding(
                  context: context,
                  appBarHeightPercentage: Utils.appBarBiggerHeightPercentage -
                      (Utils.appBarBiggerHeightPercentage * 0.1),
                ),
                bottom: Utils.getScrollViewBottomPadding(context),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildMySubjectsListContainer(),
                  SizedBox(
                    height: MediaQuery.of(context).size.height * (0.035),
                  ),
                  BlocBuilder<AssignmentsTabSelectionCubit,
                      AssignmentsTabSelectionState>(
                    builder: (context, state) {
                      return AssignmentListContainer(
                        animateItems: !widget.isForBottomMenuBackground,
                        assignmentTabTitle: state.assignmentFilterTabTitle,
                        currentSelectedSubjectId:
                            state.assignmentFilterByClassSubjectId,
                        selectedAssignmentFilter: selectedAssignmentFilter,
                        isAssignmentSubmitted: context
                            .read<AssignmentsTabSelectionCubit>()
                            .isAssignmentSubmitted(),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
        Align(
          alignment: Alignment.topCenter,
          child: _buildAppBarContainer(),
        )
      ],
    );
  }
}
