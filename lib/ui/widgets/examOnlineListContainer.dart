import 'package:eschool/app/routes.dart';
import 'package:eschool/cubits/auth/authCubit.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:eschool/cubits/exam/examTabSelectionCubit.dart';
import 'package:eschool/cubits/exam/examsOnlineCubit.dart';
import 'package:eschool/cubits/academic/studentSubjectAndSlidersCubit.dart';
import 'package:eschool/data/models/exam/examOnline.dart';
import 'package:eschool/data/models/academic/subject.dart';
import 'package:eschool/ui/widgets/assignmentsSubjectsContainer.dart';
import 'package:eschool/ui/widgets/customRefreshIndicator.dart';
import 'package:eschool/ui/widgets/customShimmerContainer.dart';
import 'package:eschool/ui/widgets/errorContainer.dart';
import 'package:eschool/ui/widgets/examOnlineKeyBottomsheetContainer.dart';
import 'package:eschool/ui/widgets/listItemForOnlineExamAndOnlineResult.dart';
import 'package:eschool/ui/widgets/noDataContainer.dart';
import 'package:eschool/ui/widgets/shimmerLoadingContainer.dart';
import 'package:eschool/utils/labelKeys.dart';
import 'package:eschool/utils/utils.dart';
import 'package:get/get.dart';

class ExamOnlineListContainer extends StatefulWidget {
  final int? childId;
  final List<Subject>? subjects;

  const ExamOnlineListContainer({Key? key, this.childId, this.subjects})
      : super(key: key);

  @override
  State<ExamOnlineListContainer> createState() =>
      _ExamOnlineListContainerState();
}

