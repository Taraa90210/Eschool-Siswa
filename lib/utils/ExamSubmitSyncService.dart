import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:eschool/data/repositories/exam/onlineExamRepository.dart';
import 'package:eschool/cubits/exam/submitOnlineExamAnswersCubit.dart';

class ExamSubmitSyncService {
  static const String _key = 'exam_data';

  /// dipanggil saat app dibuka atau kembali ke foreground
  static Future<void> syncIfCached() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) return;

    try {
      final Map<String, dynamic> data = jsonDecode(raw);

      final int examId = data['examId'] as int;
      final Map<String, dynamic> answersRaw =
          Map<String, dynamic>.from(data['answers'] ?? {});
      final Map<String, dynamic> textRaw =
          Map<String, dynamic>.from(data['textAnswers'] ?? {});

      // gabungkan keduanya
      final Map<int, dynamic> merged = {};
      answersRaw.forEach((k, v) => merged[int.parse(k)] = v);
      textRaw.forEach((k, v) => merged[int.parse(k)] = v);

      if (merged.isEmpty) return;

      final cubit = SubmitOnlineExamAnswersCubit(OnlineExamRepository());

      final completer = Completer<void>();
      final sub = cubit.stream.listen((state) async {
        if (state is SubmitOnlineExamAnswersSuccess) {
          await prefs.remove(_key); // hapus cache
          if (!completer.isCompleted) completer.complete();
        } else if (state is SubmitOnlineExamAnswersFailure) {
          // biarkan cache tetap ada, dicoba lagi nanti
          if (!completer.isCompleted) completer.complete();
        }
      });
      print("syncing cached exam answers for examId=$examId");
      cubit.submitAnswers(examId: examId, answers: merged);

      await completer.future;
      await sub.cancel();
      await cubit.close();
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint("syncIfCached error: $e\n$st");
      }
    }
  }
}
