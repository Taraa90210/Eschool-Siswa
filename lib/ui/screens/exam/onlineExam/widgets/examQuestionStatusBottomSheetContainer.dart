import 'package:eschool/cubits/submitOnlineExamAnswersCubit.dart';
import 'package:eschool/ui/widgets/customCircularProgressIndicator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:eschool/cubits/onlineExamQuestionsCubit.dart';

import 'package:eschool/utils/labelKeys.dart';
import 'package:eschool/utils/utils.dart';
import 'package:get/get.dart';
import 'package:flutter_animate/flutter_animate.dart';

class ExamQuestionStatusBottomSheetContainer extends StatelessWidget {
  final PageController pageController;
  final Function navigateToResultScreen;
  final SubmitOnlineExamAnswersCubit submitOnlineExamAnswersCubit;

  final Map<int, dynamic> submittedAnswers;
  final int seed;
  final Set<int> doubtfulQuestionIds;
  final int onlineExamId;
  final String examName;

  ExamQuestionStatusBottomSheetContainer({
    Key? key,
    required this.examName,
    required this.pageController,
    required this.navigateToResultScreen,
    required this.submitOnlineExamAnswersCubit,
    required this.submittedAnswers,
    required this.doubtfulQuestionIds,
    required this.onlineExamId,
    required this.seed,
  }) : super(key: key);

  // Color palette
  Color _getPrimaryColor(BuildContext context) => Color(0xFFE94057);
  Color _getSecondaryColor(BuildContext context) =>
      Color(0xFFF27121).withOpacity(0.8);
  Color _getBackgroundColor(BuildContext context) =>
      Theme.of(context).scaffoldBackgroundColor;
  Color _getCompletedColor(BuildContext context) => Color(0xFF4CAF50);
  Color _getPendingColor(BuildContext context) =>
      Color(0xFFF44336).withOpacity(0.8);
  Color _getDoubtfulColor(BuildContext context) => Color(0xFFFF9800);
  Color _getTextColor(BuildContext context) => Color(0xFF2D3142);

  List<T> _deterministicShuffle<T>(List<T> items, int seed) {
    if (items.isEmpty) return items;

    final List<T> result =
        List.from(items); // Salin daftar agar tidak mengubah aslinya

    // Algoritma Fisher-Yates dengan Linear Congruential Generator (LCG)
    for (int i = result.length - 1; i > 0; i--) {
      seed = (seed * 1103515245 + 12345) &
          0x7fffffff; // LCG untuk angka acak deterministik
      int j = seed % (i + 1);

      // Swap elemen
      final temp = result[i];
      result[i] = result[j];
      result[j] = temp;
    }

    return result;
  }