class _ExamOnlineListContainerState extends State<ExamOnlineListContainer>
    with SingleTickerProviderStateMixin {
  late ExamOnline examSelected;
  late final ScrollController _scrollController = ScrollController()
    ..addListener(_examOnlinesScrollListener);

  String _selectedFilter = 'all';
  String _selectedFilterSiswa = 'all';
  String _searchQuery = '';
  bool _isSearchFocused = false;
  final TextEditingController _searchController = TextEditingController();
  late AnimationController _animationController;

  late List<int> examDone;
  final FocusNode _searchFocusNode = FocusNode();

  void _examOnlinesScrollListener() {
    if (_scrollController.offset ==
        _scrollController.position.maxScrollExtent) {
      if (context.read<ExamsOnlineCubit>().hasMore()) {
        context.read<ExamsOnlineCubit>().getMoreExamsOnline(
              childId: widget.childId ?? 0,
              useParentApi: context.read<AuthCubit>().isParent(),
            );
      }
    }
  }

  void fetchExamsList() {
    Future.delayed(Duration.zero, () {
      print(context
          .read<ExamTabSelectionCubit>()
          .state
          .examFilterByClassSubjectId);
      context.read<ExamsOnlineCubit>().getExamsOnline(
            classSubjectId: context
                .read<ExamTabSelectionCubit>()
                .state
                .examFilterByClassSubjectId,
            childId: widget.childId ?? 0,
            useParentApi: context.read<AuthCubit>().isParent(),
          );
    });
  }

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
    _scrollController.removeListener(_examOnlinesScrollListener);
    _scrollController.dispose();
    _searchController.dispose();
    _searchFocusNode.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> navigateToExamScreen() async {
    Get.back();
    Get.toNamed(
      Routes.examOnline,
      arguments: {
        "exam": examSelected,
      },
    );
  }

  void onTapOnlineExam(ExamOnline exam) {
    showModalBottomSheet(
      isDismissible: false,
      enableDrag: false,
      isScrollControlled: true,
      elevation: 5.0,
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20.0),
          topRight: Radius.circular(20.0),
        ),
      ),
      builder: (context) {
        return ExamOnlineKeyBottomsheetContainer(
          navigateToExamScreen: navigateToExamScreen,
          exam: exam,
        );
      },
    );
  }

  Icon _getFilterIcon(String filter, bool selected) {
    Color selectedColor =
        selected ? Colors.white : Theme.of(context).colorScheme.primary;
    switch (filter) {
      case 'ongoing':
        return Icon(
          Icons.play_circle_outline_rounded,
          color: selectedColor,
          size: 20,
        );
      case 'completed':
        return Icon(
          Icons.check_circle_outline_rounded,
          color: selectedColor,
          size: 20,
        );
      case 'upcoming':
        return Icon(
          Icons.upcoming_rounded,
          color: selectedColor,
          size: 20,
        );
      case 'process':
        return Icon(
          Icons.hourglass_bottom,
          color: selectedColor,
          size: 20,
        );
      case 'not_Yet':
        return Icon(
          Icons.cancel,
          color: selectedColor,
          size: 20,
        );
      case 'all':
      default:
        return Icon(
          Icons.all_inclusive_rounded,
          color: selectedColor,
          size: 20,
        );
    }
  }

  void _showFilterBottomSheet(BuildContext context) {
    showModalBottomSheet(
      isScrollControlled: true,
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        String tempSelectedFilter = _selectedFilter;
        String tempSelectedFilterSiswa = _selectedFilterSiswa;
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: EdgeInsets.symmetric(
                horizontal: MediaQuery.of(context).size.width * 0.06,
                vertical: MediaQuery.of(context).size.height * 0.05,
              ),
              width: MediaQuery.of(context).size.width,
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(Utils.bottomSheetTopRadius),
                  topRight: Radius.circular(Utils.bottomSheetTopRadius),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.filter_list_alt,
                        size: 20,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        Utils.getTranslatedLabel(filterUjianKey),
                        style: TextStyle(
                          fontSize: 16.0,
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10.0),
                    child: Divider(
                      color: Theme.of(context)
                          .colorScheme
                          .primary
                          .withValues(alpha: 0.4),
                    ),
                  ),
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    childAspectRatio: 3.5,
                    crossAxisSpacing: 5,
                    mainAxisSpacing: 5,
                    children: [
                      _buildFilterOptionTile(
                        title: Utils.getTranslatedLabel(allKey),
                        filterValue: 'all',
                        isSelected: tempSelectedFilter == 'all',
                        onTap: () {
                          setModalState(() {
                            tempSelectedFilter = 'all';
                          });
                        },
                      ),
                      _buildFilterOptionTile(
                        title: Utils.getTranslatedLabel(onGoingKey),
                        filterValue: 'ongoing',
                        isSelected: tempSelectedFilter == 'ongoing',
                        onTap: () {
                          setModalState(() {
                            tempSelectedFilter = 'ongoing';
                          });
                        },
                      ),
                      _buildFilterOptionTile(
                        title: Utils.getTranslatedLabel(completedKey),
                        filterValue: 'completed',
                        isSelected: tempSelectedFilter == 'completed',
                        onTap: () {
                          setModalState(() {
                            tempSelectedFilter = 'completed';
                          });
                        },
                      ),
                      _buildFilterOptionTile(
                        title: Utils.getTranslatedLabel(commingSoonKey),
                        filterValue: 'upcoming',
                        isSelected: tempSelectedFilter == 'upcoming',
                        onTap: () {
                          setModalState(() {
                            tempSelectedFilter = 'upcoming';
                          });
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Icon(
                        Icons.filter_list_alt,
                        size: 20,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        Utils.getTranslatedLabel(filterUjianSiswaKey),
                        style: TextStyle(
                          fontSize: 16.0,
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10.0),
                    child: Divider(
                      color: Theme.of(context)
                          .colorScheme
                          .primary
                          .withValues(alpha: 0.4),
                    ),
                  ),
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    childAspectRatio: 3.5,
                    crossAxisSpacing: 3,
                    mainAxisSpacing: 5,
                    children: [
                      _buildFilterOptionTileSiswa(
                        title: Utils.getTranslatedLabel(allKey),
                        filterValue: 'all',
                        isSelected: tempSelectedFilterSiswa == 'all',
                        onTap: () {
                          setModalState(() {
                            tempSelectedFilterSiswa = 'all';
                          });
                        },
                      ),
                      _buildFilterOptionTileSiswa(
                        title: Utils.getTranslatedLabel(processExamKey),
                        filterValue: 'process',
                        isSelected: tempSelectedFilterSiswa == 'process',
                        onTap: () {
                          setModalState(() {
                            tempSelectedFilterSiswa = 'process';
                          });
                        },
                      ),
                      _buildFilterOptionTileSiswa(
                        title: Utils.getTranslatedLabel(doneExamKey),
                        filterValue: 'completed',
                        isSelected: tempSelectedFilterSiswa == 'completed',
                        onTap: () {
                          setModalState(() {
                            tempSelectedFilterSiswa = 'completed';
                          });
                        },
                      ),
                      _buildFilterOptionTileSiswa(
                        title: Utils.getTranslatedLabel(notYetExamDoneKey),
                        filterValue: 'not_Yet',
                        isSelected: tempSelectedFilterSiswa == 'not_Yet',
                        onTap: () {
                          setModalState(() {
                            tempSelectedFilterSiswa = 'not_Yet';
                          });
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            setState(() {
                              _selectedFilter = tempSelectedFilter;
                              _selectedFilterSiswa = tempSelectedFilterSiswa;
                            });
                            Navigator.pop(context); // Tutup modal
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                Theme.of(context).colorScheme.primary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            elevation: 2,
                          ),
                          child: const Text(
                            'Terapkan',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // Future<List<int>> getCompletedExamIds() async {
  //   final prefs = await SharedPreferences.getInstance();
  //   final ids = prefs.getStringList('completed_exam_ids') ?? [];
  //   return ids
  //       .map((e) => int.tryParse(e) ?? -1)
  //       .where((id) => id != -1)
  //       .toList();
  // }

  Widget _buildFilterOptionTile({
    required String title,
    required String filterValue,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(left: 5),
      height: 40,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color:
            isSelected ? Theme.of(context).colorScheme.primary : Colors.white,
        border: Border.all(
          color: isSelected
              ? Colors.red
              : Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color:
                Theme.of(context).colorScheme.primary.withValues(alpha: 0.08),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _getFilterIcon(filterValue, isSelected),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: title.trim().split(" ").length > 1 ? 12 : 14,
                    fontWeight: FontWeight.w500,
                    color: isSelected
                        ? Colors.white
                        : Theme.of(context).colorScheme.secondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFilterOptionTileSiswa({
    required String title,
    required String filterValue,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(left: 5),
      height: 40,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color:
            isSelected ? Theme.of(context).colorScheme.primary : Colors.white,
        border: Border.all(
          color: isSelected
              ? Colors.red
              : Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color:
                Theme.of(context).colorScheme.primary.withValues(alpha: 0.08),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onTap, // ✅ ganti jadi parameter
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _getFilterIcon(filterValue, isSelected),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: title.trim().split(" ").length > 1 ? 11 : 13,
                    fontWeight: FontWeight.w500,
                    color: isSelected
                        ? Colors.white
                        : Theme.of(context).colorScheme.secondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildExamOnlineList(ExamsOnlineFetchSuccess state) {
    final List<ExamOnline> examList = state.examList;

    // ini sudah saya perbaiki
    // perlu tambahan untuk pagination
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
                    (exam.title?.toLowerCase().contains(_searchQuery) ==
                        true) ||
                    (exam.subjectName?.toLowerCase().contains(_searchQuery) ==
                        true);
                return matchesSearch;
              }).toList();

              // Sort exams: first by isExamStarted (true first), then by start date
              final sortedExams = [...searchFilteredExams];
              sortedExams.sort((a, b) {
                // First compare by isExamStarted (true comes first)
                if (a.isExamStarted && !b.isExamStarted) return -1;
                if (!a.isExamStarted && b.isExamStarted) return 1;

                // Then sort by start date in descending order (newest first)
                final aDate = a.startDate != null
                    ? DateTime.parse(a.startDate!)
                    : DateTime(0);
                final bDate = b.startDate != null
                    ? DateTime.parse(b.startDate!)
                    : DateTime(0);
                return bDate.compareTo(
                    aDate); // Reversed comparison for descending order
              });

              // Filter exams based on selected filter
              final filteredExams = sortedExams.where((exam) {
                final now = DateTime.now();
                final startDate = exam.startDate != null
                    ? DateTime.parse(exam.startDate!)
                    : null;
                final endDate =
                    exam.endDate != null ? DateTime.parse(exam.endDate!) : null;

                final filterByStatus = () {
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
                };

                final filterByStudentStatus = () {
                  switch (_selectedFilterSiswa) {
                    case 'process':
                      return exam.status == 1;
                    case 'completed':
                      return exam.status == 2;
                    case 'not_Yet':
                      return exam.status == 0;
                    case 'all':
                    default:
                      return true;
                  }
                };

                // Untuk parent, hanya gunakan filter waktu ujian
                // Untuk siswa, gunakan kedua filter
                if (context.read<AuthCubit>().isParent()) {
                  return filterByStatus();
                } else {
                  return filterByStatus() && filterByStudentStatus();
                }
              }).toList();

              // Show a message if no exams match the filter
              if (filteredExams.isEmpty) {
                return [
                  NoDataContainer(
                      titleKey: Utils.getTranslatedLabel(noExamsFoundKey)),
                ];
              }

              // Generate list items for filtered exams
              return List.generate(
                filteredExams.length,
                (index) {
                  //
                  return ListItemForOnlineExamAndOnlineResult(
                    isExamStarted: filteredExams[index].isExamStarted,
                    statusUjian: filteredExams[index].status!,
                    examStartingDate:
                        filteredExams[index].startDate ?? "", // String asli
                    examEndingDate:
                        filteredExams[index].endDate ?? "", // String asli
                    examName: filteredExams[index].title ?? "",
                    subjectName: filteredExams[index].subjectName ?? "-",
                    totalMarks: filteredExams[index].totalMarks ?? "",
                    isSubjectSelected: context
                            .read<ExamTabSelectionCubit>()
                            .state
                            .examFilterByClassSubjectId !=
                        0,
                    marks: '',
                    onItemTap: () {
                      if (context.read<AuthCubit>().isParent()) {
                        // Parent dapat melihat hasil ujian yang sudah selesai
                        if (filteredExams[index].status == 2) {
                          // Status 2 = Ujian sudah selesai dikerjakan
                          Navigator.of(context).pushNamed(
                            Routes.resultOnline,
                            arguments: {
                              'examId': filteredExams[index].id,
                              'examName': filteredExams[index].title,
                              'subjectName': filteredExams[index].subjectName,
                              'childId': widget.childId,
                            },
                          );
                        } else {
                          // Ujian belum selesai dikerjakan
                          Utils.showCustomSnackBar(
                            context: context,
                            errorMessage: Utils.getTranslatedLabel(
                                examNotCompletedYetKey),
                            backgroundColor:
                                Utils.getColorScheme(context).error,
                            icon: Icons.error_outline_rounded,
                          );
                        }
                      } else {
                        DateTime? startDate = filteredExams[index].startDate !=
                                null
                            ? DateTime.parse(filteredExams[index].startDate!)
                            : null;
                        DateTime? endDate = filteredExams[index].endDate != null
                            ? DateTime.parse(filteredExams[index].endDate!)
                            : null;
                        if (!(startDate?.isBefore(DateTime.now()) == true &&
                            endDate?.isAfter(DateTime.now()) == true)) {
                          Utils.showCustomSnackBar(
                            context: context,
                            errorMessage:
                                Utils.getTranslatedLabel(noExamNowKey),
                            backgroundColor:
                                Utils.getColorScheme(context).error,
                          );

                          return;
                        }

                        setState(() {
                          examSelected = filteredExams[index];
                        });

                        if (DateTime.now()
                                .difference(
                                  DateTime.parse(
                                      filteredExams[index].endDate ?? ""),
                                )
                                .inDays >
                            0) {
                          Utils.showCustomSnackBar(
                            context: context,
                            errorMessage:
                                Utils.getTranslatedLabel(noExamTodayKey),
                            backgroundColor:
                                Utils.getColorScheme(context).error,
                          );
                          return;
                        }

                        if (DateTime.now().isBefore(
                          DateTime.parse(filteredExams[index].endDate ?? ""),
                        )) {
                          onTapOnlineExam(filteredExams[index]);
                        } else {
                          Utils.showCustomSnackBar(
                            context: context,
                            errorMessage:
                                Utils.getTranslatedLabel(noExamNowKey),
                            backgroundColor:
                                Utils.getColorScheme(context).error,
                          );
                          return;
                        }
                      }
                    },
                  );
                },
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

  Widget buildMySubjectsListContainer() {
    return BlocBuilder<StudentSubjectsAndSlidersCubit,
        StudentSubjectsAndSlidersState>(
      builder: (context, state) {
        return BlocBuilder<ExamTabSelectionCubit, ExamTabSelectionState>(
          bloc: context.read<ExamTabSelectionCubit>(),
          builder: (context, state) {
            return AssignmentsSubjectContainer(
              cubitAndState: "onlineExam",
              subjects: (widget.subjects != null)
                  ? widget.subjects!
                  : context
                      .read<StudentSubjectsAndSlidersCubit>()
                      .getSubjectsForAssignmentContainer(),
              onTapSubject: (classSubjectId) {
                context
                    .read<ExamTabSelectionCubit>()
                    .changeExamFilterBySubjectId(classSubjectId);
                fetchExamsList();
              },
              selectedClassSubjectId: state.examFilterByClassSubjectId,
            );
          },
        );
      },
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
        if (kDebugMode) {
          print("refresh - fetch exams list");
        }
        fetchExamsList();
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        controller: _scrollController,
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
            buildMySubjectsListContainer(),
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
                  Container(
                    margin: const EdgeInsets.only(left: 5),
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
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(8),
                        onTap: () {
                          _showFilterBottomSheet(context);
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12.0),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.filter_list_rounded,
                                color: Theme.of(context).colorScheme.primary,
                                size: 20,
                              ),
                              // Text(
                              //   _getFilterText(_selectedFilter),
                              //   style: TextStyle(
                              //     fontSize: 14,
                              //     fontWeight: FontWeight.w500,
                              //     color:
                              //         Theme.of(context).colorScheme.secondary,
                              //   ),
                              // ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            BlocBuilder<ExamsOnlineCubit, ExamsOnlineState>(
              builder: (context, state) {
                if (state is ExamsOnlineFetchSuccess) {
                  print("ExamsOnlineFetchSuccess" + state.totalPage.toString());
                  return Align(
                    alignment: Alignment.topCenter,
                    child: state.examList.isEmpty
                        ? const NoDataContainer(titleKey: noExamsFoundKey)
                        : _buildExamOnlineList(state),
                  );
                }
                if (state is ExamsOnlineFetchFailure) {
                  return ErrorContainer(
                    errorMessageCode: state.errorMessage,
                    onTapRetry: () {
                      if (kDebugMode) {
                        print("Retry - fetch exams list");
                      }
                      fetchExamsList();
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
