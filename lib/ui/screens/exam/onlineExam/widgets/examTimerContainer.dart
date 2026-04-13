import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class ExamTimerContainer extends StatefulWidget {
  final int examDurationInMinutes;
  final Function navigateToResultScreen;
  const ExamTimerContainer({
    Key? key,
    required this.examDurationInMinutes,
    required this.navigateToResultScreen,
  }) : super(key: key);

  @override
  ExamTimerContainerState createState() => ExamTimerContainerState();
}

class ExamTimerContainerState extends State<ExamTimerContainer> {
  late int minutesLeft = widget.examDurationInMinutes - 1;
  late int secondsLeft = 59;

  void startTimer() {
    // Jangan buat timer baru kalau masih aktif
    if (examTimer != null && examTimer!.isActive) {
      debugPrint("Timer sudah berjalan");
      return;
    }

    debugPrint("Timer dimulai");
    examTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (minutesLeft == 0 && secondsLeft == 0) {
        timer.cancel();
        widget.navigateToResultScreen();
      } else {
        if (secondsLeft == 0) {
          secondsLeft = 59;
          minutesLeft--;
        } else {
          secondsLeft--;
        }
        setState(() {});
      }
    });
  }

  Timer? examTimer;

  int getCompletedExamDuration() {
    if (kDebugMode) {
      print("Exam completed in ${widget.examDurationInMinutes - minutesLeft}");
    }
    return widget.examDurationInMinutes - minutesLeft;
  }

  void cancelTimer() {
    if (kDebugMode) {
      print("Cancel timer");
    }
    examTimer?.cancel();
  }

  void resumeTimer() {
    if (examTimer == null || !examTimer!.isActive) {
      startTimer();
      if (kDebugMode) {
        print("Timer resumed");
      }
    } else {
      if (kDebugMode) {
        print("Timer is already running");
      }
    }
  }

  @override
  void dispose() {
    cancelTimer();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    String hours = (minutesLeft ~/ 60).toString().length == 1
        ? "0${minutesLeft ~/ 60}"
        : (minutesLeft ~/ 60).toString();

    final String minutes = (minutesLeft % 60).toString().length == 1
        ? "0${minutesLeft % 60}"
        : (minutesLeft % 60).toString();
    hours = hours == "00" ? "" : hours;

    final String seconds = secondsLeft < 10 ? "0$secondsLeft" : "$secondsLeft";

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8.0,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        hours.isEmpty
            ? "$minutes Menit $seconds Detik"
            : "$hours Jam $minutes Menit $seconds Detik",
        textAlign: TextAlign.center,
        style: TextStyle(
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
