import 'dart:convert';

import 'package:eschool/data/models/exam/examOnline.dart';
import 'package:eschool/data/models/exam/question.dart';
import 'package:eschool/utils/system/api.dart';
import 'package:flutter/foundation.dart';

class OnlineExamRepository {
   /// - [page]            : nomor halaman (default 1)
  /// - [classSubjectId]  : filter by subject (0 = semua)
  /// - [childId]         : wajib jika orang tua (parent API)
  /// - [useParentApi]    : true = endpoint parent, false = endpoint student
  ///
  /// Return:
  /// {
  ///   "examList": List<ExamOnline>,
  ///   "currentPage": int,
  ///   "totalPage": int,
  ///   "from": int?,
  ///   "to": int?,
  ///   "total": int?,
  ///   "nextPageUrl": String?,
  ///   "prevPageUrl": String?,
  /// }
  Future<Map<String, dynamic>> getExamsOnline({
    int? page,
    required int classSubjectId,
    required int childId,
    required bool useParentApi,
  }) async {
    try {
      final qp = <String, dynamic>{
        if (classSubjectId != 0) 'class_subject_id': classSubjectId,
        'page': (page == null || page == 0) ? 1 : page,
        if (useParentApi) 'child_id': childId,
      };

      final result = await Api.get(
        url: useParentApi ? Api.parentExamOnlineList : Api.studentExamOnlineList,
        useAuthToken: true,
        queryParameters: qp,
      );

      if (kDebugMode) {
        debugPrint('Result of getExamsOnline');
        debugPrint('===============');
        final jsonString = const JsonEncoder.withIndent('  ').convert(result);
        for (final line in jsonString.split('\n')) {
          debugPrint(line);
        }
      }

      // Struktur respons di contohmu:
      // { error, message, data: { current_page, data: [...], last_page, ... }, code }
      final Map<String, dynamic>? root = _asMap(result);
      final Map<String, dynamic>? data = _asMap(root?['data']);

      // Safety: kalau struktur tidak sesuai, kembalikan kosong.
      if (data == null) {
        return {
          'examList': <ExamOnline>[],
          'currentPage': 0,
          'totalPage': 0,
          'from': 0,
          'to': 0,
          'total': 0,
          'nextPageUrl': null,
          'prevPageUrl': null,
        };
      }

      final List list = (data['data'] as List?) ?? const [];
      final examList = list
          .map((e) => ExamOnline.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();

      return {
        'examList': examList,
        'currentPage': _asInt(data['current_page']),
        'totalPage': _asInt(data['last_page']),
        'from': _asInt(data['from']),
        'to': _asInt(data['to']),
        'total': _asInt(data['total']),
        'nextPageUrl': data['next_page_url']?.toString(),
        'prevPageUrl': data['prev_page_url']?.toString(),
      };
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('getExamsOnline error: $e');
        debugPrint('$st');
      }
      throw ApiException(e.toString());
    }
  }

  Future<Map<String, dynamic>> getOnlineExamQuestions({
    required int examId,
    required int examKey,
  }) async {
    try {
      final result = await Api.get(
        url: Api.studentExamOnlineQuestions,
        useAuthToken: true,
        queryParameters: {'exam_id': examId, 'exam_key': examKey},
      );

      if (result['data'] == null) {
        throw ApiException(result['message'].toString());
      }

      return {
        "question": (result['data'] as List)
            .map((e) => Question.fromJson(Map.from(e)))
            .toList(),
        "totalMarks": result['total_marks'],
        "totalQuestions": result['total_questions'] //
      };
    } catch (e) {
      print("---");
      print(e);
      throw ApiException(e.toString());
    }
  }

  Future<String> setExamOnlineAnswers({
    required int examId,
    required Map<int, dynamic> answerData,
  }) async {
    try {
      final answersData = answerData.keys
          .map((key) => {
                "question_id": key,
                if (answerData[key] is String) "answer": answerData[key],
                if (answerData[key] is int) "option_id": answerData[key],
              })
          .toList();

      final body = {"online_exam_id": examId, "answers_data": answersData};

      print("Request body");
      print("===============");

      String jsonString = JsonEncoder.withIndent("\t").convert(body);
      for (var line in jsonString.split("\n")) {
        print(line);
      }

      final result = await Api.post(
        url: Api.studentSubmitOnlineExamAnswers,
        useAuthToken: true,
        body: body,
      );
      if (kDebugMode) {
        print("result of answer's submission $result");
      }

      print("Result body");
      print("===============");

      String resultJsonString = JsonEncoder.withIndent("\t").convert(body);
      for (var line in resultJsonString.split("\n")) {
        print(line);
      }
      return result["message"];
    } catch (e) {
      print("ERROR PAS SUBMIT");
      print(e);
      if (kDebugMode) {
        print("exception @Answer submission $e");
      }
      throw ApiException(e.toString());
    }
  }


   Map<String, dynamic>? _asMap(dynamic v) {
    if (v is Map<String, dynamic>) return v;
    if (v is Map) {
      return v.map((k, val) => MapEntry(k.toString(), val));
    }
    return null;
  }

  /// Pastikan dynamic bisa dibaca sebagai int
  int _asInt(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString()) ?? 0;
  }
}
