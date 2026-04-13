import 'package:eschool/cubits/authCubit.dart';
import 'package:eschool/cubits/examTimeTableCubit.dart';
import 'package:eschool/data/models/exam.dart';
import 'package:eschool/data/repositories/studentRepository.dart';
import 'package:eschool/ui/widgets/customShimmerContainer.dart';
import 'package:eschool/ui/widgets/errorContainer.dart';
import 'package:eschool/ui/widgets/noDataContainer.dart';
import 'package:eschool/ui/widgets/screenTopBackgroundContainer.dart';
import 'package:eschool/ui/widgets/shimmerLoadingContainer.dart';
import 'package:eschool/ui/widgets/subjectImageContainer.dart';
import 'package:eschool/ui/widgets/svgButton.dart';
import 'package:eschool/utils/animationConfiguration.dart';
import 'package:eschool/utils/labelKeys.dart';
import 'package:eschool/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';

class ExamTimeTableScreen extends StatefulWidget {
  final int? childID;
  final int examID;
  final String examName;

  const ExamTimeTableScreen({
    Key? key,
    this.childID,
    required this.examID,
    required this.examName,
  }) : super(key: key);

  @override
  State<ExamTimeTableScreen> createState() => _ExamTimeTableState();

  static Widget routeInstance() {
    final examDetails = Get.arguments as Map<String, dynamic>;

    return BlocProvider(
      create: (context) => ExamTimeTableCubit(StudentRepository()),
      child: ExamTimeTableScreen(
        childID: examDetails['childID'],
        examID: examDetails['examID'],
        examName: examDetails['examName'],
      ),
    );
  }
}

class _ExamTimeTableState extends State<ExamTimeTableScreen> {
  //
  Widget _buildExamTimeTableContainer({
    required ExamTimeTable examTimeTable,
  }) {
    final subjectDetails = examTimeTable.subject;
    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: MediaQuery.of(context).size.width * 0.075,
        vertical: 10.0,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black
                .withValues(alpha: 0.1), // Changed to lighter black shadow
            blurRadius: 12, // Reduced blur
            spreadRadius: 1,
            offset: const Offset(0, 4), // Smaller offset
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              // Ripple effect on tap
            },
            // splashColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
            // highlightColor:
            //     Theme.of(context).colorScheme.primary.withValues(alpha: 0.05),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Hero(
                    tag: 'subject-${subjectDetails!.id}',
                    child: SubjectImageContainer(
                      showShadow: true,
                      height: 75, // Increased from 60 to 75
                      radius: 12,
                      subject: subjectDetails,
                      width: 75, // Increased from 60 to 75
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                subjectDetails.name ?? "",
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.primary,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16.0,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                vertical: 4,
                                horizontal: 8,
                              ),
                              decoration: BoxDecoration(
                                color: Theme.of(context)
                                    .colorScheme
                                    .primary
                                    .withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '${examTimeTable.totalMarks} ${Utils.getTranslatedLabel(marksKey)}',
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.primary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (subjectDetails.type != ' ') ...[
                          const SizedBox(height: 4),
                          Text(
                            Utils.getTranslatedLabel(subjectDetails.isPractial()
                                ? practicalKey
                                : theoryKey),
                            style: TextStyle(
                              color: Theme.of(context)
                                  .colorScheme
                                  .secondary
                                  .withValues(alpha: 0.8),
                              fontSize: 14.0,
                            ),
                          ),
                        ],
                        const SizedBox(height: 8),
                        if (examTimeTable.date != '') ...[
                          Row(
                            children: [
                              Icon(
                                Icons.calendar_today,
                                size: 14,
                                color: Theme.of(context)
                                    .colorScheme
                                    .secondary
                                    .withValues(alpha: 0.7),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                Utils.formatDate(
                                    DateTime.parse(examTimeTable.date!)),
                                style: TextStyle(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .secondary
                                      .withValues(alpha: 0.7),
                                  fontSize: 14.0,
                                ),
                              ),
                            ],
                          ),
                        ],
                        if (examTimeTable.startingTime != '' &&
                            examTimeTable.endingTime != '') ...[
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                Icons.access_time,
                                size: 14,
                                color: Theme.of(context)
                                    .colorScheme
                                    .secondary
                                    .withValues(alpha: 0.7),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${Utils.formatTime(examTimeTable.startingTime!)} - ${Utils.formatTime(examTimeTable.endingTime!)}',
                                style: TextStyle(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .secondary
                                      .withValues(alpha: 0.7),
                                  fontSize: 14.0,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ).animate().fadeIn(duration: 300.ms).slideX(
                        begin: 0.1,
                        end: 0,
                        duration: 300.ms,
                        curve: Curves.easeOutQuad),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    )
        .animate()
        .fadeIn(duration: 400.ms)
        .scale(duration: 400.ms, curve: Curves.easeOutQuad);
  }

  Widget _buildExamTimeTableLoading() {
    return Column(
      children: List.generate(
        Utils.defaultShimmerLoadingContentCount,
        (index) => _buildShimmerLoadingExamTimeTableContainer(context),
      ),
    );
  }

