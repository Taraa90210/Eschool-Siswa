import 'package:eschool/cubits/assignmentReportCubit.dart';
import 'package:eschool/cubits/authCubit.dart';
import 'package:eschool/cubits/onlineExamReportCubit.dart';
import 'package:eschool/ui/widgets/customCircularProgressIndicator.dart';
import 'package:eschool/ui/widgets/noDataContainer.dart';
import 'package:eschool/ui/widgets/screenTopBackgroundContainer.dart';
import 'package:eschool/utils/errorMessageKeysAndCodes.dart';
import 'package:eschool/utils/systemModules.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:eschool/cubits/reportTabSelectionCubit.dart';
import 'package:eschool/data/models/subject.dart';
import 'package:eschool/ui/widgets/customBackButton.dart';
import 'package:eschool/ui/widgets/errorContainer.dart';
import 'package:eschool/utils/labelKeys.dart';
import 'package:eschool/utils/utils.dart';
import 'package:get/get.dart';
import 'package:percent_indicator/percent_indicator.dart';

class SubjectWiseDetailedReport extends StatefulWidget {
  final Subject subject;
  final int? childId;
  const SubjectWiseDetailedReport({
    Key? key,
    required this.subject,
    this.childId,
  }) : super(key: key);

  @override
  SubjectWiseDetailedReportState createState() =>
      SubjectWiseDetailedReportState();

  static Widget routeInstance() {
    final arguments = Get.arguments as Map<String, dynamic>;
    return SubjectWiseDetailedReport(
      subject: arguments['subject'],
      childId: arguments['childId'] ?? 0,
    );
  }
}

