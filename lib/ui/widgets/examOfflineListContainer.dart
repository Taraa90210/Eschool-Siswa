import 'package:eschool/app/routes.dart';
import 'package:eschool/cubits/auth/authCubit.dart';
import 'package:eschool/cubits/exam/examDetailsCubit.dart';
import 'package:eschool/data/models/exam/exam.dart';
import 'package:eschool/ui/widgets/customRefreshIndicator.dart';
import 'package:eschool/ui/widgets/customShimmerContainer.dart';
import 'package:eschool/ui/widgets/errorContainer.dart';
import 'package:eschool/ui/widgets/examsFilterContainer.dart';
import 'package:eschool/ui/widgets/listItemForExamAndResult.dart';
import 'package:eschool/ui/widgets/noDataContainer.dart';
import 'package:eschool/ui/widgets/shimmerLoadingContainer.dart';
import 'package:eschool/utils/constants.dart';
import 'package:eschool/utils/labelKeys.dart';
import 'package:eschool/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';

class ExamOfflineListContainer extends StatefulWidget {
  final int? childId;

  const ExamOfflineListContainer({Key? key, this.childId}) : super(key: key);

  @override
  State<ExamOfflineListContainer> createState() =>
      _ExamOfflineListContainerState();
}

class _ExamOfflineListContainerState extends State<ExamOfflineListContainer>
    with SingleTickerProviderStateMixin {
  String _currentlySelectedExamFilter = allExamsKey;
  String _selectedFilter = 'all';
  String _searchQuery = '';
  bool _isSearchFocused = false;
  final TextEditingController _searchController = TextEditingController();
  late AnimationController _animationController;
  final FocusNode _searchFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    fetchExamsList();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _searchFocusNode.addListener(() {
      setState(() {
        _isSearchFocused = _searchFocusNode.hasFocus;
      });
      if (_isSearchFocused) {
        _animationController.forward();
      } else if (!_isSearchFocused && _searchController.text.isEmpty) {
        _animationController.reverse();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void fetchExamsList() {
    Future.delayed(Duration.zero, () {
      context.read<ExamDetailsCubit>().fetchStudentExamsList(
            useParentApi: context.read<AuthCubit>().isParent(),
            childId: widget.childId,
            examStatus: getExamStatusBasedOnFilterKey(
                examFilter: _currentlySelectedExamFilter),
          );
    });
  }

  Widget _buildExamList(List<Exam> examList) {
    void printExamListStructure() {
      for (var i = 0; i < examList.length; i++) {
        print('Exam[$i]: {');
        print("examID: ${examList[i].examID ?? ""}");
        print("examName: ${examList[i].examName ?? ""}");
        print("description: ${examList[i].description ?? ""}");
        print("publish: ${examList[i].publish ?? 0}");
        print("sessionYear: ${examList[i].sessionYear ?? ""}");
        print("examStartingDate: ${examList[i].examStartingDate ?? ""}");
        print("examEndingDate: ${examList[i].examEndingDate ?? ""}");
        print("examStatus: ${examList[i].examStatus ?? ""}");
        print('}');
      }
    }

    printExamListStructure();

    return SingleChildScrollView(
      child: Align(
        alignment: Alignment.topCenter,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ...() {
              // First filter by search text
              var searchFilteredExams = examList.where((exam) {
                final matchesSearch = _searchQuery.isEmpty ||
                    (exam.examName?.toLowerCase().contains(_searchQuery) ==
                        true) ||
                    (exam.description?.toLowerCase().contains(_searchQuery) ==
                        true);
                return matchesSearch;
              }).toList();

              // Then apply status filters
              final filteredExams = searchFilteredExams.where((exam) {
                final now = DateTime.now();
                DateTime? startDate;
                DateTime? endDate;

                try {
                  startDate = exam.examStartingDate != null &&
                          exam.examStartingDate!.isNotEmpty
                      ? DateTime.parse(exam.examStartingDate!)
                      : null;
                  endDate = exam.examEndingDate != null &&
                          exam.examEndingDate!.isNotEmpty
                      ? DateTime.parse(exam.examEndingDate!)
                      : null;
                } catch (e) {
                  print("Date parsing error: $e");
                }

                switch (_selectedFilter) {
                  case 'ongoing':
                    return startDate != null &&
                        endDate != null &&
                        now.isAfter(startDate) &&
                        now.isBefore(endDate);
                  case 'completed':
                    return endDate != null && now.isAfter(endDate);
                  case 'upcoming':
                    return startDate != null && now.isBefore(startDate);
                  case 'all':
                  default:
                    return true;
                }
              }).toList();

              if (filteredExams.isEmpty) {
                String message = _searchQuery.isNotEmpty
                    ? Utils.getTranslatedLabel(noExamsFoundKey)
                    : Utils.getTranslatedLabel(noExamsFoundKey);

                return [
                  NoDataContainer(
                    titleKey: message,
                  ),
                ];
              }

              return List.generate(
                filteredExams.length,
                (index) => ListItemForExamAndResult(
                  index: index,
                  examStartingDate: filteredExams[index].examStartingDate!,
                  examName: filteredExams[index].examName!,
                  examDescription: filteredExams[index].description!,
                  resultPercentage: 0,
                  examStatus:
                      int.tryParse(filteredExams[index].examStatus!) ?? 0,
                  resultGrade: '',
                  onItemTap: () {
                    if (filteredExams[index].examStartingDate! == '') {
                      Utils.showCustomSnackBar(
                        context: context,
                        errorMessage: Utils.getTranslatedLabel(
                          noExamTimeTableFoundKey,
                        ),
                        backgroundColor: Utils.getColorScheme(context).error,
                      );
                      return;
                    }
                    Get.toNamed(
                      Routes.examTimeTable,
                      arguments: {
                        'examID': filteredExams[index].examID,
                        'examName': filteredExams[index].examName.toString(),
                        'childID': widget.childId
                      },
                    );
                  },
                ),
              );
            }(),
          ],
        ),
      ),
    );
  }

  Widget _buildExamShimmerLoadingContainer() {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      width: MediaQuery.of(context).size.width,
      padding: EdgeInsets.symmetric(
        horizontal: Utils.screenContentHorizontalPaddingInPercentage *
            MediaQuery.of(context).size.width,
      ),
      child: ShimmerLoadingContainer(
        child: LayoutBuilder(
          builder: (context, boxConstraints) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  height: MediaQuery.of(context).size.height * (0.035),
                ),
                ShimmerLoadingContainer(
                  child: CustomShimmerContainer(
                    height: 9,
                    width: boxConstraints.maxWidth * (0.3),
                  ),
                ),
                SizedBox(
                  height: boxConstraints.maxWidth * (0.02),
                ),
                ShimmerLoadingContainer(
                  child: CustomShimmerContainer(
                    height: 10,
                    width: boxConstraints.maxWidth * (0.8),
                  ),
                ),
                SizedBox(
                  height: boxConstraints.maxWidth * (0.1),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildExamLoading() {
    return Align(
      alignment: Alignment.topCenter,
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: List.generate(
              Utils.defaultShimmerLoadingContentCount,
              (index) => _buildExamShimmerLoadingContainer(),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CustomRefreshIndicator(
      displacment: Utils.getScrollViewTopPadding(
        context: context,
        appBarHeightPercentage: Utils.appBarBiggerHeightPercentage -
            (Utils.appBarBiggerHeightPercentage * 0.1),
      ),
      onRefreshCallback: () {
        context.read<ExamDetailsCubit>().fetchStudentExamsList(
              examStatus: getExamStatusBasedOnFilterKey(
                  examFilter: _currentlySelectedExamFilter),
              useParentApi: context.read<AuthCubit>().isParent(),
              childId: widget.childId,
            );
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.only(
          bottom: Utils.getScrollViewBottomPadding(context),
          top: Utils.getScrollViewTopPadding(
            context: context,
            appBarHeightPercentage: Utils.appBarBiggerHeightPercentage -
                (Utils.appBarBiggerHeightPercentage * 0.1),
          ),
        ),
        child: Column(
          children: [
            ExamFiltersContainer(
              onTapSubject: (examFilterIndex) {
                _currentlySelectedExamFilter = examFilters[examFilterIndex];
                context.read<ExamDetailsCubit>().fetchStudentExamsList(
                      useParentApi: context.read<AuthCubit>().isParent(),
                      childId: widget.childId,
                      examStatus: getExamStatusBasedOnFilterKey(
                          examFilter: _currentlySelectedExamFilter),
                    );

                setState(() {});
              },
              selectedExamFilterIndex:
                  examFilters.indexOf(_currentlySelectedExamFilter),
            ),
            Padding(
              padding: const EdgeInsets.only(
                  left: 16.0, right: 16.0, top: 16.0, bottom: 10.0),
              child: Row(
                children: [
                  // Search Bar - Takes available space dynamically
                  Expanded(
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      height: 40,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        color: Colors.white,
                        border: Border.all(
                          color: Theme.of(context)
                              .colorScheme
                              .primary
                              .withValues(alpha: 0.3),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Theme.of(context)
                                .colorScheme
                                .primary
                                .withValues(alpha: 0.08),
                            blurRadius: _isSearchFocused ? 8 : 4,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 12.0),
                            child: Icon(
                              Icons.search_rounded,
                              color: Theme.of(context).colorScheme.primary,
                              size: 20,
                            ),
                          ),
                          Expanded(
                            child: TextField(
                              controller: _searchController,
                              focusNode: _searchFocusNode,
                              onChanged: (value) {
                                setState(() {
                                  _searchQuery = value.toLowerCase();
                                });
                              },
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.primary,
                                fontSize: 14,
                              ),
                              textAlignVertical: TextAlignVertical.center,
                              decoration: InputDecoration(
                                hintText: Utils.getTranslatedLabel(searchKey),
                                hintStyle: TextStyle(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .primary
                                      .withValues(alpha: 0.7),
                                  fontSize: 14,
                                ),
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(
                                  vertical: 0,
                                  horizontal: 0,
                                ),
                                isDense: true,
                              ),
                            ),
                          ),
                          // Clear button that appears when text is entered
                          AnimatedOpacity(
                            opacity:
                                _searchController.text.isNotEmpty ? 1.0 : 0.0,
                            duration: const Duration(milliseconds: 200),
                            child: _searchController.text.isNotEmpty
                                ? GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        _searchController.clear();
                                        _searchQuery = '';
                                      });
                                    },
                                    child: Padding(
                                      padding:
                                          const EdgeInsets.only(right: 8.0),
                                      child: Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: BoxDecoration(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .primary
                                              .withValues(alpha: 0.1),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          Icons.close,
                                          color: Theme.of(context)
                                              .colorScheme
                                              .primary,
                                          size: 14,
                                        ),
                                      ),
                                    ),
                                  )
                                : const SizedBox(width: 8),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Container(
                  //   margin: const EdgeInsets.only(left: 5),
                  //   height: 40,
                  //   decoration: BoxDecoration(
                  //     borderRadius: BorderRadius.circular(8),
                  //     color: Colors.white,
                  //     border: Border.all(
                  //       color: Theme.of(context)
                  //           .colorScheme
                  //           .primary
                  //           .withOpacity(0.3),
                  //       width: 1.5,
                  //     ),
                  //     boxShadow: [
                  //       BoxShadow(
                  //         color: Theme.of(context)
                  //             .colorScheme
                  //             .primary
                  //             .withOpacity(0.08),
                  //         blurRadius: 4,
                  //         offset: const Offset(0, 2),
                  //       ),
                  //     ],
                  //   ),
                  //   child: Material(
                  //     color: Colors.transparent,
                  //     child: InkWell(
                  //       borderRadius: BorderRadius.circular(8),
                  //       onTap: () {
                  //         _showFilterBottomSheet(context);
                  //       },
                  //       child: Padding(
                  //         padding: const EdgeInsets.symmetric(horizontal: 12.0),
                  //         child: Row(
                  //           mainAxisSize: MainAxisSize.min,
                  //           children: [
                  //             _getFilterIcon(_selectedFilter),
                  //             const SizedBox(width: 8),
                  //             Text(
                  //               _getFilterText(_selectedFilter),
                  //               style: TextStyle(
                  //                 fontSize: 14,
                  //                 fontWeight: FontWeight.w500,
                  //                 color:
                  //                     Theme.of(context).colorScheme.secondary,
                  //               ),
                  //             ),
                  //             const SizedBox(width: 8),
                  //           ],
                  //         ),
                  //       ),
                  //     ),
                  //   ),
                  // ),
                ],
              ),
            ),
            BlocBuilder<ExamDetailsCubit, ExamDetailsState>(
              builder: (context, state) {
                if (state is ExamDetailsFetchSuccess) {
                  return Align(
                    alignment: Alignment.topCenter,
                    child: state.examList.isEmpty
                        ? const NoDataContainer(titleKey: noExamsFoundKey)
                        : Column(
                            children: [
                              _buildExamList(state.examList),
                            ],
                          ),
                  );
                }
                if (state is ExamDetailsFetchFailure) {
                  return ErrorContainer(
                    errorMessageCode: state.errorMessage,
                    onTapRetry: () {
                      context.read<ExamDetailsCubit>().fetchStudentExamsList(
                            useParentApi: context.read<AuthCubit>().isParent(),
                            childId: widget.childId,
                            examStatus: examFilters
                                .indexOf(_currentlySelectedExamFilter),
                          );
                    },
                  );
                }

                return _buildExamLoading();
              },
            ),
          ],
        ),
      ),
    );
  }
}
