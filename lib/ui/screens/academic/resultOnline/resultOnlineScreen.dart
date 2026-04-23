import 'dart:math';

import 'package:eschool/cubits/auth/authCubit.dart';
import 'package:eschool/ui/widgets/system/errorContainer.dart';
import 'package:eschool/ui/widgets/system/screenTopBackgroundContainer.dart';
import 'package:eschool/ui/widgets/system/shimmerLoaders/shimmerLoadingContainer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:eschool/cubits/exam/resultOnlineCubit.dart';
import 'package:eschool/data/models/exam/resultOnlineDetails.dart';
import 'package:eschool/data/repositories/exam/resultRepository.dart';
import 'package:eschool/ui/widgets/system/customBackButton.dart';
import 'package:eschool/utils/system/labelKeys.dart';
import 'package:eschool/utils/system/utils.dart';
import 'package:get/get.dart';

class ResultOnlineScreen extends StatefulWidget {
  final int examId;
  final String examName, subjectName;
  final int? childId;
  const ResultOnlineScreen({
    Key? key,
    required this.examId,
    required this.examName,
    required this.subjectName,
    this.childId,
  }) : super(key: key);

  @override
  ResultOnlineScreenState createState() => ResultOnlineScreenState();
  static Widget routeInstance() {
    final arguments = Get.arguments as Map<String, dynamic>;
    return BlocProvider(
      create: (context) => ResultOnlineCubit(ResultRepository()),
      child: ResultOnlineScreen(
        examId: arguments['examId'],
        examName: arguments['examName'],
        subjectName: arguments['subjectName'],
        childId: arguments['childId'] ?? 0,
      ),
    );
  }
}

class ResultOnlineScreenState extends State<ResultOnlineScreen> {
  // Matching the color theme with SubjectAttendanceContainer
  final Color primaryColor = Color(0xFFE53935); // Red
  final Color accentColor = Color(0xFFC62828); // Darker red
  final Color lightColor = Color(0xFFFFEBEE); // Light red
  final Color surfaceColor = Colors.white;
  final Color textColor = Colors.black87;

  void fetchResultDetails() {
    context.read<ResultOnlineCubit>().fetchResultOnlineDetails(
          examId: widget.examId,
          useParentApi: context.read<AuthCubit>().isParent(),
          childId: widget.childId ?? 0,
        );
  }

  @override
  void initState() {
    super.initState();
    fetchResultDetails();
  }