  Widget hasQuestionAttemptedContainer({
    required int questionIndex,
    required Color color,
    required BuildContext context,
  }) {
    return GestureDetector(
      onTap: () {
        pageController.animateToPage(
          questionIndex,
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeInOutCubic,
        );
        Get.back();
      },
      child: Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: color,
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.3),
              blurRadius: 4,
              offset: Offset(0, 2),
            )
          ],
        ),
        height: 42.0,
        width: 42.0,
        child: Text(
          "${questionIndex + 1}",
          style: TextStyle(
            color: _getBackgroundColor(context),
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      )
          .animate(onPlay: (controller) => true)
          .scale(begin: Offset(1, 1), end: Offset(0.95, 0.95), duration: 100.ms)
          .then(duration: 100.ms)
          .scale(begin: Offset(0.95, 0.95), end: Offset(1, 1)),
    );
  }

  Widget setAnsweredAndNotAnsweredCount({
    required BuildContext context,
    required String titleText,
    required int answerCount,
    required Color bgColor,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        color: bgColor.withOpacity(0.15),
        border: Border.all(color: bgColor.withOpacity(0.3), width: 1),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(10),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: bgColor,
            ),
            child: Icon(
              icon,
              size: 24,
              color: Colors.white,
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Text(
              Utils.getTranslatedLabel(titleText),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: _getTextColor(context),
              ),
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(30),
              color: bgColor,
            ),
            child: Text(
              answerCount.toString(),
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(duration: 400.ms, delay: 200.ms)
        .slideX(begin: 0.1, end: 0);
  }

  @override
  Widget build(BuildContext context) {
    final int totalQuestions =
        context.read<OnlineExamQuestionsCubit>().getTotalQuestions() ?? 0;

// Hitung soal yang dijawab DAN TIDAK ragu-ragu
    final answeredCount = submittedAnswers.entries
    .where((entry) {
      final id = entry.key;
      final value = entry.value;

      // Tidak boleh ragu-ragu
      if (doubtfulQuestionIds.contains(id)) return false;

      // Jika value adalah String kosong -> belum dijawab
      if (value is String) return value.trim().isNotEmpty;

      // Kalau bukan String, anggap terisi
      return true;
    })
    .length;


// Hitung soal yang ragu-ragu
    final doubtfulCount = doubtfulQuestionIds.length;

// Sisanya adalah soal yang benar-benar belum dijawab
    final unansweredCount = totalQuestions - answeredCount - doubtfulCount;

    final allQuestions = _deterministicShuffle(
        context.read<OnlineExamQuestionsCubit>().getQuestions(), seed);

    return Container(
      padding: const EdgeInsets.only(
          left: 20.0, right: 20.0, top: 5.0, bottom: 20.0),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * (0.8),
      ),
      decoration: BoxDecoration(
        color: _getBackgroundColor(context),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(30.0),
          topRight: Radius.circular(30.0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            spreadRadius: 1,
          )
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 5,
            margin: EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(5),
            ),
          ).animate().fadeIn(),

          // Header
          Container(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Row(
              children: [
                Icon(
                  Icons.assignment_rounded,
                  color: _getPrimaryColor(context),
                  size: 28,
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    examName,
                    style: TextStyle(
                      color: _getTextColor(context),
                      fontSize: 20.0,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(duration: 300.ms),

          // Exam stats
          Container(
            margin: EdgeInsets.symmetric(vertical: 8),
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  _getPrimaryColor(context),
                  _getSecondaryColor(context)
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      Icon(Icons.help_outline, color: Colors.white, size: 28),
                      SizedBox(height: 8),
                      Text(
                        "${context.read<OnlineExamQuestionsCubit>().getQuestions().length}",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        Utils.getTranslatedLabel(totalQuestionsKey),
                        style: TextStyle(color: Colors.white, fontSize: 13),
                      ),
                    ],
                  ),
                ),
                Container(
                  height: 50,
                  width: 1,
                  color: Colors.white.withOpacity(0.5),
                ),
                Expanded(
                  child: Column(
                    children: [
                      Icon(Icons.calculate_outlined,
                          color: Colors.white, size: 28),
                      SizedBox(height: 8),
                      Text(
                        "${context.read<OnlineExamQuestionsCubit>().getTotalMarks()}",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        Utils.getTranslatedLabel(totalMarksKey),
                        style: TextStyle(color: Colors.white, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          )
              .animate()
              .fadeIn(duration: 400.ms, delay: 100.ms)
              .scale(begin: Offset(0.95, 0.95)),

          // Progress indicator
          Container(
            margin: EdgeInsets.symmetric(vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 8.0, bottom: 8.0),
                  child: Text(
                    "${Utils.getTranslatedLabel("Progress")} (${totalQuestions == 0 ? '0' : (answeredCount / totalQuestions * 100).toStringAsFixed(0)}%)",
                    style: TextStyle(
                      color: _getTextColor(context),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value:
                        totalQuestions > 0 ? answeredCount / totalQuestions : 0,
                    backgroundColor: Colors.grey.shade200,
                    valueColor: AlwaysStoppedAnimation<Color>(
                        _getCompletedColor(context)),
                    minHeight: 10,
                  ),
                ),
              ],
            ),
          )
              .animate()
              .fadeIn(duration: 400.ms, delay: 150.ms)
              .slideY(begin: 0.2, end: 0),

          // Questions list
          Expanded(
            child: SingleChildScrollView(
              physics: BouncingScrollPhysics(),
              child: Column(
                children: [
                  // Questions list
                  Container(
                    margin: const EdgeInsets.symmetric(
                        horizontal: 5.0, vertical: 8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            alignment: WrapAlignment.start,
                            children: List.generate(
                                allQuestions.length, (index) => index).map(
                              (index) {
                                final question = allQuestions[index];
                                final bool isDoubtful =
                                    doubtfulQuestionIds.contains(question.id);
                                final bool isAttempted = submittedAnswers
                                        .containsKey(question.id)
                                    ? (submittedAnswers[question.id] is String
                                        ? submittedAnswers[question.id]
                                                .toString()
                                                .trim() !=
                                            ""
                                        : true)
                                    : false;

                                // Logika baru untuk menentukan warna
                                final Color statusColor;
                                if (isDoubtful) {
                                  statusColor = _getDoubtfulColor(context);
                                } else if (isAttempted) {
                                  statusColor = _getCompletedColor(context);
                                } else {
                                  statusColor = _getPendingColor(context);
                                }

                                return hasQuestionAttemptedContainer(
                                  color:
                                      statusColor, // <-- Kirim warna yang sudah ditentukan
                                  context: context,
                                  questionIndex: index,
                                );
                              },
                            ).toList(),
                          ),
                        ),
                      ],
                    ),
                  )
                      .animate()
                      .fadeIn(duration: 300.ms, delay: (50).ms)
                      .slideY(begin: 0.1, end: 0),

                  const SizedBox(height: 16),

                  // Answered status
                  setAnsweredAndNotAnsweredCount(
                    context: context,
                    titleText: answeredKey,
                    answerCount: answeredCount,
                    bgColor: _getCompletedColor(context),
                    icon: Icons.check_circle_outline,
                  ),
                  setAnsweredAndNotAnsweredCount(
                    context: context,
                    titleText: "Ragu - ragu",
                    answerCount: doubtfulCount,
                    bgColor: _getDoubtfulColor(context),
                    icon: Icons.question_mark_outlined,
                  ),
                  setAnsweredAndNotAnsweredCount(
                    context: context,
                    titleText: unAnsweredKey,
                    answerCount: unansweredCount,
                    bgColor: _getPendingColor(context),
                    icon: Icons.pending_actions,
                  ),

                  const SizedBox(height: 16),
                ],
              ),
            ),
          )
              .animate()
              .fadeIn(duration: 400.ms, delay: 300.ms)
              .slideY(begin: 0.2, end: 0),

          // Submit button
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 20.0),
            child: BlocBuilder<SubmitOnlineExamAnswersCubit,
                SubmitOnlineExamAnswersState>(
              bloc: submitOnlineExamAnswersCubit,
              builder: (context, state) {
                return ElevatedButton(
                  onPressed: () {
                    print("Submit button pressed");
                    if (state is SubmitOnlineExamAnswersInProgress) {
                      return;
                    }

                    // Clear focus from any text fields to prevent automatic focusing
                    FocusScope.of(context).unfocus();

                    navigateToResultScreen();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    padding: EdgeInsets.symmetric(vertical: 16),
                    elevation: 3,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    minimumSize: Size(double.infinity, 56),
                  ),
                  child: state is SubmitOnlineExamAnswersInProgress
                      ? CustomCircularProgressIndicator(
                          indicatorColor: Colors.white,
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.send_rounded, color: Colors.white),
                            SizedBox(width: 8),
                            Text(
                              Utils.getTranslatedLabel(submitKey).toUpperCase(),
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                letterSpacing: 1,
                              ),
                            ),
                          ],
                        ),
                );
              },
            ),
          )
        ],
      ),
    );
  }
}