class SubjectWiseDetailedReportState extends State<SubjectWiseDetailedReport>
    with TickerProviderStateMixin {
  late final ScrollController _reportOnlineExamController = ScrollController()
    ..addListener(_reportOnlineExamScrollListener);
  late final ScrollController _reportAssignmentController = ScrollController()
    ..addListener(_reportAssignmentScrollListener);
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    fetchReportData();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _reportOnlineExamController.removeListener(_reportOnlineExamScrollListener);
    _reportAssignmentController.removeListener(_reportAssignmentScrollListener);
    _animationController.dispose();
    super.dispose();
  }

  void fetchReportData() {
    if (isAssignmentManagementModuleEnable() &&
        isExamManagementModuleEnable()) {
      //Both module enable
      if (context.read<ReportTabSelectionCubit>().isReportAssignment()) {
        getAssignmentReport();
      } else {
        getExamOnlineReport();
      }
    } else {
      //If one module is enable among the two
      if (isAssignmentManagementModuleEnable()) {
        getAssignmentReport();
      }
      if (isExamManagementModuleEnable()) {
        getExamOnlineReport();
      }
    }
  }

  bool isAssignmentManagementModuleEnable() => Utils.isModuleEnabled(
      context: context, moduleId: assignmentManagementModuleId.toString());

  bool isExamManagementModuleEnable() => Utils.isModuleEnabled(
      context: context, moduleId: examManagementModuleId.toString());

  void getAssignmentReport() {
    context.read<AssignmentReportCubit>().getAssignmentReport(
          classSubjectId: widget.subject.classSubjectId ?? 0,
          childId: widget.childId ?? 0,
          useParentApi: context.read<AuthCubit>().isParent(),
        );
  }

  void getExamOnlineReport() {
    context.read<OnlineExamReportCubit>().getExamOnlineReport(
          classSubjectId: widget.subject.classSubjectId ?? 0,
          childId: widget.childId ?? 0,
          useParentApi: context.read<AuthCubit>().isParent(),
        );
  }

  void _reportAssignmentScrollListener() {
    if (_reportAssignmentController.offset ==
        _reportAssignmentController.position.maxScrollExtent) {
      if (context.read<AssignmentReportCubit>().hasMore()) {
        context.read<AssignmentReportCubit>().getMoreAssignmentReport(
              childId: widget.childId ?? 0,
              useParentApi: context.read<AuthCubit>().isParent(),
            );
      }
    }
  }

  void _reportOnlineExamScrollListener() {
    if (_reportOnlineExamController.offset ==
        _reportOnlineExamController.position.maxScrollExtent) {
      if (context.read<OnlineExamReportCubit>().hasMore()) {
        context.read<OnlineExamReportCubit>().getMoreExamOnlineReport(
              childId: widget.childId ?? 0,
              useParentApi: context.read<AuthCubit>().isParent(),
            );
      }
    }
  }

  Widget buildModernAppBar(ReportTabSelectionState currentState) {
    return ScreenTopBackgroundContainer(
      heightPercentage: Utils.appBarBiggerHeightPercentage -
          (Utils.appBarBiggerHeightPercentage * 0.1),
      child: LayoutBuilder(
        builder: (context, boxConstraints) {
          return Stack(
            children: [
              // Back Button
              const CustomBackButton(),

              // Screen Title
              Align(
                alignment: Alignment.topCenter,
                child: Container(
                  alignment: Alignment.topCenter,
                  width: boxConstraints.maxWidth * (0.5),
                  child: Text(
                    widget.subject.getSubjectName(context: context),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Theme.of(context).scaffoldBackgroundColor,
                      fontSize: Utils.screenTitleFontSize,
                    ),
                  ),
                ),
              ),

              // Tab Selector
              Visibility(
                visible: isAssignmentManagementModuleEnable() &&
                    isExamManagementModuleEnable(),
                child: Align(
                  alignment: Alignment(0.0, 0.3),
                  child: Container(
                    width: boxConstraints.maxWidth * (0.7),
                    height: 45,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEEEEEE).withOpacity(0.3),
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    child: Row(
                      children: [
                        // Assignment Tab
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              context
                                  .read<ReportTabSelectionCubit>()
                                  .changeReportFilterTabTitle(assignmentKey);
                              getAssignmentReport();
                            },
                            child: Container(
                              margin: const EdgeInsets.symmetric(
                                horizontal: 4.0,
                                vertical: 5.0,
                              ),
                              decoration: BoxDecoration(
                                color: currentState.reportFilterTabTitle ==
                                        assignmentKey
                                    ? Theme.of(context).colorScheme.primary
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(8.0),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                Utils.getTranslatedLabel(assignmentKey),
                                style: TextStyle(
                                  color: currentState.reportFilterTabTitle ==
                                          assignmentKey
                                      ? Colors.white
                                      : Theme.of(context)
                                          .scaffoldBackgroundColor,
                                  fontWeight:
                                      currentState.reportFilterTabTitle ==
                                              assignmentKey
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                ),
                              ),
                            ),
                          ),
                        ),

                        // Exam Tab
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              context
                                  .read<ReportTabSelectionCubit>()
                                  .changeReportFilterTabTitle(onlineExamKey);
                              getExamOnlineReport();
                            },
                            child: Container(
                              margin: const EdgeInsets.symmetric(
                                horizontal: 4.0,
                                vertical: 5.0,
                              ),
                              decoration: BoxDecoration(
                                color: currentState.reportFilterTabTitle ==
                                        onlineExamKey
                                    ? Theme.of(context).colorScheme.primary
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(8.0),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                Utils.getTranslatedLabel(onlineExamKey),
                                style: TextStyle(
                                  color: currentState.reportFilterTabTitle ==
                                          onlineExamKey
                                      ? Colors.white
                                      : Theme.of(context)
                                          .scaffoldBackgroundColor,
                                  fontWeight:
                                      currentState.reportFilterTabTitle ==
                                              onlineExamKey
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                replacement: Align(
                  alignment: Alignment(0.0, 0.3),
                  child: Container(
                    width: boxConstraints.maxWidth * (0.7),
                    height: 45,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEEEEEE).withOpacity(0.3),
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      Utils.getTranslatedLabel(
                          isAssignmentManagementModuleEnable()
                              ? assignmentKey
                              : onlineExamKey),
                      style: TextStyle(
                        color: Theme.of(context).scaffoldBackgroundColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget modernStatsCard({
    required String title,
    required String value,
    required double percentage,
    required Color progressColor,
    required String subtitle1,
    required String subtitle2,
    required String value1,
    required String value2,
    required IconData icon,
  }) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 10,
              spreadRadius: 1,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: Theme.of(context).colorScheme.secondary,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color:
                        Theme.of(context).colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            LinearPercentIndicator(
              lineHeight: 10.0,
              percent:
                  percentage.isNaN ? 0 : (percentage > 1.0 ? 1.0 : percentage),
              animation: true,
              animationDuration: 1500,
              barRadius: const Radius.circular(5),
              backgroundColor: Colors.grey.withOpacity(0.2),
              progressColor: progressColor,
              padding: EdgeInsets.zero,
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      subtitle1,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      value1,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      subtitle2,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      value2,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      Utils.getTranslatedLabel(totalKey),
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      value,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget modernPointsDetailCard({
    required String title,
    required String points,
    required String subtitle,
    required double percentage,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 5,
            spreadRadius: 1,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withOpacity(0.05),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Theme.of(context).colorScheme.primary.withOpacity(0.7),
                      Theme.of(context).colorScheme.primary.withOpacity(0.9),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  points,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Stack(
                  children: [
                    Container(
                      height: 6,
                      decoration: BoxDecoration(
                        color: Colors.grey.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    Container(
                      height: 6,
                      width: MediaQuery.of(context).size.width *
                          0.72 *
                          (percentage.isNaN || percentage.isInfinite
                              ? 0
                              : percentage > 1.0
                                  ? 1.0
                                  : percentage < 0
                                      ? 0
                                      : percentage),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Theme.of(context)
                                .colorScheme
                                .primary
                                .withOpacity(0.8),
                            Theme.of(context)
                                .colorScheme
                                .primary
                                .withOpacity(0.7),
                          ],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Text(
                "${(percentage * 100).toStringAsFixed(0)}%",
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAssignmentReport() {
    return BlocBuilder<AssignmentReportCubit, AssignmentReportState>(
      builder: (context, state) {
        if (state is AssignmentReportFetchSuccess) {
          return SingleChildScrollView(
            controller: _reportAssignmentController,
            padding: const EdgeInsets.only(top: 16, bottom: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                modernStatsCard(
                  title:
                      "${Utils.getTranslatedLabel(statisticsKey)} ${Utils.getTranslatedLabel(assignmentsKey)}",
                  value: state.assignments.toString(),
                  percentage: state.submittedAssignments! / state.assignments!,
                  progressColor: LinearGradient(
                    colors: [
                      Theme.of(context).colorScheme.primary.withOpacity(0.7),
                      Theme.of(context).colorScheme.primary.withOpacity(0.9),
                    ],
                  ).colors.first,
                  subtitle1: Utils.getTranslatedLabel(submittedKey),
                  subtitle2: Utils.getTranslatedLabel(pendingKey),
                  value1: state.submittedAssignments.toString(),
                  value2: state.unsubmittedAssignments.toString(),
                  icon: Icons.assignment_outlined,
                ),
                modernStatsCard(
                  title:
                      "${Utils.getTranslatedLabel(statisticsKey)} ${Utils.getTranslatedLabel(pointsKey)}",
                  value: state.totalPoints!,
                  percentage: int.parse(state.totalObtainedPoints!) /
                      int.parse(state.totalPoints!),
                  progressColor: LinearGradient(
                    colors: [
                      Theme.of(context).colorScheme.primary.withOpacity(0.7),
                      Theme.of(context).colorScheme.primary.withOpacity(0.9),
                    ],
                  ).colors.first,
                  subtitle1: Utils.getTranslatedLabel(obtainedKey),
                  subtitle2: Utils.getTranslatedLabel(percentageKey),
                  value1: state.totalObtainedPoints!,
                  value2: '${state.percentage}%',
                  icon: Icons.electric_bolt_outlined,
                ),
                if ((state.submittedAssignmentWithPointsData.data ?? [])
                    .isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(32, 16, 16, 16),
                    child: Text(
                      "${Utils.getTranslatedLabel(detailKey)} ${Utils.getTranslatedLabel(pointsKey)}",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.secondary,
                      ),
                    ),
                  ),
                if ((state.submittedAssignmentWithPointsData.data ?? [])
                    .isNotEmpty)
                  ...state.submittedAssignmentWithPointsData.data!.map((item) {
                    final totalPoints = item.totalPoints ?? 0;
                    final obtainedPoints = item.obtainedPoints ?? 0;

                    return modernPointsDetailCard(
                      title: Utils.getTranslatedLabel(pointsKey),
                      points: "$obtainedPoints / $totalPoints",
                      subtitle: item.assignmentName!,
                      percentage: obtainedPoints / totalPoints,
                    );
                  }).toList(),
                const SizedBox(height: 24),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context)
                          .colorScheme
                          .secondary
                          .withOpacity(0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Theme.of(context)
                            .colorScheme
                            .secondary
                            .withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: Theme.of(context).colorScheme.secondary,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            Utils.getTranslatedLabel(reportNoteKey),
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.secondary,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        }
        if (state is AssignmentReportFetchFailure) {
          return Padding(
            padding: const EdgeInsets.only(top: 16),
            child: Align(
              alignment: Alignment.topCenter,
              child: ErrorContainer(
                errorMessageCode: state.errorMessage,
                onTapRetry: getAssignmentReport,
              ),
            ),
          );
        }
        return Center(
          child: CustomCircularProgressIndicator(
            indicatorColor: Theme.of(context).colorScheme.primary,
          ),
        );
      },
    );
  }

  Widget _buildOnlineExamReport() {
    return BlocBuilder<OnlineExamReportCubit, OnlineExamReportState>(
      builder: (context, state) {
        if (state is OnlineExamReportFetchSuccess) {
          return SingleChildScrollView(
            controller: _reportOnlineExamController,
            padding: const EdgeInsets.only(top: 16, bottom: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                modernStatsCard(
                  title:
                      "${Utils.getTranslatedLabel(statisticsKey)} ${Utils.getTranslatedLabel(examsKey)}",
                  value: state.totalExams.toString(),
                  percentage: state.attempted! / state.totalExams!,
                  progressColor:
                      Theme.of(context).colorScheme.primary.withOpacity(0.9),
                  subtitle1: Utils.getTranslatedLabel(attemptedKey),
                  subtitle2: Utils.getTranslatedLabel(missedKey),
                  value1: state.attempted.toString(),
                  value2: state.missedExams.toString(),
                  icon: Icons.quiz_outlined,
                ),
                modernStatsCard(
                  title:
                      "${Utils.getTranslatedLabel(statisticsKey)} ${Utils.getTranslatedLabel(pointsKey)}",
                  value: state.totalMarks!,
                  percentage: int.parse(state.totalObtainedMarks!) /
                      int.parse(state.totalMarks!),
                  progressColor:
                      Theme.of(context).colorScheme.primary.withOpacity(0.8),
                  subtitle1: Utils.getTranslatedLabel(obtainedKey),
                  subtitle2: Utils.getTranslatedLabel(percentageKey),
                  value1: state.totalObtainedMarks!,
                  value2: "${state.percentage}%",
                  icon: Icons.trending_up_rounded,
                ),
                if (state.examList.data != null &&
                    state.examList.data!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(32, 16, 16, 16),
                    child: Text(
                      "${Utils.getTranslatedLabel(detailKey)} ${Utils.getTranslatedLabel(examsKey)}",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                if (state.examList.data != null &&
                    state.examList.data!.isNotEmpty)
                  ...state.examList.data!.map((item) {
                    final totalMarksRaw = item.totalMarks ?? 0;
                    final obtainedMarksRaw = item.obtainedMarks ?? 0;

                    //  bertipe num (int/double)
                    final totalMarks = (totalMarksRaw is num)
                        ? totalMarksRaw
                        : num.tryParse(totalMarksRaw.toString()) ?? 0;

                    final obtainedMarks = (obtainedMarksRaw is num)
                        ? obtainedMarksRaw
                        : num.tryParse(obtainedMarksRaw.toString()) ?? 0;

                    final percentage =
                        totalMarks > 0 ? obtainedMarks / totalMarks : 0.0;

                    return modernPointsDetailCard(
                      title: Utils.getTranslatedLabel(pointsKey),
                      points: "$obtainedMarks / $totalMarks",
                      subtitle: item.title ?? '',
                      percentage: percentage,
                    );
                  }).toList(),
              ],
            ),
          );
        }
        if (state is OnlineExamReportFetchFailure) {
          return Padding(
            padding: const EdgeInsets.only(top: 16),
            child: Align(
              alignment: Alignment.topCenter,
              child: state.errorMessage ==
                      ErrorMessageKeysAndCode.noOnlineExamReportFoundCode
                  ? NoDataContainer(
                      titleKey:
                          ErrorMessageKeysAndCode.getErrorMessageKeyFromCode(
                              state.errorMessage),
                    )
                  : ErrorContainer(
                      errorMessageCode: state.errorMessage,
                      onTapRetry: getExamOnlineReport,
                    ),
            ),
          );
        }
        return Center(
          child: CustomCircularProgressIndicator(
            indicatorColor: Theme.of(context).colorScheme.primary,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // return SizedBox();r
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: BlocBuilder<ReportTabSelectionCubit, ReportTabSelectionState>(
        builder: (context, state) {
          return Column(
            children: [
              buildModernAppBar(state),
              Expanded(
                child: (isExamManagementModuleEnable() &&
                        isAssignmentManagementModuleEnable())
                    ? state.reportFilterTabTitle == assignmentKey
                        ? _buildAssignmentReport()
                        : _buildOnlineExamReport()
                    : isAssignmentManagementModuleEnable()
                        ? _buildAssignmentReport()
                        : _buildOnlineExamReport(),
              ),
            ],
          );
        },
      ),
    );
  }
}