  // Simplified navbar
  Widget buildResultAppBar() {
    return ScreenTopBackgroundContainer(
      heightPercentage: Utils.appBarSmallerHeightPercentage,
      child: Container(
        width: double.infinity,
        height: double.infinity,
        child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.topCenter,
            children: [
              Positioned(
                left: 10,
                top: -2,
                child: const CustomBackButton(),
              ),
              Text(
                Utils.getTranslatedLabel(examResultKey),
                style: TextStyle(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  fontSize: Utils.screenTitleFontSize,
                ),
              ),
            ]),
      ),
    );
  }

  Widget buildResultSummary(ResultOnlineDetails result) {
    return Container(
      padding: EdgeInsets.only(
        top: 100, // Match the navbar height
        bottom: 20,
      ),
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildScoreCard(result),
            _buildResultGraph(result),
            if (context
                .read<ResultOnlineCubit>()
                .getUniqueCorrectAnswerMark()
                .isNotEmpty)
              _buildPerMarkAnalysis(result),
            _buildResultDisclaimer(),
          ],
        ),
      ),
    );
  }

  Widget _buildScoreCard(ResultOnlineDetails result) {
    // Calculate percentage for progress bar
    double percentage = ((result.totalObtainedMarks ?? 0) /
            max(result.totalMarks!.toInt(), 1)) *
        100;
    Color progressColor = percentage >= 75.0
        ? Colors.green
        : percentage >= 60.0
            ? Colors.amber.shade700
            : Colors.red;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            Utils.getTranslatedLabel(obtainedMarksKey),
            style: _textStyle(
              color: textColor.withValues(alpha: 0.7),
              size: 14,
            ),
          ),
          const SizedBox(height: 5),
          Row(
            children: [
              Text(
                "${result.totalObtainedMarks}",
                style: _textStyle(
                  color: accentColor,
                  size: 28,
                  weight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 5),
              Text(
                "/ ${result.totalMarks}",
                style: _textStyle(
                  color: textColor.withValues(alpha: 0.7),
                  size: 20,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: lightColor,
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Row(
                  children: [
                    Text(
                      "${percentage.toStringAsFixed(1).replaceAll(RegExp(r'\.0$'), '')}",
                      style: _textStyle(
                        color: progressColor,
                        size: 20,
                        weight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Icon(
                      Icons.percent,
                      color: progressColor,
                      size: 15,
                    ),
                  ],
                ),
              ),
            ],
          ),
          // Add progress bar here
          const SizedBox(height: 15),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: percentage / 100,
                  backgroundColor: Colors.grey.withValues(alpha: 0.2),
                  valueColor: AlwaysStoppedAnimation<Color>(progressColor),
                  minHeight: 8,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildResultGraph(ResultOnlineDetails result) {
    final correctAnswers = result.correctAnswers!.totalQuestions ?? 0;
    final incorrectAnswers = result.inCorrectAnswers!.totalQuestions ?? 0;
    final total = correctAnswers + incorrectAnswers;
    final correctPercentage = total > 0 ? correctAnswers / total : 0.0;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            Utils.getTranslatedLabel(performanceAnalysisKey),
            style: _textStyle(
              color: textColor,
              size: 16,
              weight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 200,
            child: Center(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CustomPaint(
                    size: const Size(180, 180),
                    painter: DonutChartPainter(
                      animationValue: 1.0,
                      correctPercentage: correctPercentage,
                      correctColor: Colors.green.shade400,
                      incorrectColor: Colors.redAccent,
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        "$correctAnswers / $total",
                        style: _textStyle(
                          color: textColor,
                          size: 22,
                          weight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        Utils.getTranslatedLabel(correctAnswersKey),
                        style: _textStyle(
                          color: textColor.withValues(alpha: 0.7),
                          size: 14,
                        ),
                      )
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildLegendItem(
                color: Colors.green.shade400,
                text: Utils.getTranslatedLabel(correctAnswersKey),
                count: correctAnswers,
              ),
              const SizedBox(width: 20),
              _buildLegendItem(
                color: Colors.redAccent,
                text: Utils.getTranslatedLabel(incorrectAnswersKey),
                count: incorrectAnswers,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(
      {required Color color, required String text, required int count}) {
    return Row(
      children: [
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          "$text ($count)",
          style: _textStyle(
            color: textColor.withValues(alpha: 0.8),
            size: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildPerMarkAnalysis(ResultOnlineDetails result) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            Utils.getTranslatedLabel(detailedAnalysisKey),
            style: _textStyle(
              color: textColor,
              size: 16,
              weight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          Column(
            children: context
                .read<ResultOnlineCubit>()
                .getUniqueCorrectAnswerMark()
                .map((questionMark) {
              int totalQuestions = context
                  .read<ResultOnlineCubit>()
                  .getTotalQuestionsOfMark(questionMark!);
              int correctAnswers = context
                  .read<ResultOnlineCubit>()
                  .getCorectAnswersByMark(questionMark)
                  .length;
              int incorrectAnswers = context
                  .read<ResultOnlineCubit>()
                  .getIncorectAnswersByMark(questionMark)
                  .length;

              return _buildMarkCard(
                mark: questionMark.toString(),
                totalQuestions: totalQuestions,
                correctAnswers: correctAnswers,
                incorrectAnswers: incorrectAnswers,
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildMarkCard({
    required String mark,
    required int totalQuestions,
    required int correctAnswers,
    required int incorrectAnswers,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: lightColor.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: primaryColor.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "$mark ${Utils.getTranslatedLabel(marksKey)} ${Utils.getTranslatedLabel(questionsKey)}",
                style: _textStyle(
                  color: accentColor,
                  size: 16,
                  weight: FontWeight.w600,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  totalQuestions.toString(),
                  style: _textStyle(
                    color: accentColor,
                    size: 14,
                    weight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildResultCountItem(
                  count: correctAnswers,
                  label: Utils.getTranslatedLabel(correctAnswersKey),
                  color: Colors.green.shade400,
                  iconData: Icons.check_circle_outline,
                ),
              ),
              Container(
                height: 40,
                width: 1,
                color: Colors.grey.withValues(alpha: 0.3),
                margin: const EdgeInsets.symmetric(horizontal: 16),
              ),
              Expanded(
                child: _buildResultCountItem(
                  count: incorrectAnswers,
                  label: Utils.getTranslatedLabel(incorrectAnswersKey),
                  color: Colors.redAccent,
                  iconData: Icons.highlight_off,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildResultCountItem({
    required int count,
    required String label,
    required Color color,
    required IconData iconData,
  }) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              iconData,
              color: color,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              "$count",
              style: _textStyle(
                color: textColor,
                size: 18,
                weight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: _textStyle(
            color: textColor.withValues(alpha: 0.7),
            size: 12,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildResultDisclaimer() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.amber.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.amber.shade200,
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline,
            color: Colors.amber.shade700,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              "Hasil di atas dapat berubah apabila guru melakukan koreksi ulang pada soal esai atau terdapat penyesuaian penilaian.",
              style: _textStyle(
                color: Colors.amber.shade800,
                size: 13,
                weight: FontWeight.w500,
              ),
              textAlign: TextAlign.justify,
            ),
          ),
        ],
      ),
    );
  }

  Widget buildLoadingShimmer() {
    return Column(
      children: [
        Container(
          height: 100,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [primaryColor, accentColor],
            ),
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(30),
              bottomRight: Radius.circular(30),
            ),
          ),
        ),
        Container(
          width: MediaQuery.of(context).size.width,
          margin: const EdgeInsets.symmetric(horizontal: 15.0),
          padding: const EdgeInsets.only(bottom: 15, top: 15),
          child: ShimmerLoadingContainer(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  height: 100,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                Container(
                  width: double.infinity,
                  height: 250,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                Container(
                  width: double.infinity,
                  height: 150,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: surfaceColor,
      body: BlocBuilder<ResultOnlineCubit, ResultOnlineState>(
        builder: (context, state) {
          if (state is ResultOnlineFetchSuccess) {
            return Stack(
              children: [
                buildResultSummary(state.result),
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: buildResultAppBar(),
                ),
              ],
            );
          }
          if (state is ResultOnlineFetchFailure) {
            return Column(
              children: [
                buildResultAppBar(),
                Expanded(
                  child: ErrorContainer(
                    errorMessageCode: state.errorMessage,
                    onTapRetry: fetchResultDetails,
                  ),
                ),
              ],
            );
          }
          return buildLoadingShimmer();
        },
      ),
    );
  }

  TextStyle _textStyle({
    required Color color,
    required double size,
    FontWeight weight = FontWeight.normal,
  }) {
    return TextStyle(
      color: color,
      fontSize: size,
      fontWeight: weight,
      fontFamily: 'Poppins',
    );
  }
}

// Custom painter to create a donut chart
class DonutChartPainter extends CustomPainter {
  final double animationValue;
  final double correctPercentage;
  final Color correctColor;
  final Color incorrectColor;

  DonutChartPainter({
    required this.animationValue,
    required this.correctPercentage,
    required this.correctColor,
    required this.incorrectColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width / 2, size.height / 2);
    const startAngle = -pi / 2; // Start from the top

    // Background circle
    final backgroundPaint = Paint()
      ..color = Colors.grey.withValues(alpha: 0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 20;

    canvas.drawCircle(center, radius - 10, backgroundPaint);

    // Correct answers arc
    final correctPaint = Paint()
      ..color = correctColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 20
      ..strokeCap = StrokeCap.round;

    final correctSweepAngle = 2 * pi * correctPercentage;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - 10),
      startAngle,
      correctSweepAngle,
      false,
      correctPaint,
    );

    // Incorrect answers arc
    final incorrectPaint = Paint()
      ..color = incorrectColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 20
      ..strokeCap = StrokeCap.round;

    final incorrectSweepAngle = 2 * pi * (1 - correctPercentage);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - 10),
      startAngle + correctSweepAngle,
      incorrectSweepAngle,
      false,
      incorrectPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