  Widget _buildExamTimeTableDetailsContainer() {
    return SingleChildScrollView(
      padding: EdgeInsets.only(
        bottom: Utils.getScrollViewBottomPadding(context),
        top: Utils.getScrollViewTopPadding(
          context: context,
          appBarHeightPercentage: Utils.appBarMediumtHeightPercentage,
        ),
      ),
      child: BlocBuilder<ExamTimeTableCubit, ExamTimeTableState>(
        builder: (context, state) {
          if (state is ExamTimeTableFetchSuccess) {
            return state.examTimeTableList.isEmpty
                ? const NoDataContainer(titleKey: noExamTimeTableFoundKey)
                : Column(children: [
                    SizedBox(
                      height: 10,
                    ),
                    ...List.generate(
                      state.examTimeTableList.length,
                      (index) => Animate(
                        effects: listItemAppearanceEffects(
                          itemIndex: index,
                          totalLoadedItems: state.examTimeTableList.length,
                        ),
                        child: _buildExamTimeTableContainer(
                          examTimeTable: state.examTimeTableList[index],
                        ),
                      ),
                    ),
                  ]);
          } else if (state is ExamTimeTableFetchFailure) {
            return ErrorContainer(
              errorMessageCode: state.errorMessage,
              onTapRetry: fetchExamTimeTableList,
            );
          }

          return _buildExamTimeTableLoading();
        },
      ),
    );
  }

  void fetchExamTimeTableList() {
    context.read<ExamTimeTableCubit>().fetchStudentExamsList(
          useParentApi: context.read<AuthCubit>().isParent(),
          examID: widget.examID,
          childId: widget.childID,
        );
  }

  @override
  void initState() {
    super.initState();
    Future.delayed(Duration.zero, () {
      fetchExamTimeTableList();
    });
  }

  Widget _buildAppBar(BuildContext context) {
    return ScreenTopBackgroundContainer(
      heightPercentage: Utils.appBarMediumtHeightPercentage,
      child: LayoutBuilder(
        builder: (context, boxConstraints) {
          return Stack(
            clipBehavior: Clip.none,
            children: [
              Align(
                alignment: Alignment.topLeft,
                child: Padding(
                  padding: EdgeInsets.only(
                    left: Utils.screenContentHorizontalPadding,
                  ),
                  child: SvgButton(
                    onTap: () {
                      Get.back();
                    },
                    svgIconUrl: Utils.getBackButtonPath(context),
                  ),
                ),
              ),
              Align(
                alignment: Alignment.topCenter,
                child: Text(
                  Utils.getTranslatedLabel(examTimeTableKey),
                  style: TextStyle(
                    color: Theme.of(context).scaffoldBackgroundColor,
                    fontSize: Utils.screenTitleFontSize,
                  ),
                ),
              ),
              // Align(
              //   alignment: Alignment.topCenter,
              //   child: Padding(
              //     padding: EdgeInsets.only(
              //       top: boxConstraints.maxHeight * (0.075) +
              //           Utils.screenTitleFontSize,
              //       left: Utils.screenContentHorizontalPadding,
              //       right: Utils.screenContentHorizontalPadding,
              //     ),
              //     child: Text(
              //       studentName,
              //       maxLines: 1,
              //       overflow: TextOverflow.ellipsis,
              //       style: TextStyle(
              //         fontSize: Utils.screenSubTitleFontSize,
              //         color: Theme.of(context).scaffoldBackgroundColor,
              //       ),
              //     ),
              //   ),
              // ),
              Positioned(
                bottom: -20,
                left: MediaQuery.of(context).size.width * (0.075),
                child: Container(
                  alignment: Alignment.center,
                  height: 50,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: Theme.of(context)
                            .colorScheme
                            .secondary
                            .withValues(alpha: 0.075),
                        offset: const Offset(2.5, 2.5),
                        blurRadius: 5,
                      )
                    ],
                    color: Theme.of(context).scaffoldBackgroundColor,
                  ),
                  width: MediaQuery.of(context).size.width * (0.85),
                  child: Text(
                    widget.examName,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.secondary,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
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
    print("ExamTimeTableScreen");
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Stack(
        children: [
          Align(
            alignment: Alignment.topCenter,
            child: _buildExamTimeTableDetailsContainer(),
          ),
          Align(alignment: Alignment.topCenter, child: _buildAppBar(context)),
        ],
      ),
    );
  }

  Container _buildShimmerLoadingExamTimeTableContainer(BuildContext context) {
    return Container(
      width: MediaQuery.of(context).size.width,
      margin: EdgeInsets.only(
        bottom: 20,
        left: MediaQuery.of(context).size.width * (0.075),
        right: MediaQuery.of(context).size.width * (0.075),
      ),
      height: 90,
      child: LayoutBuilder(
        builder: (context, boxConstraints) {
          return ShimmerLoadingContainer(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomShimmerContainer(
                  borderRadius: 10,
                  height: boxConstraints.maxHeight,
                  width: boxConstraints.maxWidth * (0.26),
                ),
                SizedBox(
                  width: boxConstraints.maxWidth * (0.05),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      height: boxConstraints.maxHeight * (0.075),
                    ),
                    CustomShimmerContainer(
                      borderRadius: 10,
                      width: boxConstraints.maxWidth * (0.6),
                    ),
                    SizedBox(
                      height: boxConstraints.maxHeight * (0.075),
                    ),
                    CustomShimmerContainer(
                      height: 8,
                      borderRadius: 10,
                      width: boxConstraints.maxWidth * (0.45),
                    ),
                    const Spacer(),
                    CustomShimmerContainer(
                      height: 8,
                      borderRadius: 10,
                      width: boxConstraints.maxWidth * (0.3),
                    ),
                    SizedBox(
                      height: boxConstraints.maxHeight * (0.075),
                    ),
                    CustomShimmerContainer(
                      height: 8,
                      borderRadius: 10,
                      width: boxConstraints.maxWidth * (0.3),
                    ),
                    SizedBox(
                      height: boxConstraints.maxHeight * (0.075),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
